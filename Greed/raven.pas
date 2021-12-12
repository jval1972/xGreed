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

unit raven;

interface

uses
  g_delphi,
  d_ints_h,
  d_font,
  d_video,
  protos_h,
  r_public_h;

const
  MOVEUNIT = FRACUNIT;
  FALLUNIT = FRACUNIT;
  MAXAMMO = 300;
  DEFAULTVRDIST = 157286;
  DEFAULTVRANGLE = 4;

var
  player: player_t;
  warpActive, currentViewSize: byte;
  resizeScreen: boolean = false;
  biggerScreen: boolean;
  frames, weapdelay, spritemovetime, secretdelay, inventorydelay, usedelay, jumpdelay: integer;
  keyboardDelay: integer;
  RearViewTime, RearViewDelay, inventorytime: integer;
  weaponpic: array[0..6] of Ppic_t;
  statusbar: array[0..3] of Ppic_t;
  backdrop: PByteArray;
  backdroplookup: array[0..255] of PByteArray;
  changingweapons: boolean;
  weaponlowering: boolean;
  quitgame: boolean;
  togglemapmode: boolean;
  toggleheatmode: boolean;
  heatmode: boolean;
  godmode: boolean;
  togglemotionmode: boolean;
  motionmode: boolean;
  hurtborder: boolean;
  recording: boolean;
  playback: boolean;
  activatemenu: boolean;
  debugmode: boolean;
  gameloaded: boolean;
  nospawn: boolean;
  doorsound: boolean;
  deadrestart: boolean;
  ticker: boolean;
  togglegoalitem: boolean;
  waterdrop: boolean;
  gamepause: boolean;
  ExitLevel: boolean;
  exitexists: boolean;
  warpjammer: boolean;
  paused: boolean;
  QuickExit: boolean;
  autorun: boolean;
  ToggleRearView: boolean;
  RearViewOn: boolean;
  checktrigger: boolean;
  activatehelp: boolean;
  useitem: boolean;
  toggleautorun: boolean;
  goiright: boolean;
  goileft: boolean;
  activatebrief: boolean;
  midgetmode: boolean;
  autotarget: boolean = true;
  toggleautotarget: boolean;
  adjustvrangle: integer;
  adjustvrdist: float;
  weapmode: integer;
  newweapon: integer;
  weaponychange: integer;
  headbob: integer;
  weapbob: integer;
  moveforward: integer;
  changelight: integer;
  lighting: integer;
  wbobcount: integer;
  turnrate: integer;
  mapmode: integer;
  scrollview: integer;
  doorx: integer;
  doory: integer;
  MapZoom: integer;
  Warping: integer;
  goalitem: integer;
  specialeffect: integer;
  falldamage: integer;
  wallanimcount: integer;
  netmsgindex: integer;
  netmsgstatus: integer;
  playerturnspeed: integer = 8;
  turnunit: integer = 2;
  exitx: integer;
  exity: integer;
  songnum: integer;
  enemyviewmode: integer;
  moverate, strafrate, fallrate, WarpX, WarpY: fixed_t;
  netmode: boolean;
  wallanimationtime: integer;
  recordindex: integer;
  netsendtime: integer;
  specialeffecttime: integer;
  SwitchTime: integer;
  nethurtsoundtime: integer;
  demobuffer: PByteArray;
  demokb: array[0..NUMCODES - 1] of byte;

const
  SECRETBUFSIZE = 20;

var
  secretbuf: string[SECRETBUFSIZE] = '';

const
  NETMSGSIZE = 30;

var
  netmsg: array[0..NETMSGSIZE - 1] of char;

var
  rearbuf: array[0..64 * 64 - 1] of byte;
  BonusItem: bonus_t;
  SaveTheScreen, redo, newsong: boolean;

procedure TimeUpdate;

function Thrust(const ang: integer; const speed: fixed_t): boolean;

procedure maingame;

implementation

uses
  constant,
  d_disk,
  d_ints,
  d_misc,
  display,
  event,
  i_windows,
  i_video,
  menu,
  m_defs,
  modplay,
  net,
  r_conten,
  r_public,
  r_refdef,
  r_render,
  r_spans,
  r_walls,
  spawn,
  sprites,
  timer,
  utils;

procedure CheckElevators;
var
  elev_p: Pelevobj_t;
  time: integer;
  floorz, newfloorz: fixed_t;
begin
  floorz := RF_GetFloorZ(player.x, player.y) + player.height;
  time := timecount;
  elev_p := firstelevobj.next;
  while elev_p <> @lastelevobj do
  begin
    while time >= elev_p.elevTimer do
    begin
      if elev_p.elevUp and (CAddI(elev_p.position, elev_p.speed) >= elev_p.ceiling) then
      begin
        SoundEffect(SN_ELEVATORSTART, 15, (elev_p.mapspot and 63) * FRACTILEUNIT, (elev_p.mapspot div 64) * FRACTILEUNIT);
        elev_p.position := elev_p.ceiling;
        if elev_p.typ = E_NORMAL then
          elev_p.elevDown := true
        else if (elev_p.typ <> E_SWAP) and (elev_p.typ <> E_SECRET) then
        begin
          if elev_p.endeval <> 0 then
            RunEvent(elev_p.endeval, false);
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
      else if (elev_p.elevDown) and (CSubI(elev_p.position, elev_p.speed) <= elev_p.floor) then
      begin
        SoundEffect(SN_ELEVATORSTART, 15, (elev_p.mapspot) and (63) * FRACTILEUNIT, (elev_p.mapspot div 64) * FRACTILEUNIT);
        elev_p.position := elev_p.floor;
        if (elev_p.typ = E_NORMAL) or (elev_p.typ = E_SECRET) then
          elev_p.elevUp := true
        else if elev_p.typ <> E_SWAP then
        begin
          if elev_p.endeval <> 0 then
            RunEvent(elev_p.endeval, false);
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
      if (elev_p.typ = E_SECRET) and elev_p.elevUp then
      begin
        if (player.mapspot = elev_p.mapspot) or (mapsprites[elev_p.mapspot] <> 0) then
          elev_p.position := elev_p.floor;
      end;
      if mapsprites[elev_p.mapspot] = SM_ELEVATOR then
        mapsprites[elev_p.mapspot] := 0;
      floorheight[elev_p.mapspot] := elev_p.position;
      elev_p.elevTimer := elev_p.elevTimer + MOVEDELAY;
    end;
    elev_p := elev_p.next;
  end;
  newfloorz := RF_GetFloorZ(player.x, player.y) + player.height;
  if newfloorz <> floorz then
  begin
    if player.z > newfloorz then
    begin
      fallrate := fallrate + FALLUNIT;
      player.z := player.z - fallrate;
      if player.z < newfloorz then
        player.z := newfloorz;
    end
    else if player.z < newfloorz then
    begin
      player.z := newfloorz;
      fallrate := 0;
    end;
  end;
end;


function GetTargetAngle(const n: integer; pz: fixed_t): integer;
var
  hsprite: Pscaleobj_t;
  counter, mapspot, x, y, z, d, accuracy: integer;
  found: boolean;
  sz: fixed_t;
begin
  if not autotarget then
  begin
    result := (-player.scrollmin) and ANGLES;
    exit;
  end;
  accuracy := 16; //16 + 2*player.difficulty;
  counter := 0;
  found := false;
  msprite := @probe;
  probe.x := player.x;
  probe.y := player.y;
  probe.z := player.z;
  probe.angle := player.angle + n;
  probe.zadj := player.height;
  probe.startspot := (player.y div FRACTILEUNIT) * MAPCOLS + (player.x div FRACTILEUNIT);

  while counter < MAXPROBE do
  begin
    result := SP_Thrust;
    if result = 1 then
    begin
      hsprite := firstscaleobj.next;
      while hsprite <> @lastscaleobj do
        hsprite := hsprite.next;
      if hsprite.hitpoints <> 0 then
      begin
        mapspot := (hsprite.y div FRACTILEUNIT) * MAPCOLS + (hsprite.x div FRACTILEUNIT);
        if mapspot = spriteloc then
        begin
          found := true;
          counter := MAXPROBE;
          break;
        end;
      end;
    end;
    inc(counter);
  end;

  if not found then
  begin
    counter := 0;
    msprite := @probe;
    probe.x := player.x;
    probe.y := player.y;
    probe.z := player.z;
    probe.angle := player.angle + n + accuracy;
    probe.zadj := player.height;
    probe.startspot := (player.y div FRACTILEUNIT) * MAPCOLS + (player.x div FRACTILEUNIT);

    while counter < MAXPROBE do
    begin
      result := SP_Thrust;
      if result = 1 then
      begin
        hsprite := firstscaleobj.next;
        while hsprite <> @lastscaleobj do
          hsprite := hsprite.next;
        if hsprite.hitpoints <> 0 then
        begin
          mapspot := (hsprite.y div FRACTILEUNIT) * MAPCOLS + (hsprite.x div FRACTILEUNIT);
          if mapspot = spriteloc then
          begin
            found := true;
            player.angle := player.angle + accuracy;
            counter := MAXPROBE;
            break;
          end;
        end;
      end;
      inc(counter);
    end;

  end;

  if not found then
  begin
    counter := 0;
    msprite := @probe;
    probe.x := player.x;
    probe.y := player.y;
    probe.z := player.z;
    probe.angle := player.angle + n - accuracy;
    probe.zadj := player.height;
    probe.startspot := (player.y div FRACTILEUNIT) * MAPCOLS + (player.x div FRACTILEUNIT);

    while counter < MAXPROBE do
    begin
      result := SP_Thrust;
      if result = 1 then
      begin
        hsprite := firstscaleobj.next;
        while hsprite <> @lastscaleobj do
          hsprite := hsprite.next;
        if hsprite.hitpoints <> 0 then
        begin
          mapspot := (hsprite.y div FRACTILEUNIT) * MAPCOLS + (hsprite.x div FRACTILEUNIT);
          if mapspot = spriteloc then
          begin
            found := true;
            player.angle := player.angle - accuracy;
            counter := MAXPROBE;
            break;
          end;
        end;
      end;
      inc(counter);
    end;

  end;

  if not found then
  begin
    counter := 0;
    msprite := @probe;
    probe.x := player.x;
    probe.y := player.y;
    probe.z := player.z;
    probe.angle := player.angle + n + accuracy div 2;
    probe.zadj := player.height;
    probe.startspot := (player.y div FRACTILEUNIT) * MAPCOLS + (player.x div FRACTILEUNIT);

    while counter < MAXPROBE do
    begin
      result := SP_Thrust;
      if result = 1 then
      begin
        hsprite := firstscaleobj.next;
        while hsprite <> @lastscaleobj do
          hsprite := hsprite.next;
        if hsprite.hitpoints <> 0 then
        begin
          mapspot := (hsprite.y div FRACTILEUNIT) * MAPCOLS + (hsprite.x div FRACTILEUNIT);
          if mapspot = spriteloc then
          begin
            found := true;
            player.angle := player.angle + accuracy div 2;
            counter := MAXPROBE;
            break;
          end;
        end;
      end;
      inc(counter);
    end;

  end;

  if not found then
  begin
    counter := 0;
    msprite := @probe;
    probe.x := player.x;
    probe.y := player.y;
    probe.z := player.z;
    probe.angle := player.angle + n - accuracy div 2;
    probe.zadj := player.height;
    probe.startspot := (player.y div FRACTILEUNIT) * MAPCOLS + (player.x div FRACTILEUNIT);

    while counter < MAXPROBE do
    begin
      result := SP_Thrust;
      if result = 1 then
      begin
        hsprite := firstscaleobj.next;
        while hsprite <> @lastscaleobj do
          hsprite := hsprite.next;
        if hsprite.hitpoints <> 0 then
        begin
          mapspot := (hsprite.y div FRACTILEUNIT) * MAPCOLS + (hsprite.x div FRACTILEUNIT);
          if mapspot = spriteloc then
          begin
            found := true;
            player.angle := player.angle - accuracy div 2;
            counter := MAXPROBE;
            break;
          end;
        end;
      end;
      inc(counter);
    end;

  end;

  if found then
  begin
    pz := pz + player.z;
    sz := hsprite.z + (hsprite.height div 2);
    if sz > pz then
    begin
      z := _SHR((sz - pz), (FRACBITS + 2));
      if z >= MAXAUTO then
      begin
        result := (-player.scrollmin) and ANGLES;
        exit;
      end;
      x := _SHR((hsprite.x - player.x), (FRACBITS + 2));
      y := _SHR((hsprite.y - player.y), (FRACBITS + 2));
      d := trunc(sqrt(x * x + y * y));
      if (d >= MAXAUTO) or (autoangle2[d][z] = -1) then
      begin
        result := (-player.scrollmin) and ANGLES;
        exit;
      end;
      result := autoangle2[d][z];
      exit;
    end
    else if sz<pz then
    begin
      z := _SHR((pz - sz), (FRACBITS + 2));
      if z >= MAXAUTO then
      begin
        result := (-player.scrollmin) and ANGLES;
        exit;
      end;
      x := _SHR((hsprite.x - player.x), (FRACBITS + 2));
      y := _SHR((hsprite.y - player.y), (FRACBITS + 2));
      d := trunc(sqrt(x * x + y * y));
      if (d >= MAXAUTO) or (autoangle2[d][z] = -1) then
      begin
        result := (-player.scrollmin) and ANGLES;
        exit;
      end;
      result := -autoangle2[d][z];
      exit;
    end
    else
    begin
      result := (-player.scrollmin) and ANGLES;
      exit;
    end;
  end
  else
  begin
    result := (-player.scrollmin) and ANGLES;
    exit;
  end;
end;


procedure fireweapon;
var
  i, n, angle2, ammo, angle, angleinc, oldangle: integer;
  z, xmove2, ymove2: fixed_t;
begin
  player.status := 2;
  n := player.weapons[player.currentweapon];
  ammo := weapons[n].ammorate;
  if player.ammo[weapons[n].ammotype] < ammo then
    exit;
  oldangle := player.angle;
  weapons[n].charge := 0;
  player.ammo[weapons[n].ammotype] := player.ammo[weapons[n].ammotype] - ammo;
  if (n <> 4) and (n <> 18) and (weapmode <> 1) then
    weapmode := 1;
  case n of
  13: // mooman #1
    begin
      z := player.height - (50 * FRACUNIT);
      SpawnSprite(S_HANDBULLET, player.x, player.y, player.z, z, player.angle, GetTargetAngle(0, z), true, playernum);
      SoundEffect(SN_BULLET13, 0, player.x, player.y);
      if netmode then
        NetSoundEffect(SN_BULLET13, 0, player.x, player.y);
    end;

  8, // lizard #1
  14, // specimen #1
  15: // trix #1
    begin
      z := player.height - (50 * FRACUNIT);
      SpawnSprite(S_HANDBULLET, player.x, player.y, player.z, z, player.angle, GetTargetAngle(0, z), true, playernum);
      SoundEffect(SN_BULLET8, 0, player.x, player.y);
      if netmode then
        NetSoundEffect(SN_BULLET8, 0, player.x, player.y);
    end;

  1: // psyborg #2
    begin
      z := player.height - (52 * FRACUNIT);
      angle2 := GetTargetAngle(0, z);
      SpawnSprite(S_BULLET1, player.x, player.y, player.z, z, player.angle, angle2, true, playernum);
      SoundEffect(SN_BULLET1, 0, player.x, player.y);
      if netmode then
        NetSoundEffect(SN_BULLET1, 0, player.x, player.y);
    end;

  2:
    begin
      z := player.height - (50 * FRACUNIT);
      SpawnSprite(S_BULLET2, player.x, player.y, player.z, z, player.angle, GetTargetAngle(0, z), true, playernum);
      SoundEffect(SN_BULLET5, 0, player.x, player.y);
      if netmode then
        NetSoundEffect(SN_BULLET5, 0, player.x, player.y);
    end;

  3:
    begin
      z := player.height - (50 * FRACUNIT);
      SpawnSprite(S_BULLET3, player.x, player.y, player.z, z, player.angle, GetTargetAngle(0, z), true, playernum);
      SoundEffect(SN_BULLET3, 0, player.x, player.y);
      if netmode then
        NetSoundEffect(SN_BULLET3, 0, player.x, player.y);
    end;

  4:
    begin
      z := player.height - (50 * FRACUNIT);
      SpawnSprite(S_BULLET4, player.x, player.y, player.z, z, player.angle - 48, GetTargetAngle(-16, z), true, playernum);
      SpawnSprite(S_BULLET4, player.x, player.y, player.z, z, player.angle - 24, GetTargetAngle(-32, z), true, playernum);
      SpawnSprite(S_BULLET4, player.x, player.y, player.z, z, player.angle, GetTargetAngle(0, z), true, playernum);
      SpawnSprite(S_BULLET4, player.x, player.y, player.z, z, player.angle + 24, GetTargetAngle(+16, z), true, playernum);
      SpawnSprite(S_BULLET4, player.x, player.y, player.z, z, player.angle + 48, GetTargetAngle(+32, z), true, playernum);
    end;

  5:;

  6:;

  7: // psyborg #1
    begin
      z := player.height - (52 * FRACUNIT);
      angle2 := GetTargetAngle(0, z);
      SpawnSprite(S_BULLET7, player.x, player.y, player.z, z, player.angle, angle2, true, playernum);
      SoundEffect(SN_BULLET13, 0, player.x, player.y);
      if netmode then
        NetSoundEffect(SN_BULLET13, 0, player.x, player.y);
    end;

  9: // lizard #2
    begin
      z := player.height - (52 * FRACUNIT);
      angle2 := GetTargetAngle(0, z);
      SpawnSprite(S_BULLET9, player.x, player.y, player.z, z, player.angle, angle2, true, playernum);
      SoundEffect(SN_BULLET9, 0, player.x, player.y);
      if netmode then
        NetSoundEffect(SN_BULLET1, 0, player.x, player.y);
    end;

  10: // specimen #2
    begin
      z := player.height - (52 * FRACUNIT);
      angle2 := GetTargetAngle(0, z);
      SpawnSprite(S_BULLET10, player.x, player.y, player.z, z, player.angle, angle2, true, playernum);
      SoundEffect(SN_BULLET10, 0, player.x, player.y);
      if netmode then
        NetSoundEffect(SN_BULLET10, 0, player.x, player.y);
    end;
  11: // mooman #2
    begin
      z := player.height - (52 * FRACUNIT);
      angle2 := GetTargetAngle(0, z);
      SpawnSprite(S_BULLET11, player.x, player.y, player.z, z, player.angle, angle2, true, playernum);
      SoundEffect(SN_BULLET1, 0, player.x, player.y);
      if netmode then
        NetSoundEffect(SN_BULLET1, 0, player.x, player.y);
    end;

  12: // dominatrix #2
    begin
      angle := (player.angle - NORTH) and ANGLES;
      xmove2 := FIXEDMUL(FRACUNIT * 4, costable[angle]);
      ymove2 := -FIXEDMUL(FRACUNIT * 4, sintable[angle]);
      z := player.height - (50 * FRACUNIT);
      SpawnSprite(S_BULLET12, player.x + xmove2, player.y + ymove2, player.z, z, player.angle, GetTargetAngle(0, z), true, playernum);
      angle := (player.angle + NORTH) and ANGLES;
      xmove2 := FIXEDMUL(FRACUNIT * 4, costable[angle]);
      ymove2 := -FIXEDMUL(FRACUNIT * 4, sintable[angle]);
      z := player.height - (50 * FRACUNIT);
      SpawnSprite(S_BULLET12, player.x + xmove2, player.y + ymove2, player.z, z, player.angle, GetTargetAngle(0, z), true, playernum);
      SoundEffect(SN_BULLET12, 0, player.x, player.y);
      if netmode then
        NetSoundEffect(SN_BULLET12, 0, player.x, player.y);
    end;

  16: // red gun
    begin
      angle := (player.angle - NORTH) and ANGLES;
      xmove2 := FIXEDMUL(FRACUNIT * 4, costable[angle]);
      ymove2 := -FIXEDMUL(FRACUNIT * 4, sintable[angle]);
      z := player.height - (50 * FRACUNIT);
      SpawnSprite(S_BULLET16, player.x + xmove2, player.y + ymove2, player.z, z, player.angle, GetTargetAngle(0, z), true, playernum);
      angle := (player.angle + NORTH) and ANGLES;
      xmove2 := FIXEDMUL(FRACUNIT * 4, costable[angle]);
      ymove2 := -FIXEDMUL(FRACUNIT * 4, sintable[angle]);
      z := player.height - (50 * FRACUNIT);
      SpawnSprite(S_BULLET16, player.x + xmove2, player.y + ymove2, player.z, z, player.angle, GetTargetAngle(0, z), true, playernum);
      SoundEffect(SN_BULLET12, 0, player.x, player.y);
      if netmode then
        NetSoundEffect(SN_BULLET12, 0, player.x, player.y);
    end;

  17: // blue gun
    begin
      z := player.height - (64 * FRACUNIT);
      angle2 := GetTargetAngle(0, z);
      SpawnSprite(S_BULLET17, player.x, player.y, player.z, z, player.angle, angle2, true, playernum);
      SoundEffect(SN_BULLET17, 0, player.x, player.y);
      if netmode then
        NetSoundEffect(SN_BULLET1, 0, player.x, player.y);
    end;

  18: // green gun
    begin
      angleinc := ANGLES div 12;
      angle := 0;
      for i := 0 to 11 do
      begin
        z := player.height - (52 * FRACUNIT);
        angle2 := GetTargetAngle(0, z);
        SpawnSprite(S_BULLET18, player.x, player.y, player.z, z, angle, angle2, true, playernum);
        angle := angle + angleinc;
      end;
      if netmode then
        NetSendSpawn(S_BULLET18, player.x, player.y, player.z, z, angle, angle2, true, playernum);
    end;
  end;
  player.angle := oldangle;
end;


function FindWarpDestination(var x, y: integer; const warpValue: byte): boolean;
var
  search, nosearch: integer;
begin
  nosearch := y * MAPSIZE + x;
  if warpActive = 0 then
  begin
    for search := 0 to MAPROWS * MAPCOLS - 1 do
      if (mapsprites[search] = warpValue) and (search <> nosearch) then
      begin
        x := search and (MAPSIZE - 1);
        y := search div TILESIZE;
        turnrate := 0;
        moverate := 0;
        fallrate := 0;
        strafrate := 0;
        ResetMouse;
        warpActive := warpValue;
        result := true;
        exit;
      end;
  end;
  result := false;
end;


procedure CheckItems(const centerx, centery: integer; const useit: boolean; const chartype: integer);
var
  sprite: Pscaleobj_t;
  mapspot, value, value2, index, ammo, cmapspot: integer;
  x, y, i, j: integer;
  elev_p: Pelevobj_t;
  sound: boolean;
begin
  mapspot := centery * MAPCOLS + centerx;
  value := mapsprites[mapspot];
  case value of
  SM_MEDPAK1,
  SM_MEDPAK2,
  SM_MEDPAK3,
  SM_MEDPAK4:
    begin
      value2 := value - SM_MEDPAK1 + S_MEDPAK1;
      sprite := firstscaleobj.next;
      while sprite <> @lastscaleobj do
      begin
        if (sprite.x div FRACTILEUNIT = centerx) and (sprite.y div FRACTILEUNIT = centery) then
          if sprite.typ = value2 then
          begin
            if useit and netmode then
              NetItemPickup(centerx, centery);
            mapsprites[mapspot] := 0;
            SoundEffect(SN_PICKUP0 + chartype, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
            if useit then
            begin
              if player.angst = player.maxangst then
              begin
                player.inventory[0] := player.inventory[0] + 5 - (value - SM_MEDPAK1);
                if player.inventory[0] > 20 then
                  player.inventory[0] := 20;
                oldinventory := -2;
                inventoryleft;
                inventoryright;
                writemsg('Stored MedTube!');
              end
              else
              begin
                medpaks((5 - (value - SM_MEDPAK1)) * 50);
                writemsg('Used MedTube!');
              end;
            end;
            SpawnSprite(S_GENERATOR, sprite.x, sprite.y, 0, 0, 0, 0, false, 0);
            RF_RemoveSprite(sprite);
            exit;
          end;
        sprite := sprite.next;
      end;
    end;

  SM_SHIELD1,
  SM_SHIELD2,
  SM_SHIELD3,
  SM_SHIELD4:
    begin
      value2 := value - SM_MEDPAK1 + S_MEDPAK1;
      sprite := firstscaleobj.next;
      while sprite <> @lastscaleobj do
      begin
        if (sprite.x div FRACTILEUNIT = centerx) and (sprite.y div FRACTILEUNIT = centery) then
          if sprite.typ = value2 then
          begin
            if useit and netmode then
              NetItemPickup(centerx, centery);
            mapsprites[mapspot] := 0;
            SoundEffect(SN_PICKUP0 + chartype, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
            if useit then
            begin
              if player.shield = player.maxshield then
              begin
                player.inventory[1] := player.inventory[1] + 1 + (value - SM_SHIELD1);
                if player.inventory[1] > 20 then
                  player.inventory[1] := 20;
                oldinventory := -2;
                inventoryleft;
                inventoryright;
                writemsg('Stored Shield Charge!');
              end
              else
              begin
                heal((1 + (value - SM_SHIELD1)) * 50);
                writemsg('Used Shield Charge!');
              end;
            end;
            SpawnSprite(S_GENERATOR, sprite.x, sprite.y, 0, 0, 0, 0, false, 0);
            RF_RemoveSprite(sprite);
            exit;
          end;
        sprite := sprite.next
      end;
    end;

  SM_ENERGY,
  SM_BALLISTIC,
  SM_PLASMA:
    begin
      value2 := value - SM_ENERGY + S_ENERGY;
      sprite := firstscaleobj.next;
      while sprite <> @lastscaleobj do
      begin
        if (sprite.x div FRACTILEUNIT = centerx) and (sprite.y div FRACTILEUNIT = centery) then
          if sprite.typ = value2 then
          begin
            if useit and netmode then
              NetItemPickup(centerx, centery);
            mapsprites[mapspot] := 0;
            SoundEffect(SN_PICKUP0 + chartype, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
            if useit then
            begin
              hurtborder := true;
              player.ammo[value - SM_ENERGY] := player.ammo[value - SM_ENERGY] + 75;
              if player.ammo[value - SM_ENERGY] > MAXAMMO then
                player.ammo[value - SM_ENERGY] := MAXAMMO;
              oldshots := -1;
              writemsg(pickupammomsg[value - SM_ENERGY]);
            end;
            SpawnSprite(S_GENERATOR, sprite.x, sprite.y, 0, 0, 0, 0, false, 0);
            RF_RemoveSprite(sprite);
            exit;
          end;
        sprite := sprite.next;
      end;
    end;

  SM_AMMOBOX:
    begin
      value2 := weapons[player.weapons[player.currentweapon]].ammotype;
      if useit and ((player.ammo[value2] >= MAXAMMO) or
        ((weapons[player.currentweapon].ammorate = 0) and
        (player.ammo[0] >= MAXAMMO) and (player.ammo[1] >= MAXAMMO) and
        (player.ammo[2] >= MAXAMMO))) then
        exit;
      sprite := firstscaleobj.next;
      while sprite <> @lastscaleobj do
      begin
        if (sprite.x div FRACTILEUNIT = centerx) and (sprite.y div FRACTILEUNIT = centery) then
          if sprite.typ = S_AMMOBOX then
          begin
            if useit and netmode then
              NetItemPickup(centerx, centery);
            mapsprites[mapspot] := 0;
            SoundEffect(SN_PICKUP0 + chartype, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
            if useit then
            begin
              hurtborder := true;
              if weapons[player.currentweapon].ammorate = 0 then
              begin
                player.ammo[0] := player.ammo[0] + 45;
                if player.ammo[0] > MAXAMMO then
                  player.ammo[0] := MAXAMMO;
                player.ammo[1] := player.ammo[1] + 45;
                if player.ammo[1] > MAXAMMO then
                  player.ammo[1] := MAXAMMO;
                player.ammo[2] := player.ammo[2] + 45;
                if player.ammo[2] > MAXAMMO then
                  player.ammo[2] := MAXAMMO;
              end
              else
              begin
                player.ammo[value2] := player.ammo[value2] + 125;
                if player.ammo[value2] > MAXAMMO then
                  player.ammo[value2] := MAXAMMO;
              end;
              oldshots := -1;
              writemsg(pickupmsg[11]);
            end;
            if sprite.deathevent <> 0 then
              RunEvent(sprite.deathevent, false);
            RF_RemoveSprite(sprite);
            exit;
          end;
        sprite := sprite.next;
      end;
    end;

  SM_MEDBOX:
    begin
      if (useit) and (player.angst = player.maxangst) and (player.shield = player.maxshield) then
        exit;
      sprite := firstscaleobj.next;
      while sprite <> @lastscaleobj do
      begin
        if (sprite.x div FRACTILEUNIT = centerx) and (sprite.y div FRACTILEUNIT = centery) then
          if sprite.typ = S_MEDBOX then
          begin
            if useit and netmode then
              NetItemPickup(centerx, centery);
            mapsprites[mapspot] := 0;
            SoundEffect(SN_PICKUP0 + chartype, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
            if useit then
            begin
              heal(250);
              medpaks(250);
              hurtborder := true;
              writemsg(pickupmsg[12]);
            end;
            if sprite.deathevent <> 0 then
              RunEvent(sprite.deathevent, false);
            RF_RemoveSprite(sprite);
            exit;
          end;
        sprite := sprite.next;
      end;
    end;

  SM_GOODIEBOX:
    begin
      sprite := firstscaleobj.next;
      while sprite <> @lastscaleobj do
      begin
        if (sprite.x div FRACTILEUNIT = centerx) and (sprite.y div FRACTILEUNIT = centery) then
          if sprite.typ = S_GOODIEBOX then
          begin
            if useit and netmode then
              NetItemPickup(centerx, centery);
            mapsprites[mapspot] := 0;
            SoundEffect(SN_PICKUP0 + chartype, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
            if useit then
            begin
              for i := 0 to 1 do
              begin
                if netmode then
                begin
                  repeat
                    value2 := (clock + MS_RndT) mod 11;
                  until value2 = 8;
                end
                else
                begin
                  repeat
                    value2 := (clock + MS_RndT) mod 11;
                  until (value2 = 6) or (value2 = 10) or (value2 = 12);
                end;
                player.inventory[value2 + 2] := player.inventory[value2 + 2] + pickupamounts[value2];
                if value2 = 2 then
                begin
                  if player.inventory[2] > 15 then
                    player.inventory[2] := 15;
                end
                else if player.inventory[value2 + 2] > 10 then
                  player.inventory[value2 + 2] := 10;
              end;
              oldinventory := -2;
              inventoryleft;
              inventoryright;
              hurtborder := true;
              writemsg(pickupmsg[13]);
            end;
            if sprite.deathevent <> 0 then
              RunEvent(sprite.deathevent, false);
            RF_RemoveSprite(sprite);
            exit;
          end;
        sprite := sprite.next;
      end;
    end;

  SM_IGRENADE,
  SM_IREVERSO,
  SM_IPROXMINE,
  SM_ITIMEMINE,
  SM_IDECOY,
  SM_IINSTAWALL,
  SM_ICLONE,
  SM_IHOLO,
  SM_IINVIS,
  SM_IJAMMER,
  SM_ISTEALER:
    begin
      value2 := value - SM_IGRENADE + S_IGRENADE;
      sprite := firstscaleobj.next;
      while sprite <> @lastscaleobj do
      begin
        if (sprite.x div FRACTILEUNIT = centerx) and (sprite.y div FRACTILEUNIT = centery) then
          if sprite.typ = value2 then
          begin
            if useit and netmode then
              NetItemPickup(centerx, centery);
            mapsprites[mapspot] := 0;
            SoundEffect(SN_PICKUP0 + chartype, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
            if useit then
            begin
              hurtborder := true;
              player.inventory[value - SM_IGRENADE + 2] := player.inventory[value - SM_IGRENADE + 2] + pickupamounts[value - SM_IGRENADE];
              if value = SM_IGRENADE then
              begin
                if player.inventory[2] > 15 then
                  player.inventory[2] := 15;
              end
              else if player.inventory[value - SM_IGRENADE + 2] > 10 then
                player.inventory[value - SM_IGRENADE + 2] := 10;
              writemsg(pickupmsg[value - SM_IGRENADE]);
              oldinventory := -2;
              inventoryleft;
              inventoryright;
            end;
            SpawnSprite(S_GENERATOR, sprite.x, sprite.y, 0, 0, 0, 0, false, 0);
            RF_RemoveSprite(sprite);
            exit;
          end;
        sprite := sprite.next;
      end;
    end;

  SM_BONUSITEM:
    begin
      if useit then
      begin
        if netmode then
          NetItemPickup(centerx, centery);
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
      SoundEffect(SN_WEAPPICKUP0 + chartype, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
      BonusItem.name := '';
    end;

  SM_PRIMARY1,
  SM_PRIMARY2:
    begin
      value2 := mapsprites[mapspot] - SM_PRIMARY1 + S_PRIMARY1;
      sprite := firstscaleobj.next;
      while sprite <> @lastscaleobj do
      begin
        if (sprite.x div FRACTILEUNIT = centerx) and (sprite.y div FRACTILEUNIT = centery) then
          if sprite.typ = value2 then
          begin
            if useit and netmode then
              NetItemPickup(centerx, centery);
            RF_RemoveSprite(sprite);
            mapsprites[mapspot] := 0;
            SoundEffect(SN_WEAPPICKUP0 + chartype, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
            if useit then
            begin
              heal(150);
              medpaks(150);
              hurtborder := true;
              addscore(primaries[(value2 - S_PRIMARY1) * 2 + 1]);
              writemsg('Primary goal item!');
              inc(player.primaries[value2 - S_PRIMARY1]);
            end;
            exit;
          end;
        sprite := sprite.next;
      end;
    end;

  SM_SECONDARY1,
  SM_SECONDARY2,
  SM_SECONDARY3,
  SM_SECONDARY4,
  SM_SECONDARY5,
  SM_SECONDARY6,
  SM_SECONDARY7:
    begin
      value2 := mapsprites[mapspot] - SM_SECONDARY1 + S_SECONDARY1;
      sprite := firstscaleobj.next;
      while sprite <> @lastscaleobj do
      begin
        if (sprite.x div FRACTILEUNIT = centerx) and (sprite.y div FRACTILEUNIT = centery) and (sprite.typ = value2) then
        begin
          if useit and netmode then
            NetItemPickup(centerx, centery);
          RF_RemoveSprite(sprite);
          mapsprites[mapspot] := 0;
          SoundEffect(SN_WEAPPICKUP0 + chartype, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
          if useit then
          begin
            heal(150);
            medpaks(150);
            hurtborder := true;
            addscore(secondaries[(value2 - S_SECONDARY1) * 2 + 1]);
            writemsg('Secondary goal item!');
            inc(player.secondaries[value2 - S_SECONDARY1]);
          end;
          exit;
        end;
        sprite := sprite.next;
      end;
    end;

  SM_SWITCHDOWN:
    begin
      sound := false;
      elev_p := firstelevobj.next;
      while elev_p <> @lastelevobj do
      begin
        if (elev_p.typ = E_SWITCHDOWN) and not elev_p.elevDown then
        begin
          elev_p.elevDown := true;
          elev_p.elevTimer := timecount;
          sound := true;
          SoundEffect(SN_ELEVATORSTART, 15, (elev_p.mapspot and 63) * FRACTILEUNIT, (elev_p.mapspot div 64) * FRACTILEUNIT);
        end;
        if useit and netmode then
          NetItemPickup(centerx, centery);
        mapsprites[mapspot] := 0;
        if useit and sound then
        begin
          SoundEffect(SN_TRIGGER, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
          if netmode then
            NetSoundEffect(SN_TRIGGER, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
          SoundEffect(SN_TRIGGER, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
          if netmode then
            NetSoundEffect(SN_TRIGGER, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
        end;
        elev_p := elev_p.next;
      end;
    end;

  SM_SWITCHDOWN2:
    begin
      if useit and netmode then
        NetItemPickup(centerx, centery);
      sound := false;
      elev_p := firstelevobj.next;
      while elev_p <> @lastelevobj do
      begin
        if (elev_p.typ = E_SWITCHDOWN2) and not elev_p.elevDown then
        begin
          elev_p.elevDown := true;
          elev_p.elevTimer := timecount;
          SoundEffect(SN_ELEVATORSTART, 15, (elev_p.mapspot and 63) * FRACTILEUNIT, (elev_p.mapspot div 64) * FRACTILEUNIT);
          sound := true;
        end;
        if useit and netmode then
          NetItemPickup(centerx, centery);
        mapsprites[mapspot] := 0;
        if sound then
          SoundEffect(SN_TRIGGER, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
        elev_p := elev_p.next;
      end;
    end;

  SM_SWITCHUP:
    begin
      if useit and netmode then
        NetItemPickup(centerx, centery);
      sound := false;
      elev_p := firstelevobj.next;
      while elev_p <> @lastelevobj do
      begin
        if (elev_p.typ = E_SWITCHUP) and not elev_p.elevUp then
        begin
          elev_p.elevUp := true;
          elev_p.elevTimer := timecount;
          sound := true;
          SoundEffect(SN_ELEVATORSTART, 15, (elev_p.mapspot and 63) * FRACTILEUNIT, (elev_p.mapspot div 64) * FRACTILEUNIT);
        end;
        if useit and netmode then
          NetItemPickup(centerx, centery);
        mapsprites[mapspot] := 0;
        if sound then
          SoundEffect(SN_TRIGGER, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
        elev_p := elev_p.next;
      end;
    end;

  SM_EXIT:
    ExitLevel := true;

  SM_WEAPON0,
  SM_WEAPON1,
  SM_WEAPON2,
  SM_WEAPON3,
  SM_WEAPON4,
  SM_WEAPON5,
  SM_WEAPON6,
  SM_WEAPON7,
  SM_WEAPON8,
  SM_WEAPON9,
  SM_WEAPON10,
  SM_WEAPON11,
  SM_WEAPON12,
  SM_WEAPON13,
  SM_WEAPON14,
  SM_WEAPON15,
  SM_WEAPON16,
  SM_WEAPON17,
  SM_WEAPON18:
    begin
      value2 := value - SM_WEAPON0;
      ammo := weapons[value2].ammotype;
      index := ammo + 2;

      if (player.weapons[index] = value2) and not netmode then
      begin
        player.ammo[ammo] := player.ammo[ammo] + 100;
        if player.ammo[ammo] > MAXAMMO then
          player.ammo[ammo] := MAXAMMO;
        writemsg('Found more ammo.');
      end
      else if (player.weapons[index] <> -1) and not netmode then
      begin
        i := -MAPCOLS;
        while i <= MAPCOLS do
        begin
          for j := -1 to 1 do
          begin
            cmapspot := mapspot + i + j;
            if (cmapspot <> mapspot) and (floorpic[cmapspot] <> 0) and (mapsprites[cmapspot] = 0) then
            begin
              x := (cmapspot and 63) * MAPSIZE + 32;
              y := (cmapspot div 64) * MAPSIZE + 32;
              SpawnSprite(player.weapons[index] + S_WEAPON0, x * FRACUNIT, y * FRACUNIT, 0, 0, 0, 0, false, 0);
              i := MAPCOLS * 2;
              break;
            end;
          end;
          i := i + MAPCOLS;
        end;
        if player.currentweapon = index then
        begin
          weaponlowering := false;
          newweapon := index;
          loadweapon(value2);
          weaponychange := weaponpic[0].height - 20;
          changingweapons := true;
        end
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
        player.weapons[index] := value - SM_WEAPON0;
        player.ammo[ammo] := player.ammo[ammo] + 100;
        if player.ammo[ammo] > MAXAMMO then
          player.ammo[ammo] := MAXAMMO;
        SoundEffect(SN_WEAPPICKUP0 + chartype, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
        NetSoundEffect(SN_WEAPPICKUP0 + chartype, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
        changingweapons := true;
        weaponlowering := true;
        newweapon := index;
      end
      else
      begin
        value2 := value - SM_WEAPON0 + S_WEAPON0;
        sprite := firstscaleobj.next;
        while sprite <> @lastscaleobj do
        begin
          if (sprite.x div FRACTILEUNIT = centerx) and (sprite.y div FRACTILEUNIT = centery) then
            if sprite.typ = value2 then
            begin
              player.weapons[index] := value - SM_WEAPON0;
              value2 := weapons[player.weapons[index]].ammotype;
              hurtborder := true;
              RF_RemoveSprite(sprite);
              mapsprites[mapspot] := 0;
              SoundEffect(SN_WEAPPICKUP0 + chartype, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
              exit;
            end;
          sprite := sprite.next;
        end;
      end;
    end;
  end;
end;


procedure CheckWarps(const centerx, centery: fixed_t);
var
  x, y, mapspot: integer;
begin
  x := centerx div FRACTILEUNIT;
  y := centery div FRACTILEUNIT;
  mapspot := y * MAPCOLS + x;
  if (mapsprites[mapspot] >= 128) and (mapsprites[mapspot] <= 130) then
  begin
    if Warping <> 0 then
      exit;
    if FindWarpDestination(x, y, mapsprites[mapspot]) then
    begin
      WarpX := (x * MAPSIZE + 32) * FRACUNIT;
      WarpY := (y * MAPSIZE + 32) * FRACUNIT;
      Warping := 1;
    end;
  end
  else
  begin
    warpActive := 0;
    if mapsprites[mapspot] > 130 then
      CheckItems(x, y, true, player.chartype);
  end;
  if triggers[x][y] <> 0 then
  begin
    SoundEffect(SN_TRIGGER, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
    if netmode then
      NetSoundEffect(SN_TRIGGER, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
    SoundEffect(SN_TRIGGER, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
    if netmode then
      NetSoundEffect(SN_TRIGGER, 0, centerx * FRACTILEUNIT, centery * FRACTILEUNIT);
    RunEvent(triggers[x][y], true);
  end;
end;


procedure CheckDoors(const centerx, centery: fixed_t);
var
  x, y, mapspot: integer;
  door_p, last_p: Pdoorobj_t;
begin
  x := centerx div FRACTILEUNIT;
  y := centery div FRACTILEUNIT;
  last_p := @doorlist[numdoors];
  door_p := @doorlist[0];
  while door_p <> last_p do
  begin
    while (timecount >= door_p.doorTimer) do
    begin
      mapspot := door_p.tiley * MAPCOLS + door_p.tilex;
      if ((door_p.tilex = x) and (door_p.tiley = y)) or (mapsprites[mapspot] <> 0) then
      begin
        if door_p.doorOpen and not door_p.doorClosing then
          door_p.doorBlocked := true;
      end
      else
        door_p.doorBlocked := false;

      if door_p.doorOpening then
      begin
        if CSubI(door_p.doorSize, 4) <= MINDOORSIZE then
        begin
          door_p.doorSize := MINDOORSIZE;
          door_p.doorOpening := false;
          door_p.doorOpen := true;
          door_p.doorTimer := door_p.doorTimer + 270; // 3 seconds
        end
        else
          door_p.doorTimer := door_p.doorTimer + MOVEDELAY;
      end
      else if door_p.doorClosing then
      begin
        if CAddI(door_p.doorSize, 4) >= 64 then
        begin
          door_p.doorSize := 64;
          door_p.doorClosing := false;
          door_p.doorTimer := door_p.doorTimer + MOVEDELAY;
        end
        else
          door_p.doorTimer := door_p.doorTimer + MOVEDELAY;
      end
      else if door_p.doorOpen and (timecount > door_p.doorTimer) and not door_p.doorBlocked then
      begin
        door_p.doorClosing := true;
        door_p.doorOpen := false;
        SoundEffect(SN_DOOR, 15, door_p.tilex * FRACTILEUNIT, door_p.tiley * FRACTILEUNIT);
        door_p.doorTimer := door_p.doorTimer + MOVEDELAY;
      end
      else
        door_p.doorTimer := door_p.doorTimer + MOVEDELAY;

      door_p.position := door_p.doorSize * FRACUNIT;
    end;
    inc(door_p);
  end;
end;

function CheckForSwitch(const x, y: integer; const angle: integer; const doubleswitch: boolean): boolean;
var
  mapspot: integer;
begin
  if timecount < SwitchTime then
  begin
    result := false;
    exit;
  end;
  mapspot := y * MAPCOLS + x;
  if (angle >= SOUTH + DEGREE45) or (angle < DEGREE45) then
  begin
    if westwall[mapspot + 1] = 127 then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot + 1] = 128) and doubleswitch then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot + 1] = 172) then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot + 1] = 173) and doubleswitch then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot + 1] = 75) then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot + 1] = 76) and doubleswitch then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot + 1] = 140) then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot + 1] = 141) and doubleswitch then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot + 1] = 234) then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot + 1] = 235) and doubleswitch then
    begin
      result := true;
      exit;
    end
  end
  else if (angle >= DEGREE45) and (angle < NORTH + DEGREE45) then
  begin
    if (northwall[mapspot] = 127) then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot] = 128) and doubleswitch then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot] = 172) then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot] = 173) and doubleswitch then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot] = 75) then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot] = 76) and doubleswitch then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot] = 140) then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot] = 141) and doubleswitch then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot] = 234) then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot] = 235) and doubleswitch then
    begin
      result := true;
      exit;
    end
  end
  else if (angle >= NORTH + DEGREE45) and (angle < WEST + DEGREE45) then
  begin
    if (westwall[mapspot] = 127) then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot] = 128) and doubleswitch then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot] = 172) then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot] = 173) and doubleswitch then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot] = 75) then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot] = 76) and doubleswitch then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot] = 140) then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot] = 141) and doubleswitch then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot] = 234) then
    begin
      result := true;
      exit;
    end
    else if (westwall[mapspot] = 235) and doubleswitch then
    begin
      result := true;
      exit;
    end
  end
  else if angle >= WEST + DEGREE45 then
  begin
    if (northwall[mapspot + MAPCOLS] = 127) then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot + MAPCOLS] = 128) and doubleswitch then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot + MAPCOLS] = 172) then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot + MAPCOLS] = 173) and doubleswitch then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot + MAPCOLS] = 75) then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot + MAPCOLS] = 76) and doubleswitch then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot + MAPCOLS] = 140) then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot + MAPCOLS] = 141) and doubleswitch then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot + MAPCOLS] = 234) then
    begin
      result := true;
      exit;
    end
    else if (northwall[mapspot + MAPCOLS] = 235) and doubleswitch then
    begin
      result := true;
      exit;
    end
  end;
  result := false;
end;


procedure SwitchWall(const x, y: integer; const angle: integer; const doubleswitch: boolean);
var
  mapspot: integer;
  spot: integer;
begin
  SoundEffect(SN_WALLSWITCH, 0, x * FRACTILEUNIT, y * FRACTILEUNIT);
  mapspot := y * MAPCOLS + x;
  if (angle >= SOUTH + DEGREE45) or (angle < DEGREE45) then
  begin
    spot := mapspot + 1;
    if westwall[spot] = 127 then
      westwall[spot] := 128
    else if (westwall[spot] = 128) and doubleswitch then
      westwall[spot] := 127
    else if (westwall[spot] = 172) then
      westwall[spot] := 173
    else if (westwall[spot] = 173) and doubleswitch then
      westwall[spot] := 172
    else if (westwall[spot] = 75) then
      westwall[spot] := 76
    else if (westwall[spot] = 76) and doubleswitch then
      westwall[spot] := 75
    else if (westwall[spot] = 140) then
      westwall[spot] := 141
    else if (westwall[spot] = 141) and doubleswitch then
      westwall[spot] := 140
    else if (westwall[spot] = 234) then
      westwall[spot] := 235
    else if (westwall[spot] = 235) and doubleswitch then
      westwall[spot] := 234;
  end
  else if (angle >= DEGREE45) and (angle < NORTH + DEGREE45) then
  begin
    if northwall[mapspot] = 127 then
      northwall[mapspot] := 128
    else if (northwall[mapspot] = 128) and doubleswitch then
      northwall[mapspot] := 127
    else if (northwall[mapspot] = 172) then
      northwall[mapspot] := 173
    else if (northwall[mapspot] = 173) and doubleswitch then
      northwall[mapspot] := 172
    else if (northwall[mapspot] = 75) then
      northwall[mapspot] := 76
    else if (northwall[mapspot] = 76) and doubleswitch then
      northwall[mapspot] := 75
    else if (northwall[mapspot] = 140) then
      northwall[mapspot] := 141
    else if (northwall[mapspot] = 141) and doubleswitch then
      northwall[mapspot] := 140
    else if (northwall[mapspot] = 234) then
      northwall[mapspot] := 235
    else if (northwall[mapspot] = 235) and doubleswitch then
      northwall[mapspot] := 234;
  end
  else if (angle >= NORTH + DEGREE45) and (angle < WEST + DEGREE45) then
  begin
    if (westwall[mapspot] = 127) then
      westwall[mapspot] := 128
    else if (westwall[mapspot] = 128) and doubleswitch then
      westwall[mapspot] := 127
    else if (westwall[mapspot] = 172) then
      westwall[mapspot] := 173
    else if (westwall[mapspot] = 173) and doubleswitch then
      westwall[mapspot] := 172
    else if (westwall[mapspot] = 75) then
      westwall[mapspot] := 76
    else if (westwall[mapspot] = 76) and doubleswitch then
      westwall[mapspot] := 75
    else if (westwall[mapspot] = 140) then
      westwall[mapspot] := 141
    else if (westwall[mapspot] = 141) and doubleswitch then
      westwall[mapspot] := 140
    else if (westwall[mapspot] = 234) then
      westwall[mapspot] := 235
    else if (westwall[mapspot] = 235) and doubleswitch then
      westwall[mapspot] := 234;
  end
  else if angle >= WEST + DEGREE45 then
  begin
    spot := mapspot + MAPCOLS;
    if northwall[spot] = 127 then
      northwall[spot] := 128
    else if (northwall[spot] = 128) and doubleswitch then
      northwall[spot] := 127
    else if (northwall[spot] = 172) then
      northwall[spot] := 173
    else if (northwall[spot] = 173) and doubleswitch then
      northwall[spot] := 172
    else if (northwall[spot] = 75) then
      northwall[spot] := 76
    else if (northwall[spot] = 76) and doubleswitch then
      northwall[spot] := 75
    else if (northwall[spot] = 140) then
      northwall[spot] := 141
    else if (northwall[spot] = 141) and doubleswitch then
      northwall[spot] := 140
    else if (northwall[spot] = 234) then
      northwall[spot] := 235
    else if (northwall[spot] = 235) and doubleswitch then
      northwall[spot] := 234;
  end;
end;


function TryDoor(const xcenter, ycenter: fixed_t): boolean;
var
  xl, yl, xh, yh, x, y: integer;
  door_p, last_p: Pdoorobj_t;
begin
  // check for doors on the north wall
  xl := (xcenter - PLAYERSIZE) div FRACTILEUNIT;
  yl := (ycenter - PLAYERSIZE - (TILEUNIT div 2)) div FRACTILEUNIT;
  xh := (xcenter + PLAYERSIZE) div FRACTILEUNIT;
  yh := (ycenter + PLAYERSIZE - (TILEUNIT div 2)) div FRACTILEUNIT;
  for y := yl + 1 to yh do
    for x := xl to xh do
    begin
      if mapflags[y * MAPSIZE + x] and FL_DOOR <> 0 then // if tile has a door
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
              door_p.doorClosing := false;
              door_p.doorOpening := true;
              doorsound := true;
              doorx := door_p.tilex * FRACTILEUNIT;
              doory := door_p.tiley * FRACTILEUNIT;
              if door_p.orientation = dr_horizontal then
                TryDoor(xcenter + 64 * FRACUNIT, ycenter)
              else
                TryDoor(xcenter - 64 * FRACUNIT, ycenter);
              if netmode then
                NetOpenDoor(xcenter, ycenter);
              result := false;
              exit;
            end
            else if not door_p.doorOpen and door_p.doorBumpable and door_p.doorClosing then
            begin
              door_p.doorClosing := false;
              door_p.doorOpening := true;
              doorsound := true;
              doorx := door_p.tilex * FRACTILEUNIT;
              doory := door_p.tiley * FRACTILEUNIT;
              if door_p.orientation = dr_horizontal then
                TryDoor(xcenter + 64 * FRACUNIT, ycenter)
              else
                TryDoor(xcenter - 64 * FRACUNIT, ycenter);
              if netmode then
                NetOpenDoor(xcenter, ycenter);
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
  xl := (xcenter - PLAYERSIZE - (TILEUNIT div 2)) div FRACTILEUNIT;
  yl := (ycenter - PLAYERSIZE)  div FRACTILEUNIT;
  xh := (xcenter + PLAYERSIZE - (TILEUNIT div 2)) div FRACTILEUNIT;
  yh := (ycenter + PLAYERSIZE) div FRACTILEUNIT;
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
              doorsound := true;
              doorx := door_p.tilex * FRACTILEUNIT;
              doory := door_p.tiley * FRACTILEUNIT;
              if door_p.orientation = dr_vertical then
                TryDoor(xcenter, ycenter + 64 * FRACUNIT)
              else
                TryDoor(xcenter, ycenter - 64 * FRACUNIT);
              if netmode then
                NetOpenDoor(xcenter, ycenter);
              result := false;
              exit;
            end
            else if not door_p.doorOpen and door_p.doorBumpable and door_p.doorClosing then
            begin
              door_p.doorClosing := false;
              door_p.doorOpening := true;
              doorsound := true;
              doorx := door_p.tilex * FRACTILEUNIT;
              doory := door_p.tiley * FRACTILEUNIT;
              if door_p.orientation = dr_vertical then
                TryDoor(xcenter, ycenter + 64 * FRACUNIT)
              else
                TryDoor(xcenter, ycenter - 64 * FRACUNIT);
              if netmode then
                NetOpenDoor(xcenter, ycenter);
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


function TryMove(const angle: integer; xcenter, ycenter: fixed_t): boolean;
var
  xl, yl, xh, yh, x, y, mapspot: integer;
  pz: fixed_t;
begin
  if (angle < NORTH) or (angle > SOUTH) then
  begin
    xl := xcenter div FRACTILEUNIT;
    xh := (xcenter + PLAYERSIZE) div FRACTILEUNIT;
  end
  else if (angle > NORTH) and (angle < SOUTH) then
  begin
    xh := xcenter div FRACTILEUNIT;
    xl := (xcenter - PLAYERSIZE) div FRACTILEUNIT;
  end
  else
  begin
    xh := (xcenter + PLAYERSIZE) div FRACTILEUNIT;
    xl := (xcenter - PLAYERSIZE) div FRACTILEUNIT;
  end;

  if angle > WEST then
  begin
    yl := ycenter div FRACTILEUNIT;
    yh := (ycenter + PLAYERSIZE) div FRACTILEUNIT;
  end
  else if (angle < WEST) and (angle <> EAST) then
  begin
    yl := (ycenter - PLAYERSIZE) div FRACTILEUNIT;
    yh := ycenter div FRACTILEUNIT;
  end
  else
  begin
    yl := (ycenter - PLAYERSIZE) div FRACTILEUNIT;
    yh := (ycenter + PLAYERSIZE) div FRACTILEUNIT;
  end;

  pz := player.z - player.height + (26 * FRACUNIT);
  // check for solid walls
  for y := yl to yh do
    for x := xl to xh do
    begin
      mapspot := MAPCOLS * y + x;
      if (y > yl) and (northwall[mapspot] <> 0) and (northflags[mapspot] and F_NOCLIP = 0) then
      begin
        result := false;
        exit;
      end;
      if (x > xl) and (westwall[mapspot] <> 0) and (westflags[mapspot] and F_NOCLIP = 0) then
      begin
        result := false;
        exit;
      end;
      if mapspot <> player.mapspot then
      begin
        if (mapsprites[mapspot] > 0) and (mapsprites[mapspot] < 128) then
        begin
          result := false;
          exit;
        end;
        if RF_GetFloorZ((x * FRACTILEUNIT) + (32 * FRACUNIT), (y * FRACTILEUNIT) + (32 * FRACUNIT)) > pz then
        begin
          result := false;
          exit;
        end;
        if RF_GetCeilingZ((x * FRACTILEUNIT) + (32 * FRACUNIT), (y * FRACTILEUNIT) + (32 * FRACUNIT)) < player.z + (10 * FRACUNIT) then
        begin
          result := false;
          exit;
        end;
      end;
    end;

  result := true;
end;

// check for door at centerx, centery
procedure CheckHere(const useit: boolean; const centerx, centery: fixed_t; const angle: integer);
var
  mapspot, x, y, x1, y1: integer;
  elev_p: Pelevobj_t;
  switchit: boolean;
label
  skipit;
begin
  TryDoor(centerx, centery);
  x := centerx div FRACTILEUNIT;
  y := centery div FRACTILEUNIT;
  mapspot := y * MAPCOLS + x;
  switchit := false;

  if switches[x][y] <> 0 then
  begin
    if useit then
    begin
      if not CheckForSwitch(x, y, angle, true) then
        goto skipit;
      if netmode then
        NetCheckHere(centerx, centery, angle);
    end;
    SwitchWall(x, y, angle, true);
    RunEvent(switches[x][y], false);
  end;

skipit:
  case mapsprites[mapspot] of
  SM_SWAPSWITCH:
    begin
      if useit and not CheckForSwitch(x, y, angle, true) then
        exit;
      if useit and netmode then
        NetCheckHere(centerx, centery, angle);
      elev_p := firstelevobj.next;
      while elev_p <> @lastelevobj do
      begin
        if elev_p.typ = E_SWAP then
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
          SwitchWall(x, y, angle, true);
          SwitchTime := timecount + 3 * TICRATE;
        end;
        elev_p := elev_p.next;
      end;
    end;

  SM_STRIGGER:
    begin
      elev_p := firstelevobj.next;
      while elev_p <> @lastelevobj do
      begin
        if (elev_p.typ = E_SECRET) and not elev_p.elevDown and not elev_p.elevUp then
        begin
          x1 := elev_p.mapspot mod MAPCOLS;
          y1 := elev_p.mapspot div MAPCOLS;
          if (absI(x1 - x) < 2) and (absI(y1 - y) < 2) then
          begin
            switchit := true;
            elev_p.elevDown := true;
            elev_p.elevTimer := timecount;
            CheckHere(false, x1 * FRACTILEUNIT, y1 * FRACTILEUNIT, angle);
          end;
        end;
        elev_p := elev_p.next;
      end;
      if switchit and useit and netmode then
        NetCheckHere(centerx, centery, angle);
    end;
  end;
end;


procedure chargeweapons;
var
  i, n: integer;
  time: integer;
begin
  time := timecount;
  for i := 0 to 4 do
  begin
    n := player.weapons[i];
    while (n <> -1) and (weapons[n].charge < 100) and (time >= weapons[n].chargetime) do
    begin
      if weapons[n].charge = 0 then
        weapons[n].chargetime := timecount;
      weapons[n].charge := weapons[n].charge + 20;
      weapons[n].chargetime := weapons[n].chargetime + weapons[n].chargerate;
    end;
  end;
end;


function ClipMove(const angle: integer; const xmove, ymove: fixed_t): boolean;
var
  dx, dy: fixed_t;
  angle2: integer;
begin
  dx := player.x + xmove;
  dy := player.y + ymove;
  if TryMove(angle, dx, dy) and TryDoor(dx, dy) then
  begin
    if floorpic[(dy div FRACTILEUNIT) * MAPCOLS + (dx div FRACTILEUNIT)] = 0 then
    begin
      result := false;
      exit;
    end;
    player.x := player.x + xmove;
    player.y := player.y + ymove;
    result := true;
    exit;
  end;

  // the move goes into a wall, so try and move along one axis
  if xmove > 0 then
    angle2 := EAST
  else
    angle2 := WEST;
  if TryMove(angle2, dx, player.y) and TryDoor(dx, player.y) then
  begin
    if floorpic[(player.y div FRACTILEUNIT) * MAPCOLS + (dx div FRACTILEUNIT)] = 0 then
    begin
      result := false;
      exit;
    end;
    player.x := player.x + xmove;
    result := true;
    exit;
  end;

  if ymove > 0 then
    angle2 := SOUTH
  else
    angle2 := NORTH;
  if TryMove(angle2, player.x, dy) and TryDoor(player.x, dy) then
  begin
    if floorpic[(dy div FRACTILEUNIT) * MAPCOLS + (player.x div FRACTILEUNIT)] = 0 then
    begin
      result := false;
      exit;
    end;
    player.y := player.y + ymove;
    result := true;
    exit;
  end;

  result := false;
end;


function Thrust(const ang: integer; const speed: fixed_t): boolean;
var
  xmove, ymove: fixed_t;
  angle: integer;
begin
  angle := ang and ANGLES;
  xmove := FIXEDMUL(speed, costable[angle]);
  ymove := -FIXEDMUL(speed, sintable[angle]);
  result := ClipMove(angle, xmove, ymove);
  player.mapspot := (player.y div FRACTILEUNIT) * MAPCOLS + (player.x div FRACTILEUNIT);
end;


procedure ControlMovement;
var
  modifiedSpeed: fixed_t;
  modifiedTurn, modifiedMoveUnit, modifiedturnunit, n: integer;
  floorz, fz, xl, yl, xh, yh, maxz: fixed_t;
  maxx, maxy, mapspot: integer;
  imousedx, imousedy: integer;
begin
  if Warping <> 0 then
  begin
   floorz := RF_GetFloorZ(player.x, player.y) + player.height;
   if player.z > floorz then
   begin
     fallrate := fallrate + MOVEUNIT;
     player.z := player.z - fallrate;
     if player.z < floorz then
        player.z := floorz;
   end
   else if player.z < floorz then
   begin
     player.z := floorz;
     fallrate := 0;
   end;
   exit;
 end;

  if SC.mouse = 1 then
  begin
    mousebuttons[mbt_fire] := mouse.flags and 1 <> 0;
    mousebuttons[mbt_use] := mouse.flags and 2 <> 0;
    mousebuttons[mbt_north] := mouse.flags and 4 <> 0;
    if mousebuttons[mbt_north] then
      mousebuttons[mbt_north] := true;
    mousedx := mousedx + ((mouse.dx * FRACUNIT * (SC.mousesensitivity + 5)) div 10) * (mousesensitivityx + 1) div 5;
    mousedy := mousedy + ((mouse.dy * FRACUNIT * (SC.mousesensitivity + 5)) div 10) * (mousesensitivityy + 1) div 5;
  end
  else
  begin
    mousebuttons[mbt_fire] := false;
    mousebuttons[mbt_use] := false;
    mousebuttons[mbt_north] := false;
    mousedx := 0;
    mousedy := 0;
  end;

  // JVAL: invert mouse
  if invertmouseturn then
    imousedx := -mousedx
  else
    imousedx := mousedx;

  if invertmouselook then
    imousedy := -mousedy
  else
    imousedy := mousedy;

  // For smooth mouse movement
  if mousedx <> 0 then
    mousedx := mousedx div 2;
  if mousedy <> 0 then
    mousedy := mousedy div 2;

  if (keyboard[SC_ESCAPE] = 1) and (timecount > keyboardDelay) and (netmsgstatus = 0) then
  begin
    eat_key(SC_ESCAPE);
    activatemenu := true;
    keyboardDelay := timecount + ACTIVATEMENUDELAY;
  end;

  if (keyboard[SC_F5] <> 0) and (keyboard[SC_LSHIFT] <> 0) and (timecount > keyboardDelay) then
  begin
    adjustvrangle := -SC.vrangle + DEFAULTVRANGLE;
    adjustvrdist := -1;
    keyboardDelay := timecount + KBDELAY;
  end;

  if (keyboard[SC_F4] <> 0) and (keyboard[SC_LSHIFT] <> 0) and (timecount > keyboardDelay) then
  begin
    adjustvrdist := 72090;
    keyboardDelay := timecount + KBDELAY;
  end;

  if (keyboard[SC_F3] <> 0) and (keyboard[SC_LSHIFT] <> 0) and (timecount > keyboardDelay) then
  begin
    adjustvrdist := 59578;
    keyboardDelay := timecount + KBDELAY;
  end;

  if (keyboard[SC_F2] <> 0) and (keyboard[SC_LSHIFT] <> 0) and (timecount > keyboardDelay) then
  begin
    adjustvrangle := 1;
    keyboardDelay := timecount + KBDELAY;
  end;

  if (keyboard[SC_F1] <> 0) and (keyboard[SC_LSHIFT] <> 0) and (timecount > keyboardDelay) then
  begin
    adjustvrangle := -1;
    keyboardDelay := timecount + KBDELAY;
  end;

  if (keyboard[SC_F1] <> 0) and (timecount > keyboardDelay) then
  begin
    activatehelp := true;
    keyboardDelay := timecount + KBDELAY;
  end;

  if ((keyboard[SC_F4] <> 0) or ((keyboard[SC_ALT] <> 0) and (keyboard[SC_Q] <> 0))) and (timecount > keyboardDelay) then
  begin
    QuickExit := true;
    keyboardDelay := timecount + KBDELAY;
  end;

  if (keyboard[SC_F5] <> 0) and (timecount > keyboardDelay) and not netmode then
  begin
    activatebrief := true;
    keyboardDelay := timecount + KBDELAY;
  end;

  if (keyboard[SC_P] = 1) and (timecount > keyboardDelay) and (netmsgstatus = 0) then
  begin
    eat_key(SC_P);
    paused := true;
    keyboardDelay := timecount + KBDELAY;
  end;

  // change screen size
  if (keyboard[SC_F9] <> 0) and not resizeScreen and (timecount > keyboardDelay) then
  begin
    resizeScreen := true;
    biggerScreen := true;
    keyboardDelay := timecount + KBDELAY;
    if SC.screensize < MAXVIEWSIZE - 1 then
      inc(SC.screensize);
    exit;
  end;

  if (keyboard[SC_F10] <> 0) and not resizeScreen and (timecount > keyboardDelay) then
  begin
    resizeScreen := true;
    biggerScreen := false;
    keyboardDelay := timecount + KBDELAY;
    if SC.screensize > 0 then
      dec(SC.screensize);
    exit;
  end;

  if (keyboard[SC_MINUS] <> 0) and (timecount > keyboardDelay) and (netmsgstatus = 0) then
  begin
    case MapZoom of
    8: MapZoom := 4;
    16: MapZoom := 8;
    end;
    keyboardDelay := timecount + KBDELAY;
  end;

  if (keyboard[SC_PLUS] <> 0) and (timecount > keyboardDelay) and (netmsgstatus = 0) then
  begin
    case MapZoom of
    4: MapZoom := 8;
    8: MapZoom := 16;
    end;
    keyboardDelay := timecount + KBDELAY;
  end;

  if ((in_button[bt_lookup] <> 0) or (imousedy > FRACUNIT)) and (netmsgstatus = 0) then
    scrollview := scrollview - SCROLLRATE;
  if ((in_button[bt_lookdown] <> 0) or (imousedy < -FRACUNIT)) and (netmsgstatus = 0) then
    scrollview := scrollview + SCROLLRATE;
  if (in_button[bt_centerview] <> 0) and (netmsgstatus = 0) then
    scrollview := 255;

  if scrollview = 255 then
  begin
    if player.scrollmin < 0 then
    begin
      player.scrollmin := player.scrollmin + SCROLLRATE;
      player.scrollmax := player.scrollmax + SCROLLRATE;
    end
    else if player.scrollmin > 0 then
    begin
      player.scrollmin := player.scrollmin - SCROLLRATE;
      player.scrollmax := player.scrollmax - SCROLLRATE;
    end
    else
      scrollview := 0;
  end;

  // display mode toggles
  if (keyboard[SC_M] <> 0) and (timecount > keyboardDelay) and (netmsgstatus = 0) then
  begin
    togglemapmode := true;
    keyboardDelay := timecount + KBDELAY;
  end;
  if (keyboard[SC_H] <> 0) and (timecount > keyboardDelay) and (netmsgstatus = 0) then
  begin
    toggleheatmode := true;
    keyboardDelay := timecount + KBDELAY;
  end;
  if (keyboard[SC_S] <> 0) and (timecount > keyboardDelay) and (netmsgstatus = 0) then
  begin
    togglemotionmode := true;
    keyboardDelay := timecount + KBDELAY;
  end;
  if (in_button[bt_asscam] <> 0) and (timecount > keyboardDelay) and (netmsgstatus = 0) then
  begin
    ToggleRearView := true;
    keyboardDelay := timecount + KBDELAY;
  end;
  if (keyboard[SC_TAB] <> 0) and (timecount > keyboardDelay) and (netmsgstatus = 0) then
  begin
    togglegoalitem := true;
    keyboardDelay := timecount + KBDELAY;
  end;


  if (keyboard[SC_CAPSLOCK] <> 0) and (timecount > keyboardDelay) then
  begin
    toggleautorun := true;
    keyboardDelay := timecount + KBDELAY;
  end;
  if (keyboard[SC_NUMLOCK] <> 0) and (timecount > keyboardDelay) then
  begin
   toggleautotarget := true;
   keyboardDelay := timecount + KBDELAY;
  end;

  // secrets
  if newascii then
  begin
    if Pos(toupper(lastascii), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789') > 0 then
    begin
      if Length(secretbuf) >= SECRETBUFSIZE - 1 then
        Delete(secretbuf, 1, 1);
      secretbuf := secretbuf + lastascii;
    end;
    if netmsgstatus = 1 then  // getting message
    begin
      case Ord(lastascii) of
      27:
        netmsgstatus := 0;
      8:
        begin
          netmsg[netmsgindex] := ' ';
          if netmsgindex > 0 then
            dec(netmsgindex);
          netmsg[netmsgindex] := '_';
        end;
      13:
        begin
          netmsgstatus := 2; // sending
          netmsg[netmsgindex] := ' ';
        end;
      else
        netmsg[netmsgindex] := lastascii;
        if netmsgindex < NETMSGSIZE - 1 then
          inc(netmsgindex);
        netmsg[netmsgindex] := '_';
      end;
    end;
    newascii := false;
    secretdelay := timecount + KBDELAY * 5;
  end;

  if timecount > secretdelay then
    secretdelay := timecount + KBDELAY;

  if (keyboard[SC_F6] <> 0) and netmode and (netmsgstatus = 0) and (timecount > keyboardDelay) then
  begin
    memset(@netmsg, 0, SizeOf(netmsg));
    netmsgstatus := 1;
    netmsgindex := 0;
    netmsg[0] := '_';
    keyboardDelay := timecount + KBDELAY;
  end;

  if (keyboard[SC_F7] <> 0) and (timecount > keyboardDelay) then
  begin
    newsong := true;
    keyboardDelay := timecount + KBDELAY;
  end;

  if (in_button[bt_invright] <> 0) and (timecount > inventorydelay) then
  begin
    goiright := true;
    inventorydelay := timecount + KBDELAY;
    inventorytime := timecount + (3 * TICRATE);
  end;

  if (in_button[bt_invleft] <> 0) and (timecount > inventorydelay) then
  begin
    goileft := true;
    inventorydelay := timecount + KBDELAY;
    inventorytime := timecount + (3 * TICRATE);
  end;

  // he's dead jim!
  if player.angst = 0 then
  begin
    if (floorpic[player.mapspot] >= 57) and (floorpic[player.mapspot] <= 59) then
    begin
      if player.z > RF_GetFloorZ(player.x, player.y) + (40 * FRACUNIT) then
        player.z := player.z - FRACUNIT
      else if player.z < RF_GetFloorZ(player.x, player.y) + (40 * FRACUNIT) then
        player.z := RF_GetFloorZ(player.x, player.y) + (40 * FRACUNIT);
    end
    else
    begin
      if player.z > RF_GetFloorZ(player.x, player.y) + (12 * FRACUNIT) then
        player.z := player.z - FRACUNIT
      else if player.z < RF_GetFloorZ(player.x, player.y) + (12 * FRACUNIT) then
        player.z := RF_GetFloorZ(player.x, player.y) + (12 * FRACUNIT);
    end;
    if (keyboard[SC_SPACE] <> 0) then
      deadrestart := true;
    exit;
  end;

  if (in_button[bt_useitem] <> 0) and (timecount > usedelay) then
  begin
    useitem := true;
    usedelay := timecount + KBDELAY;
    inventorytime := timecount + (3 * TICRATE);
  end;

  // change weapon
  if (keyboard[SC_1] <> 0) and not changingweapons and (player.currentweapon <> 0) and (netmsgstatus = 0) then
  begin
    changingweapons := true;
    weaponlowering := true;
    newweapon := 0;
  end
  else if (keyboard[SC_2] <> 0) and not changingweapons and (player.currentweapon <> 1) and (player.weapons[1] <> -1) and (netmsgstatus = 0) then
  begin
    changingweapons := true;
    weaponlowering := true;
    newweapon := 1;
  end
  else if (keyboard[SC_3] <> 0) and not changingweapons and (player.currentweapon <> 2) and (player.weapons[2] <> -1) and (netmsgstatus = 0) then
  begin
    changingweapons := true;
    weaponlowering := true;
    newweapon := 2;
  end
  else if (keyboard[SC_4] <> 0) and not changingweapons and (player.currentweapon <> 3) and (player.weapons[3] <> -1) and (netmsgstatus = 0) then
  begin
    changingweapons := true;
    weaponlowering := true;
    newweapon := 3;
  end
  else if (keyboard[SC_5] <> 0) and not changingweapons and (player.currentweapon <> 4) and (player.weapons[4] <> -1) and (netmsgstatus = 0) then
  begin
    changingweapons := true;
    weaponlowering := true;
    newweapon := 4;
  end;

  if (in_button[bt_jump] <> 0) and (timecount > jumpdelay) and (fallrate = 0) and (netmsgstatus = 0) then
  begin
    fallrate := fallrate - (FALLUNIT * 9 + player.jumpmod);
    jumpdelay := timecount + KBDELAY;
  end;

  // check run/slow keys
  if (in_button[bt_run] <> 0) or autorun then
  begin
    modifiedSpeed := PLAYERMOVESPEED * 6 + player.runmod;
    modifiedTurn := (playerturnspeed * 5) div 2;
    modifiedMoveUnit := MOVEUNIT * 2;
    modifiedturnunit := turnunit;
  end
  else
  begin
    modifiedSpeed := (PLAYERMOVESPEED * 7) div 2 + player.walkmod;
    modifiedTurn := playerturnspeed;
    modifiedMoveUnit := MOVEUNIT;
    modifiedturnunit := turnunit * 2;
  end;

  floorz := RF_GetFloorZ(player.x, player.y) + player.height;
  if (floorpic[player.mapspot] >= 57) and (floorpic[player.mapspot] <= 59) then
  begin
    if player.z = floorz then
      modifiedSpeed := modifiedSpeed div 2;
  end;

  // check strafe
  if ((in_button[bt_straf] <> 0) or (in_button[bt_slideleft] <> 0) or (in_button[bt_slideright] <> 0)) and (netmsgstatus = 0) then
  begin
    if (in_button[bt_west] <> 0) or (in_button[bt_slideleft] <> 0) then
    begin
      strafrate := strafrate - modifiedMoveUnit;
      if strafrate < -modifiedSpeed then
        strafrate := strafrate + modifiedMoveUnit;
    end;
    if (in_button[bt_east] <> 0) or (in_button[bt_slideright] <> 0) then
    begin
      strafrate := strafrate + modifiedMoveUnit;
      if strafrate > modifiedSpeed then
        strafrate := strafrate - modifiedMoveUnit;
    end
    else if (in_button[bt_west] = 0) and (in_button[bt_slideleft] = 0) then
    begin
      if strafrate < 0 then
        strafrate := strafrate + MOVEUNIT
      else if strafrate > 0 then
        strafrate := strafrate - MOVEUNIT;
    end;
  end
  else
  begin
    if strafrate < 0 then
      strafrate := strafrate + MOVEUNIT
    else if strafrate > 0 then
      strafrate := strafrate - MOVEUNIT;

    // not strafing
    if in_button[bt_east] <> 0 then
    begin
      turnrate := turnrate - modifiedturnunit;
      if turnrate < -modifiedTurn then
        turnrate := -modifiedTurn;
      player.angle := player.angle + turnrate;
    end
    else if in_button[bt_west] <> 0 then
    begin
      turnrate := turnrate + modifiedturnunit;
      if turnrate > modifiedTurn then
        turnrate := modifiedTurn;
      player.angle := player.angle + turnrate;
    end
    else if imousedx <= -FRACUNIT then
    begin
      turnrate := turnrate - modifiedturnunit div 2 + imousedx div (2 * FRACUNIT);
      if turnrate < -modifiedTurn then
        turnrate := -modifiedTurn;
      player.angle := player.angle + turnrate;
    end
    else if imousedx >= FRACUNIT then
    begin
      turnrate := turnrate + modifiedturnunit div 2 + imousedx div (2 * FRACUNIT);
      if turnrate > modifiedTurn then
        turnrate := modifiedTurn;
      player.angle := player.angle + turnrate;
    end
    else
    begin
      if turnrate < 0 then
      begin
        turnrate := turnrate + modifiedturnunit;
        if turnrate > 0 then
          turnrate := 0
      end
      else if turnrate > 0 then
      begin
        turnrate := turnrate - modifiedturnunit;
        if turnrate < 0 then
          turnrate := 0;
      end;
      player.angle := player.angle + turnrate;
    end;
    player.angle := player.angle and ANGLES;
  end;

  if strafrate < 0 then
  begin
    if not Thrust(player.angle + NORTH, -strafrate) then
    begin
      moverate := 0;
      strafrate := 0;
    end
  end
  else if strafrate > 0 then
  begin
    if not Thrust(player.angle + SOUTH, strafrate) then
    begin
      moverate := 0;
      strafrate := 0;
    end;
  end;

  // forward/backwards move
  if (in_button[bt_north] <> 0) or mousebuttons[mbt_north] then
    moveforward := 1
  else if in_button[bt_south] <> 0 then
    moveforward := -1
  else
    moveforward := 0;

  // compute move vectors
  if moveforward = 1 then
  begin
    if moverate < modifiedSpeed then
      moverate := moverate + modifiedMoveUnit;
    if moverate > modifiedSpeed then
      moverate := moverate - modifiedMoveUnit;
  end
  else if moveforward = -1 then
  begin
    if moverate > -modifiedSpeed then
      moverate := moverate - modifiedMoveUnit;
    if moverate < -modifiedSpeed then
      moverate := moverate + modifiedMoveUnit;
  end
  else if moverate <> 0 then
  begin
    if moverate < 0 then
      moverate := moverate + MOVEUNIT
    else
      moverate := moverate - MOVEUNIT;
  end;

  // move along move vector & compute head bobbing
  if moverate < 0 then
  begin
    if headbob = MAXBOBS - 1 then
      headbob := 0
    else
      inc(headbob);
    if wbobcount = 4 then
    begin
      wbobcount := 0;
      if weapbob = MAXBOBS - 1 then
        weapbob := 0
      else
        inc(weapbob);
    end
    else
      inc(wbobcount);
    if not Thrust(player.angle + WEST, -moverate) then
      moverate := 0;
  end
  else if moverate > 0 then
  begin
    if headbob = MAXBOBS - 1 then
      headbob := 0
    else
      inc(headbob);
    if wbobcount = 4 then
    begin
      wbobcount := 0;
      if weapbob = MAXBOBS - 1 then
        weapbob := 0
      else
        inc(weapbob);
    end
    else
      inc(wbobcount);
    if not Thrust(player.angle, moverate) then
      moverate := 0;
  end
  else if timecount and 8 <> 0 then
  begin
    if weapmove[weapbob] <> 0 then
    begin
      if absI(weapmove[weapbob - 1]) < absI(weapmove[weapbob]) then
        dec(weapbob)
      else
      begin
        inc(weapbob);
        if weapbob = MAXBOBS then
          weapbob := 0;
      end;
    end;
    if headmove[headbob] <> 0 then
    begin
      if absI(headmove[headbob - 1]) < absI(headmove[headbob]) then
        dec(headbob)
      else
      begin
        inc(headbob);
        if headbob = MAXBOBS then
          headbob := 0;
      end;
    end;
  end;

  // try to open a door in front of player
  if ((in_button[bt_use] <> 0) or mousebuttons[mbt_use]) and (timecount > keyboardDelay) and (netmsgstatus = 0) then
  begin
    checktrigger := true;
    keyboardDelay := timecount + KBDELAY * 2;
  end;

  // fire a weapon
  if ((in_button[bt_fire] <> 0) or mousebuttons[mbt_fire]) and (weapons[player.weapons[player.currentweapon]].charge = 100) and not changingweapons then
  begin
    n := player.weapons[player.currentweapon];
    if (n = 18) or (n = 4) then
    begin
      if (player.ammo[weapons[n].ammotype] >= weapons[n].ammorate) and (weapmode = 0) then
        weapmode := 1;
    end
    else
      RF_SetActionHook(fireweapon);
  end;

  // compute falling or stepping up higher
  xl := (player.x - FRACUNIT * 8) div FRACTILEUNIT;
  xh := (player.x + FRACUNIT * 8) div FRACTILEUNIT;
  yl := (player.y - FRACUNIT * 8) div FRACTILEUNIT;
  yh := (player.y + FRACUNIT * 8) div FRACTILEUNIT;
  floorz := player.z - player.height;
  maxz := 0;
  while xl <= xh do
  begin
    while yl <= yh do
    begin
      fz := RF_GetFloorZ((xl * 64 + 32) * FRACUNIT, (yl * 64 + 32) * FRACUNIT);
      if (fz > maxz) and (fz < floorz + (20 * FRACUNIT)) then
      begin
        maxz := fz;
        maxx := xl;
        maxy := yl;
      end;
      inc(yl);
    end;
    inc(xl);
  end;

  if maxz = 0 then
  begin
    maxz := RF_GetFloorZ(player.x, player.y);
    maxx := player.x div FRACTILEUNIT;
    maxy := player.y div FRACTILEUNIT;
  end;
  floorz := maxz + player.height;

  if absI(player.z - floorz) <= 10 * FRACUNIT then
  begin
    mapspot := maxy * MAPCOLS + maxx;
    if floorflags[mapspot] and F_RIGHT <> 0 then
      Thrust(EAST, FRACUNIT * 4);
    if floorflags[mapspot] and F_LEFT <> 0 then
      Thrust(WEST, FRACUNIT * 4);
    if floorflags[mapspot] and F_UP <> 0 then
      Thrust(NORTH, FRACUNIT * 4);
    if floorflags[mapspot] and F_DOWN <> 0 then
      Thrust(SOUTH, FRACUNIT * 4);
  end;

// floorz := RF_GetFloorZ(player.x, player.y)+player.height;

  player.z := player.z - fallrate;
  if player.z > floorz then
    fallrate := fallrate + FALLUNIT
  else if player.z < floorz then
  begin
    if fallrate >= 12 * FRACUNIT then
      falldamage := (fallrate div FRACUNIT) div 7;
    player.z := player.z + 4 * FRACUNIT;
    if player.z > floorz then
      player.z := floorz;
    fallrate := 0;
  end;
  floorz := RF_GetCeilingZ(player.x, player.y);
  if player.z + (10 * FRACUNIT) > floorz then
  begin
    player.z := floorz - 10 * FRACUNIT;
    fallrate := FALLUNIT;
  end;
end;


// called by an interrupt
procedure PlayerCommand;
begin
  ControlMovement;
end;


procedure newlights;
begin
  if lighting + changelight > 4096 then
    lighting := 4096
  else
    lighting := lighting + changelight;
  if lighting <= 0 then
    lighting := 1;
  RF_SetLights(lighting * FRACUNIT);
  changelight := 0;
end;


procedure ChangeScroll;
begin
  if scrollview = 255 then
    exit;
  if (player.scrollmin + scrollview <= -MAXSCROLL) or (player.scrollmin + scrollview >= MAXSCROLL) then
  begin
    scrollview := 0;
    exit;
  end;
  player.scrollmin := player.scrollmin + scrollview;
  player.scrollmax := player.scrollmax + scrollview;
  scrollview := 0;
end;

function Check_Secret(const code: string): boolean;
var
  p: integer;
  i: integer;
begin
  p := Pos(strupper(code), strupper(secretbuf));
  if p > 0 then
  begin
    secretbuf := '';
    result := true;
  end
  else
    result := false;
end;

// secrets
procedure Special_Code;
var
  hsprite_p, sprite_p: Pscaleobj_t;
  i: integer;
begin
  if netmode and (MS_CheckParm('ravenger') = 0) then
  begin
    secretbuf := '';
    exit;
  end;

  if Check_Secret('belfast') then
  begin
    sprite_p := firstscaleobj.next;
    while sprite_p <> @lastscaleobj do
    begin
      if sprite_p.hitpoints <> 0 then
      begin
        mapsprites[(sprite_p.y div FRACTILEUNIT) * MAPCOLS + (sprite_p.x div FRACTILEUNIT)] := 0;
        hsprite_p := sprite_p;
        sprite_p := sprite_p.prev;
        KillSprite(hsprite_p, S_BULLET3);
        inc(player.bodycount);
      end;
      sprite_p := sprite_p.next;
    end;
    writemsg('DeathKiss');
  end
  else if Check_Secret('allahmode') then
  begin
    if godmode then
    begin
      godmode := false;
      writemsg('GodMode Off');
    end
    else
    begin
      godmode := true;
      writemsg('GodMode On');
    end;
  end
  else if Check_Secret('channel7') then
  begin
    writemsg('Rob Lays Eggs');
  end
  else if Check_Secret('lizardman') then
  begin
    writemsg('Jeremy Lays Eggs');
  end
  else if Check_Secret('dominatrix') then
  begin
    writemsg('On your knees worm!');
  end
  else if Check_Secret('cyborg') then
  begin
    writemsg('Psyborgs Rule!');
  end
  else if Check_Secret('mooman') then
  begin
    writemsg('Brady is better than you, and that ain''t saying much!');
  end
  else if Check_Secret('raven') then
  begin
    player.angst := player.maxangst;
    player.shield := player.maxshield;
    writemsg('Ambrosia');
  end
  else if Check_Secret('omni') then
  begin
    for i := 0 to MAPCOLS * MAPROWS - 1 do
      if northwall[i] and 255 <> 0 then
        player.northmap[i] := WALL_COLOR;
    for i := 0 to MAPCOLS * MAPROWS - 1 do
      if westwall[i] and 255 <> 0 then
        player.westmap[i] := WALL_COLOR;
    writemsg('Omniscience');
  end
  else if Check_Secret('kmfdm') then
  begin
    player.ammo[0] := 999;
    player.ammo[1] := 999;
    player.ammo[2] := 999;
    writemsg('Backpack of Holding');
    oldshots := -1;
  end
  else if Check_Secret('beavis') then
  begin
    player.levelscore := 100;
    player.primaries[0] := pcount[0];
    player.primaries[1] := pcount[1];
    for i := 0 to 6 do
      player.secondaries[i] := scount[i];
    writemsg('Time Warp');
  end
  else if Check_Secret('gulliver') then
  begin
    if midgetmode then
    begin
      sprite_p := firstscaleobj.next;
      while sprite_p <> @lastscaleobj do
      begin
        dec(sprite_p.scale);
        sprite_p := sprite_p.next;
      end;
      midgetmode := false;
      writemsg('Midget Mode Off');
    end
    else
    begin
      sprite_p := firstscaleobj.next;
      while sprite_p <> @lastscaleobj do
      begin
        inc(sprite_p.scale);
        sprite_p := sprite_p.next;
      end;
      midgetmode := true;
      writemsg('Midget Mode On');
    end;
  end
  else if Check_Secret('gimme') then
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
    if not DEMO then
    begin
      player.inventory[9] := 10;
      player.inventory[10] := 10;
      player.inventory[11] := 10;
      player.inventory[12] := 10;
    end;
    writemsg('Bag of Holding');
  end
  else if Check_Secret('taco') then
  begin
    enemyviewmode := enemyviewmode xor 1;
    writemsg('Enemy view toggled');
  end
  else if Check_Secret('game1') then
  begin
    GAME1 := true;
    GAME2 := false;
    GAME3 := false;
    newmap(0, 2);
  end
  else if Check_Secret('game2') and not DEMO then
  begin
    GAME1 := false;
    GAME2 := true;
    GAME3 := false;
    newmap(8, 2);
  end
  else if Check_Secret('game3') and not DEMO then
  begin
    GAME1 := false;
    GAME2 := false;
    GAME3 := true;
    newmap(16, 2);
  end
  else if Length(secretbuf) > 2 then
  begin
    if Pos('GO', strupper(secretbuf)) > 0 then
    begin
      if DEMO or GAME1 then
      begin
        if Check_Secret('go01') then
          newmap(0, 2)
        else if Check_Secret('go02') then
          newmap(1, 2)
        else if Check_Secret('go03') then
          newmap(2, 2);
      end;

      if not DEMO then
      begin
        if GAME1 then
        begin
          if Check_Secret('go04') then
            newmap(3, 2)
          else if Check_Secret('go05') then
            newmap(4, 2)
          else if Check_Secret('go06') then
            newmap(5, 2)
          else if Check_Secret('go07') then
            newmap(6, 2)
        end;

        if GAME2 then
        begin
          if Check_Secret('go08') then
            newmap(7, 2)
          else if Check_Secret('go09') then
            newmap(8, 2)
          else if Check_Secret('go10') then
            newmap(9, 2)
          else if Check_Secret('go11') then
            newmap(10, 2)
          else if Check_Secret('go12') then
            newmap(11, 2)
          else if Check_Secret('go13') then
            newmap(12, 2)
          else if Check_Secret('go14') then
            newmap(13, 2)
          else if Check_Secret('go15') then
            newmap(14, 2)
        end;

        if GAME3 then
        begin
          if Check_Secret('go16') then
            newmap(15, 2)
          else if Check_Secret('go17') then
            newmap(16, 2)
          else if Check_Secret('go18') then
            newmap(17, 2)
          else if Check_Secret('go19') then
            newmap(18, 2)
          else if Check_Secret('go20') then
            newmap(19, 2)
          else if Check_Secret('go21') then
            newmap(20, 2)
          else if Check_Secret('go22') then
            newmap(21, 2);
        end;

        if Check_Secret('go23') then
          newmap(22, 2)
        else if Check_Secret('go24') then
          newmap(23, 2)
        else if Check_Secret('go25') then
          newmap(24, 2)
        else if Check_Secret('go26') then
          newmap(25, 2)
        else if Check_Secret('go27') then
          newmap(26, 2)
        else if Check_Secret('go28') then
          newmap(27, 2)
        else if Check_Secret('go29') then
          newmap(28, 2)
        else if Check_Secret('go30') then
          newmap(29, 2)
        else if Check_Secret('go31') then
          newmap(30, 2)
        else if Check_Secret('go32') then
          newmap(31, 2);
      end;

      INT_TimerHook(PlayerCommand);
    end;

    if Pos('BL', strupper(secretbuf)) > 0 then
    begin
      if Check_Secret('blammo1') then
        player.weapons[2] := 2
      else if Check_Secret('blammo2') then
        player.weapons[2] := 3
      else if Check_Secret('blammo3') then
        player.weapons[2] := 4
      else if Check_Secret('blammo4') then
        player.weapons[2] := 16
      else if Check_Secret('blammo5') then
        player.weapons[2] := 17
      else if Check_Secret('blammo6') then
        player.weapons[2] := 18;
      if player.weapons[2] >= 0 then
      begin
        loadweapon(player.weapons[2]);
        player.currentweapon := 2;
        weapmode := 0;
      end;
    end;
  end;
end;


procedure CheckSpawnAreas;
var
  sa: Pspawnarea_t;
  i, count, typ, stype: integer;
  sprite_p: Pscaleobj_t;
begin
  if specialeffect = SE_WARPJAMMER then
    exit;
  if netwarpjammer and (netwarpjamtime > timecount) then
    exit;

  for i := 0 to numspawnareas - 1 do
  begin
    sa := @spawnareas[i];
    if timecount >= sa.time then
    begin
      if (mapsprites[sa.mapspot] = 0) and (sa.mapspot <> player.mapspot) then
      begin
        case sa.typ of
        0:
          begin
            if not netmode then
            begin
              if DEMO then
                typ := (clock + MS_RndT) mod 110
              else
                typ := (clock + MS_RndT) mod 114;
              if (typ < 30) then
                stype := S_ENERGY
              else if (typ < 60) then
                stype := S_BALLISTIC
              else if (typ < 90) then
                stype := S_PLASMA
              else if (typ < 96) then
                stype := S_IGRENADE
              else if (typ < 98) then
                stype := S_IREVERSO
              else if (typ < 102) then
                stype := S_IPROXMINE
              else if (typ < 106) then
                stype := S_ITIMEMINE
              else if (typ < 108) then
                stype := S_IINSTAWALL
              else if (typ < 110) and not DEMO then
                stype := S_ICLONE
              else if (typ < 112) and not DEMO then
                stype := S_IJAMMER
              else if DEMO then
                stype := S_ICLONE
              else
                stype := S_ISTEALER;
              sa.time := timecount + (clock and 255) + 3500 - (350 * (player.difficulty + 1));
            end
            else
            begin
              if DEMO then
                typ := (clock + MS_RndT) mod 110
              else
                typ := (clock + MS_RndT) mod 146;
              if typ < 30 then
                stype := S_ENERGY
              else if (typ < 60) then
                stype := S_BALLISTIC
              else if (typ < 90) then
                stype := S_PLASMA
              else if (typ < 96) and DEMO then
                stype := S_IGRENADE
              else if (typ < 98) and DEMO then
                stype := S_IREVERSO
              else if (typ < 102) and DEMO then
                stype := S_IPROXMINE
              else if (typ < 106) and DEMO then
                stype := S_ITIMEMINE
              else if (typ < 108) and DEMO then
                stype := S_IDECOY
              else if (typ < 98) and not DEMO
                then stype := S_IGRENADE
              else if (typ < 102) and not DEMO then
                stype := S_IREVERSO
              else if (typ < 112) and not DEMO then
                stype := S_IPROXMINE
              else if (typ < 116) and not DEMO then
                stype := S_ITIMEMINE
              else if (typ < 120) and not DEMO then
                stype := S_IDECOY
              else if (typ < 134) and not DEMO then
                stype := S_IINSTAWALL
              else if (typ < 138) and not DEMO then
                stype := S_IINVIS
              else if (typ < 142) and not DEMO then
                stype := S_ISTEALER
              else if DEMO then
                stype := S_IINSTAWALL
              else
                stype := S_IHOLO;
              sa.time := timecount + (clock and 255) + (9 - greedcom.numplayers) * 437;
            end;
          end;

        1:
          begin
            if not netmode then
            begin
              if DEMO then
                typ := (clock + MS_RndT) mod 110
              else
                typ := (clock + MS_RndT) mod 114;
              if typ < 15 then
                stype := S_MEDPAK1
              else if (typ < 22) then
                stype := S_MEDPAK2
              else if (typ < 30) then
                stype := S_MEDPAK3
              else if (typ < 45) then
                stype := S_MEDPAK4
              else if (typ < 60) then
                stype := S_SHIELD4
              else if (typ < 67) then
                stype := S_SHIELD3
              else if (typ < 75) then
                stype := S_SHIELD2
              else if (typ < 90) then
                stype := S_SHIELD1
              else if (typ < 96) and DEMO then
                stype := S_IGRENADE
              else if (typ < 98) and DEMO then
                stype := S_IREVERSO
              else if (typ < 102) and DEMO then
                stype := S_IPROXMINE
              else if (typ < 106) and DEMO then
                stype := S_ITIMEMINE
              else if (typ < 108) and DEMO then
                stype := S_IINSTAWALL
              else if (typ < 96) and not DEMO then
                stype := S_IGRENADE
              else if (typ < 98) and not DEMO then
                stype := S_IREVERSO
              else if (typ < 102) and not DEMO then
                stype := S_IPROXMINE
              else if (typ < 106) and not DEMO then
                stype := S_ITIMEMINE
              else if (typ < 108) and not DEMO then
                stype := S_IINSTAWALL
              else if (typ < 110) and not DEMO then
                stype := S_ICLONE
              else if (typ < 112) and not DEMO then
                stype := S_IJAMMER
              else if DEMO then
                stype := S_ICLONE
              else
                stype := S_ISTEALER;
              sa.time := timecount + (clock and 255) + 3500 - (350 * (player.difficulty + 1));
            end
            else
            begin
              if DEMO then
                typ := (clock + MS_RndT) mod 110
              else
                typ := (clock + MS_RndT) mod 116;
              if typ < 15 then
                stype := S_MEDPAK1
              else if (typ < 22) then
                stype := S_MEDPAK2
              else if (typ < 30) then
                stype := S_MEDPAK3
              else if (typ < 45) then
                stype := S_MEDPAK4
              else if (typ < 60) then
                stype := S_SHIELD4
              else if (typ < 67) then
                stype := S_SHIELD3
              else if (typ < 75) then
                stype := S_SHIELD2
              else if (typ < 90) then
                stype := S_SHIELD1
              else if (typ < 96) and DEMO then
                stype := S_IGRENADE
              else if (typ < 98) and DEMO then
                stype := S_IREVERSO
              else if (typ < 102) and DEMO then
                stype := S_IPROXMINE
              else if (typ < 106) and DEMO then
                stype := S_ITIMEMINE
              else if (typ < 108) and DEMO then
                stype := S_IDECOY
              else if (typ < 96) and not DEMO then
                stype := S_IGRENADE
              else if (typ < 98) and not DEMO then
                stype := S_IREVERSO
              else if (typ < 102) and not DEMO then
                stype := S_IPROXMINE
              else if (typ < 106) and not DEMO then
                stype := S_ITIMEMINE
              else if (typ < 108) and not DEMO then
                stype := S_IDECOY
              else if (typ < 110) and not DEMO then
                stype := S_IINSTAWALL
              else if (typ < 110) and not DEMO then
                stype := S_IINVIS
              else if (typ < 112) and not DEMO then
                stype := S_IJAMMER
              else if (typ < 114) and not DEMO then
                stype := S_ISTEALER
              else if DEMO then
                stype := S_IINSTAWALL
              else
                stype := S_IHOLO;
              sa.time := timecount + (clock and 255) + (9 - greedcom.numplayers) * 437;
            end;
          end;

        10:
          begin
            stype := S_MONSTER1;
            sa.time := timecount + (clock and 255) + (2100 * (player.difficulty + 1));
          end;

        11:
          begin
            stype := S_MONSTER2;
            sa.time := timecount + (clock and 255) + (4200 * (player.difficulty+ 1));
          end;

        12:
          begin
            stype := S_MONSTER3;
            sa.time := timecount + (clock and 255) + (2100 * (player.difficulty + 1));
          end;

        13:
          begin
            stype := S_MONSTER4;
            sa.time := timecount + (clock and 255) + (10500 * (player.difficulty + 1));
          end;

        14:
          begin
            stype := S_MONSTER5;
            sa.time := timecount + (clock and 255) + (4200 * (player.difficulty + 1));
          end;

        15:
          begin
            stype := S_MONSTER6;
            sa.time := timecount + (clock and 255) + (4200 * (player.difficulty + 1));
          end;

        16:
          begin
            stype := S_MONSTER7;
            sa.time := timecount + (clock and 255) + (4200 * (player.difficulty + 1));
          end;

        17:
          begin
            stype := S_MONSTER8;
            sa.time := timecount + (clock and 255) + (4200 * (player.difficulty + 1));
          end;

        18:
          begin
            stype := S_MONSTER9;
            sa.time := timecount + (clock and 255) + (4200 * (player.difficulty + 1));
          end;

        19:
          begin
            stype := S_MONSTER10;
            sa.time := timecount + (clock and 255) + (1200 * (player.difficulty + 1));
          end;

        20:
          begin
            stype := S_MONSTER11;
            sa.time := timecount + (clock and 255) + (4200 * (player.difficulty + 1));
          end;

        21:
          begin
            stype := S_MONSTER12;
            sa.time := timecount + (clock and 255) + (4200 * (player.difficulty + 1));
          end;

        22:
          begin
            stype := S_MONSTER13;
            sa.time := timecount + (clock and 255) + (4200 * (player.difficulty + 1));
          end;

        23:
          begin
            stype := S_MONSTER14;
            sa.time := timecount + (clock and 255) + (4200 * (player.difficulty + 1));
          end;

        24:
          begin
            stype := S_MONSTER15;
            sa.time := timecount + (clock and 255) + (4200 * (player.difficulty + 1));
          end;

        100:
          begin
            stype := S_MONSTER8_NS;
            sa.time := timecount + (clock and 255) + (4200 * (player.difficulty + 1));
          end;

        101:
          begin
            stype := S_MONSTER9_NS;
            sa.time := timecount + (clock and 255) + (4200 * (player.difficulty + 1));
          end;
        end;

        if sa.typ >= 10 then
        begin
          count := 0;
          sprite_p := firstscaleobj.next;
          while sprite_p <> @lastscaleobj do
          begin
            if (sprite_p.typ = stype) and (sprite_p.hitpoints <> 0) then
              inc(count);
            sprite_p := sprite_p.next;
          end;
        end
        else
          count := 0;

        if count < MAXSPAWN then
        begin
          sprite_p := firstscaleobj.next;
          while sprite_p <> @lastscaleobj do
          begin
            if ((sprite_p.typ = S_GENERATOR) or ((sprite_p.typ >= S_GENSTART) and (sprite_p.typ <= S_GENEND))) and
               (sprite_p.x = sa.mapx) and (sprite_p.y = sa.mapy) then
            begin
              sprite_p := sprite_p.prev;
              RF_RemoveSprite(sprite_p.next);
            end;
            sprite_p := sprite_p.next;
          end;

          if sa.typ >= 10 then
          begin
            sprite_p := firstscaleobj.next;
            while sprite_p <> @lastscaleobj do
            begin
            if (sprite_p.typ = stype) and (sprite_p.hitpoints = 0) then
              begin
                RF_RemoveSprite(sprite_p);
                break;
              end;
              sprite_p := sprite_p.next;
            end;
          end;

          if not netmode or (netmode and (playernum = 0)) then
          begin
            SpawnSprite(stype, sa.mapx, sa.mapy, 0, 0, 0, 0, true, 0);
            SpawnSprite(S_WARP, sa.mapx, sa.mapy, 0, 0, 0, 0, true, 0);
            if netmode and (sa.typ >= 10) then
              NetSendSpawn(stype,sa.mapx,sa.mapy, 0, 0, 0, 0, true, 0);
          end;

        end;
      end;
    end
    else
      sa.time := timecount + (clock and 255) + 7000;
  end;
end;


procedure CheckBonusItem;
var
  sprite: Pscaleobj_t;
begin
  if timecount > BonusItem.time then
  begin
    if netmode and (playernum <> 0) then
      exit; // player 0 spawns the bonuses

    if BonusItem.score > 0 then
    begin
      sprite := firstscaleobj.next;
      while sprite <> @lastscaleobj do
      begin
        if sprite.typ = S_BONUSITEM then
        begin
          RF_RemoveSprite(sprite);
          mapsprites[BonusItem.mapspot] := 0;
          break;
        end;
        sprite := sprite.next;
      end;

      SpawnSprite(S_WARP,
        (BonusItem.tilex * MAPSIZE + 32) * FRACUNIT,
        (BonusItem.tiley * MAPSIZE + 32) * FRACUNIT,
        0, 0, 0, 0, false, 0);
    end;

    repeat
      BonusItem.tilex := (clock + MS_RndT) and 63;
      BonusItem.tiley := (clock + MS_RndT) and 63;
      BonusItem.mapspot := BonusItem.tiley * MAPCOLS + BonusItem.tilex;
    until (floorpic[BonusItem.mapspot] <> 0) and
          (mapsprites[BonusItem.mapspot] = 0) and
          (mapeffects[BonusItem.mapspot] and FL_FLOOR = 0) and
          (floorheight[BonusItem.mapspot] <> ceilingheight[BonusItem.mapspot]);

    BonusItem.score := 2000 + (clock and 7) * 300;
    BonusItem.time := timecount + bonustime + (clock and 1023);
    BonusItem.num := clock mod MAXRANDOMITEMS;
    BonusItem.name := randnames[BonusItem.num];
    BonusItem.sprite := SpawnSprite(S_BONUSITEM, (BonusItem.tilex * MAPSIZE + 32) * FRACUNIT,(BonusItem.tiley * MAPSIZE + 32) * FRACUNIT, 0, 0, 0, 0, false, 0);
    SpawnSprite(S_WARP, (BonusItem.tilex * MAPSIZE + 32) * FRACUNIT, (BonusItem.tiley * MAPSIZE + 32) * FRACUNIT, 0, 0, 0, 0, false, 0);
    BonusItem.sprite.basepic := BonusItem.sprite.basepic + BonusItem.num;
    oldgoalitem := -1;
    if netmode then
      NetBonusItem;
    goalitem := 0;
  end;
end;


procedure TimeUpdate;
var
  time: integer;
begin
  I_PeekAndDisplatch;
  I_Sleep(0);

  chargeweapons;
  UpdateMouse;
  if netmode then
    NetGetData;
  if netmode then
  begin
    NetGetData;
    if timecount > netsendtime then
    begin
      if player.angst <> 0 then
        NetSendPlayerData;
      netsendtime := timecount + 3 + greedcom.numplayers;
    end;
    NetGetData;
  end;
  time := timecount;
  UpdateSound;
  while time >= spritemovetime do
  begin
    if netmode then
      NetGetData;
    if numprocesses <> 0 then
    begin
      Process;
      if netmode then
        NetGetData;
    end;

//   if (recording) or (playback) rndofs := 0;

    memset(@reallight, 0, MAPROWS * MAPCOLS * SizeOf(integer));
    MoveSprites;

    if netmode then
    begin
      NetGetData;
      spritemovetime := spritemovetime + 2;
    end;

    spritemovetime := spritemovetime + 8;
  end;
  UpdateMouse;
  if netmode then
    NetGetData;
  if numspawnareas <> 0 then
    CheckSpawnAreas;
  if netmode then
    NetGetData;
  CheckElevators;
  if netmode then
    NetGetData;
  CheckBonusItem;
  if netmode then
    NetGetData;
  if doorsound then
  begin
    doorsound := false;
    SoundEffect(SN_DOOR, 15, doorx, doory);
  end;
  if netmode then
    NetGetData;
  UpdateMouse;
end;


procedure RearView;
var
  scrollmin1, scrollmax1, view: integer;
  location: pointer;
begin
  view := currentViewSize * 2;
  location := viewLocation;
  windowWidth := 64;
  windowHeight := 64;
  windowLeft := 0;
  windowTop := 0;
  windowSize := windowWidth * windowHeight;
  viewLocation := screen;
  scrollmin1 := player.scrollmin;
  scrollmax1 := player.scrollmax;
  SetViewSize(windowWidth, windowHeight, @viewbuffer);
  ResetScalePostWidth(windowWidth);
  scrollmin := 0;
  scrollmax := 64;
  memcpy(@pixelangle, @campixelangle, SizeOf(pixelangle));
  memcpy(@pixelcosine, @campixelcosine, SizeOf(pixelcosine));
  if (enemyviewmode <> 0) and (goalitem > 0) then
    RF_RenderView(playerdata[goalitem - 1].x, playerdata[goalitem - 1].y, playerdata[goalitem - 1].z, playerdata[goalitem - 1].angle)
  else
    RF_RenderView(player.x, player.y, player.z, player.angle + WEST);
  memcpy(@rearbuf, @viewbuffer, SizeOf(rearbuf));
  I_TranslateBuffer(@rearbuf, SizeOf(rearbuf));
  windowLeft := viewLoc[view];
  windowTop := viewLoc[view + 1];
  viewLocation := location;
  SetViewSize(viewSizes[view], viewSizes[view + 1], @renderbuffer);
  ResetScalePostWidth(windowWidth);
  memcpy(@pixelangle, @wallpixelangle, SizeOf(pixelangle));
  memcpy(@pixelcosine, @wallpixelcosine, SizeOf(pixelcosine));
  player.scrollmin := scrollmin1;
  player.scrollmax := scrollmax1;
end;


procedure NewGoalItem;
begin
  togglegoalitem := false;
  inc(goalitem);

  if not netmode then
  begin
    if (goalitem = 0) and (BonusItem.score = 0) then
      inc(goalitem);
    while (goalitem >= 1) and (goalitem <= 2) and (primaries[(goalitem - 1) * 2] = -1) do
      inc(goalitem);
    while (goalitem >= 3) and (goalitem <= 9) and (secondaries[(goalitem - 3) * 2] = -1) do
      inc(goalitem);
    if goalitem >= 10 then
    begin
      goalitem := 0;
      if (goalitem = 0) and (BonusItem.score = 0) then
        inc(goalitem);
      while (goalitem >= 1) and (goalitem <= 2) and (primaries[(goalitem - 1) * 2] = -1) do
        inc(goalitem);
      while (goalitem >= 3) and (goalitem <= 9) and (secondaries[(goalitem - 3) * 2] = -1) do
        inc(goalitem);
      if goalitem = 10 then
        goalitem := -1;
    end;
  end
  else
  begin
    if (goalitem = 0) and (BonusItem.score = 0) then
      inc(goalitem);
    if goalitem > greedcom.numplayers then
    begin
      goalitem := 0;
      if (goalitem = 0) and (BonusItem.score = 0) then
        inc(goalitem);
      if goalitem > greedcom.numplayers then
        goalitem := -1;
    end;
  end;
end;


procedure startover(const restartvalue: integer);
var
  i: integer;
begin
  if netmode then
    NetGetData;
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
      memset(@player.inventory, 0, SizeOf(player.inventory));
      player.inventory[7] := 2;
      player.inventory[5] := 2;
      player.inventory[4] := 2;
      player.inventory[2] := 4;
    end
    else
    begin
      if player.inventory[7] < 2 then
        player.inventory[7] := 2;
      if player.inventory[5] < 2 then
        player.inventory[5] := 2;
      if player.inventory[4] < 2 then
        player.inventory[4] := 2;
      if player.inventory[2] < 4 then
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
    newmap(player.map, restartvalue);
    INT_TimerHook(PlayerCommand);
  end
  else
    respawnplayer;

  if netmode then
    NetGetData;

  exitexists := false;
  specialeffecttime := 0;
  ExitLevel := false;
  if netmode then
    NetGetData;
  turnrate := 0;
  moverate := 0;
  fallrate := 0;
  strafrate := 0;
  deadrestart := false;
  player.primaries[0] := 0;
  player.primaries[1] := 0;
  for i := 0 to 6 do
    player.secondaries[i] := 0;
end;


procedure EndLevel;
begin
  VI_FadeOut(0, 256, 0, 0, 0,64);
  memset(screen, 0, 64000);
  I_SetPalette(CA_CachePalette(CA_GetNamedNum('palette')));
  inc(player.map);
  startover(1);
end;


procedure WarpAnim;
begin
  if Warping = 1 then
  begin
    CA_ReadLump(CA_GetNamedNum('WARPLIGHTS'), colormaps);
    Warping := 2;
  end
  else if Warping = 2 then
  begin
    if lighting >= 128 then
      changelight := -128
    else
    begin
      Warping := 3;
      player.x := WarpX;
      player.y := WarpY;
    end;
  end
  else if Warping = 3 then
  begin
    if lighting < SC.ambientlight then
      changelight := 128
    else
    begin
      CA_ReadLump(CA_GetNamedNum('LIGHTS'), colormaps);
      Warping := 0;
    end;
  end;
end;


procedure DrawHolo;
var
  i, j, count, bottom, top, x, y: integer;
  collumn: PByteArray;
  spic: Pscalepic_t;
begin
  spic := lumpmain[player.holopic]; // draw the pic for it
  x := 5;
  for i := 0 to spic.width - 1 do
  begin
    if spic.collumnofs[i] <> 0 then
    begin
      collumn := @PByteArray(spic)[spic.collumnofs[i]];
      top := collumn[1];
      bottom := collumn[0];
      count := bottom - top + 1;
      collumn := @collumn[2];
      y := windowHeight - top - count - 5;
      for j := 0 to count - 1 do
      begin
        if (y >= 0) and (collumn[0] <> 0) then
          viewylookup[y][x] := collumn[0];
        collumn := @collumn[1];
        inc(y);
      end;
    end;
    inc(x);
  end;
end;


procedure RunMenu;
begin
  player.timecount := timecount;
  ShowMenu(0);
  if not netmode then
    timecount := player.timecount;
  activatemenu := false;
  INT_TimerHook(PlayerCommand);
  keyboardDelay := timecount + KBDELAY;
end;


procedure RunHelp;
begin
  player.timecount := timecount;
  INT_TimerHook(nil);
  ShowHelp;
  INT_TimerHook(PlayerCommand);
  activatehelp := false;
  timecount := player.timecount;
  keyboardDelay := timecount + KBDELAY;
end;


procedure RunQuickExit;
begin
  QuickExit := false;
  MouseShow;
  if ShowQuit(PlayerCommand) then
    quitgame := true;
  MouseHide;
  keyboardDelay := timecount + KBDELAY;
end;


procedure RunPause;
begin
  if paused then
  begin
    gamepause := true;
    if netmode then
      NetPause;
  end;
  player.timecount := timecount;
  ShowPause;
  timecount := player.timecount;
  if paused and netmode then
    NetUnPause;
  paused := false;
  gamepause := false;
  INT_TimerHook(PlayerCommand);
  keyboardDelay := timecount + KBDELAY;
end;


procedure PrepareNexus;
var
  i, j, mapspot, x, y: integer;
begin
  i := -MAPCOLS;
  while i <= MAPCOLS do
  begin
    for j := -1 to 1 do
    begin
      mapspot := player.mapspot + i + j;
      if (mapspot <> player.mapspot) and (floorpic[mapspot] and mapsprites[mapspot] = 0) then
      begin
        x := ((player.mapspot + i + j) and 63) * MAPSIZE + 32;
        y := ((player.mapspot + i + j) div 64) * MAPSIZE + 32;
        SpawnSprite(S_EXIT, x * FRACUNIT, y * FRACUNIT, 0, 0, 0, 0, false, 0);
        SoundEffect(SN_NEXUS, 0, x * FRACUNIT, y * FRACUNIT);
        SoundEffect(SN_NEXUS, 0, x * FRACUNIT, y * FRACUNIT);
        exitexists := true;
        writemsg('Translation Nexus Created!');
        exit;
      end;
    end;
    i := i + MAPCOLS;
  end;
end;


procedure RunBrief;
begin
  memcpy(@viewbuffer, screen, 64000);
  MissionBriefing(player.map);
  INT_TimerHook(PlayerCommand);
  memcpy(screen, @viewbuffer, 64000);
  activatebrief := false;
end;


procedure JamWarps;
var
  sp, t: Pscaleobj_t;
  mapspot, i: integer;
  sa: Pspawnarea_t;
begin
  if specialeffect <> SE_WARPJAMMER then
  begin
    specialeffect := SE_WARPJAMMER;
    specialeffecttime := timecount + TICRATE * 60;
    totaleffecttime := TICRATE * 60;
    dec(player.inventory[11]);

    sp := firstscaleobj.next;
    while sp <> @lastscaleobj do
    begin
      if (sp.typ = S_GENERATOR) or ((sp.typ >= S_GENSTART) and (sp.typ <= S_GENEND)) then
      begin
        mapspot := (sp.y div FRACTILEUNIT) * MAPCOLS + (sp.x div FRACTILEUNIT);
        mapsprites[mapspot] := 0;
        t := sp;
        sp := sp.next;
        RF_RemoveSprite(t);
      end
      else
        sp := sp.next;
    end;

    for i := 0 to numspawnareas - 1 do
      spawnareas[i].time := timecount;

    writemsg('Used Warp Jammer');
  end;
  warpjammer := false;
end;


procedure SelectNewSong;
begin
  inc(songnum);
  songnum := songnum mod 32;
  selectsong(songnum);
  newsong := false;
end;

var
  wpic: Ppic_t;
  weapbob1, wx, wy: integer;

procedure UpdateView(const px, py, pz: fixed_t; const aangle: integer; const update: integer);
var
  weaponx, weapony, i, x: integer;
  pic: Ppic_t;
  dbg: string;
  angle: integer;
  rtop: integer;
begin
  angle := aangle and ANGLES;

  if update <> 0 then
  begin
    weapbob1 := weapbob;
    rtimecount := timecount;
  end;

  SetViewSize(RENDER_VIEW_WIDTH, RENDER_VIEW_HEIGHT, @renderbuffer);
  RF_RenderView(px, py, pz, angle);
  SetViewSize(MAX_VIEW_WIDTH, MAX_VIEW_HEIGHT, @viewbuffer);

  if update = 1 then
    TimeUpdate;

  if player.holopic <> 0 then
    DrawHolo;

  if netmode then
    NetGetData;

  if timecount < RearViewTime then
  begin
    x := windowWidth - 65;
    if currentViewSize >= 4 then
      rtop := 10
    else
      rtop := 0;
    for i := 0 to 63 do
    begin
      memcpy(@ylookup[rtop + i + 1][x], @rearbuf[i * 64], 64);
      ylookup[rtop + i + 1][x - 1] := 30;
      ylookup[rtop + i + 1][x + 64] := 30;
    end;
    memset(@ylookup[rtop + 64][x - 1], 30, 66);
    memset(@ylookup[rtop + 1][x - 1], 30, 66);
  end;

  // update sprite movement
  if update = 1 then
    TimeUpdate;

  // draw the weapon pic

  if player.angst <> 0 then // only if alive
  begin
    if update <> 0 then
      wpic := weaponpic[weapmode];

    weaponx := ((windowWidth - wpic.width) div 2) + (weapmove[weapbob1] div 2);
    weapony := windowHeight - wpic.height + (weapmove[weapbob1 div 2] div 8);

    if changingweapons and weaponlowering then
    begin
      weaponychange := weaponychange + 15;
      weapony := weapony + weaponychange;
      if weapony >= windowHeight - 20 then
      begin
        weaponlowering := false;
        player.currentweapon := newweapon;
        loadweapon(player.weapons[newweapon]);
        weapmode := 0;
        wpic := weaponpic[weapmode];
        weaponychange := weaponpic[weapmode].height - 20;
        weapony := windowHeight - 21;
        weaponx := ((windowWidth - wpic.width) div 2) + (weapmove[weapbob1] div 2);
      end
    end
    else if changingweapons then
    begin
      weaponychange := weaponychange - 10;
      if weaponychange <= 0 then
        changingweapons := false
      else
        weapony := weapony + weaponychange;
    end;

    if update <> 0 then
    begin
      wx := weaponx;
      wy := weapony;
    end
    else
    begin
      weaponx := wx;
      weapony := wy;
    end;

    if netmode then
      NetGetData;

    if weapmode = 0 then
      VI_DrawMaskedPicToBuffer2(weaponx, weapony, wpic)
    else
      VI_DrawMaskedPicToBuffer(weaponx, weapony, wpic);
  end;

  // update sprite movement
  if update = 1 then
    TimeUpdate;

  // update displays

  if mapmode = 1 then
    displaymapmode
  else if mapmode = 2 then
    displayswingmapmode
  else if mapmode <> 0 then
    MS_Error('PlayLoop(): mapmode = %d', [mapmode]);

  if heatmode then
  begin
    if mapmode <> 0 then
      displayheatmapmode
    else
      displayheatmode;
  end;

  if motionmode then
  begin
    if mapmode <> 0 then
      displaymotionmapmode
    else
      displaymotionmode;
  end;

  if netmode then
    NetGetData;

  if (currentViewSize > 0) and (currentViewSize < MAXVIEWSIZE) then
  begin
    if currentViewSize = 4 then
      pic := statusbar[2]
    else
      pic := statusbar[currentViewSize - 1];
    VI_DrawMaskedPicToBuffer(statusbarloc[currentViewSize * 2], statusbarloc[currentViewSize * 2 + 1], pic);
    if currentViewSize = 4 then
      VI_DrawMaskedPic(0, 0, statusbar[3]);
  end;

  if netmode then
    NetGetData;

  updatedisplay;

  if netmode then
    NetGetData;

  // display the message string
  rewritemsg;

  // finally draw it

  if netmode then
    NetGetData;

  if ticker then
  begin
    sprintf(dbg, 'sp:%4d tp:%4d ver:%4d e:%4d mu:%2d t:%3d:%2d',
      [numspans, transparentposts, pDiff(vertexlist_p, @vertexlist, SizeOf(vertex_t)), pDiff(entry_p, @entries, SizeOf(entry_t)), greedcom.maxusage, timecount div (60 * TICRATE), (timecount div TICRATE) mod 60]);
    // sprintf(dbg, 'x: %d  y: %d', [(player.x div FRACUNIT) and 63, (player.y div FRACUNIT) and 63]);
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
    sprintf(dbg, 'Message: %s', [netmsg]);
    FN_RawPrint2(dbg);
  end
  else if netmsgstatus = 2 then
  begin
    NetSendMessage(netmsg);
    netmsgstatus := 0;
  end;

  // update sprite movement
  if update = 1 then
    TimeUpdate;
end;

procedure PlayLoop;
var
  i: integer;
begin
  if netmode then
    NetWaitStart
  else
    timecount := 0;

  while not quitgame do
  begin
    if fliplayed <> 0 then
    begin
      needsblit := true;
      if deadrestart then
      begin
        memset(screen, 0, 64000);

        I_SetPalette(CA_CachePalette(CA_GetNamedNum('palette')));

        startover(2);
      end;
      continue;
    end;

    needsblit := false;

    if netmode then
      NetGetData;

    if toggleautorun then
    begin
      autorun := not autorun;
      if autorun then
        writemsg('Auto-Run On')
      else
        writemsg('Auto-Run Off');
      toggleautorun := false;
    end;

    if toggleautotarget then
    begin
      autotarget := not autotarget;
      if autotarget then
        writemsg('Auto-Target On')
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
      CheckHere(true, player.x, player.y, player.angle);
      if fliplayed <> 0 then
      begin
        needsblit := true;
        continue;
      end;
    end;

    if warpjammer then
      JamWarps;

    if netmode then
      NetGetData;

    if falldamage <> 0 then
    begin // just makes a grunt sound
      SoundEffect(SN_HIT0 + player.chartype, 15, player.x, player.y);
      if netmode then
        NetSoundEffect(SN_HIT0 + player.chartype, 15, player.x, player.y);
      falldamage := 0;
    end;

    if (player.levelscore = 0) and not exitexists and not netmode and
      (((primaries[0] <> -1) and (player.primaries[0] = pcount[0])) or (primaries[0] = -1)) and
      (((primaries[2] <> -1) and (player.primaries[1] = pcount[1])) or (primaries[2] = -1)) then
      PrepareNexus;

    if ExitLevel then
    begin
      EndLevel;
      if DEMO then
      begin
        if player.map >= 3 then
        begin
          quitgame := true;
          exit;
        end;
      end
      else if GAME1 then
      begin
        if player.map >= 8 then
        begin
          quitgame := true;
          exit;
        end;
      end
      else if GAME2 then
      begin
        if player.map >= 16 then
        begin
          quitgame := true;
          exit;
        end;
      end
      else
      begin
        if player.map >= 22 then
        begin
          quitgame := true;
          exit;
        end;
      end;
    end;

    if netmode then
      NetGetData;

    if timecount > specialeffecttime then
    begin
      specialeffect := 0;
      specialeffecttime := $7FFFFFFF;
    end;

    if firegrenade then
    begin
      SpawnSprite(S_GRENADE, player.x, player.y, player.z, player.height - (50 * FRACUNIT), player.angle, (-player.scrollmin) and ANGLES, true, playernum);
      SoundEffect(SN_GRENADE, 0, player.x, player.y);
      if netmode then
        NetSoundEffect(SN_GRENADE, 0, player.x, player.y);
      dec(player.inventory[2]);
      firegrenade := false;
    end;

    if netmode then
      NetGetData;

    if Warping <> 0 then
      WarpAnim;

    if netmode then
      NetGetData;

    // check special code flag
    Special_Code;

    // update sprite movement
    TimeUpdate;

    // update wallanimation
    if timecount >= wallanimationtime then
    begin
      inc(wallanimcount);
      case wallanimcount mod 3 of
      0:
        begin
          flattranslation[57] := 58;
          flattranslation[58] := 59;
          flattranslation[59] := 57;
          flattranslation[217] := 218;
          flattranslation[218] := 219;
          flattranslation[219] := 217;
          walltranslation[228] := 229;
          walltranslation[229] := 230;
          walltranslation[230] := 228;
        end;

      1:
        begin
          flattranslation[57] := 59;
          flattranslation[58] := 57;
          flattranslation[59] := 58;
          flattranslation[217] := 219;
          flattranslation[218] := 217;
          flattranslation[219] := 218;
          walltranslation[228] := 230;
          walltranslation[229] := 228;
          walltranslation[230] := 229;
        end;

      2:
        begin
          flattranslation[57] := 57;
          flattranslation[58] := 58;
          flattranslation[59] := 59;
          flattranslation[217] := 217;
          flattranslation[218] := 218;
          flattranslation[219] := 219;
          walltranslation[228] := 228;
          walltranslation[229] := 229;
          walltranslation[230] := 230;
        end;
      end;
      wallanimationtime := timecount + 12;
      if netmode then
        NetGetData;
      if (floorflags[player.mapspot] and F_DAMAGE <> 0) and (player.z = RF_GetFloorZ(player.x, player.y) + player.height) then
        hurt(30);
    end;

    CheckWarps(player.x, player.y);
    if fliplayed <> 0 then
    begin
      needsblit := true;
      continue;
    end;

    needsblit := false;

    CheckDoors(player.x, player.y);
    if netmode then
      NetGetData;
    if deadrestart then
      startover(2);
    if resizeScreen then
      ChangeViewSize(biggerScreen);
    if netmode then
      NetGetData;
    if scrollview <> 0 then
      ChangeScroll;

    // update sprite movement *)
    TimeUpdate;

    // check display toggle flags
    if toggleheatmode then
    begin
      if heatmode then
        heatmode := false
      else
      begin
        heatmode := true;
        if mapmode = 2 then
          mapmode := 1;
      end;
      toggleheatmode := false;
    end;

    if togglemotionmode then
    begin
      if motionmode then
        motionmode := false
      else
      begin
        motionmode := true;
        if mapmode = 2 then
          mapmode := 1;
      end;
      togglemotionmode := false;
    end;

    if togglemapmode then
    begin
      case mapmode of
      0:
        begin
          mapmode := 1;
        end;

      1:
        begin
          if heatmode or motionmode then
            mapmode := 0
          else
            mapmode := 2;
        end;

      2:
        begin
          mapmode := 0;
        end;
      end;

      togglemapmode := false;
    end;

    if togglegoalitem then
      NewGoalItem;

    if ToggleRearView then
    begin
      RearViewOn := not RearViewOn;
      ToggleRearView := false;
      RearViewDelay := timecount;
    end;

    if netmode then
      NetGetData;

    // render the view
    if RearViewOn and (timecount >= RearViewDelay) then
    begin
      RearViewTime := timecount + 2 * TICRATE;
      RearView;
      RearViewDelay := timecount + SC.camdelay;
      if SC.camdelay = TICRATE then
        RearViewOn := false;
    end;

    if netmode then
      NetGetData;

    scrollmin := player.scrollmin;
    scrollmax := player.scrollmax;

    UpdateView(player.x, player.y, player.z, player.angle, 1);

    if newsong then
      SelectNewSong;

    if activatemenu then
    begin
      needsblit := true;
      RunMenu;
    end;

    if activatehelp then
    begin
      needsblit := true;
      RunHelp;
    end;

    if activatebrief then
    begin
      needsblit := true;
      RunBrief;
    end;

    TimeUpdate;

    if QuickExit then
      RunQuickExit;

    if netmode then
      NetGetData;

    if paused or netpaused then
    begin
      needsblit := true;
      RunPause;
    end;

    inc(frames);

    // update sprite movement
    TimeUpdate;

    // update lights if necessary
    if changelight <> 0 then
      newlights;

    // update weapon to be displayed
    while (weapmode <> 0) and (timecount >= weapdelay) do
    begin
      if (player.weapons[player.currentweapon] = 4) or (player.weapons[player.currentweapon] = 18) then
      begin
        if weapmode = 1 then
        begin
          if player.weapons[player.currentweapon] = 4 then
          begin
            SoundEffect(SN_BULLET4, 0, player.x, player.y);
            if netmode then
              NetSoundEffect(SN_BULLET4, 0, player.x, player.y);
          end;
          if player.weapons[player.currentweapon] = 18 then
          begin
            SoundEffect(SN_BULLET18, 0, player.x, player.y);
            if netmode then
              NetSoundEffect(SN_BULLET18, 0, player.x, player.y);
          end;
        end;
        weapmode := weaponstate[player.weapons[player.currentweapon]][weapmode];
        if weapmode = 0 then
          fireweapon;
      end
      else
        weapmode := weaponstate[player.weapons[player.currentweapon]][weapmode];
      weapdelay := timecount + 8;
    end;

    if netmode then
      NetGetData;

    I_FinishUpdate;
    needsblit := true;
  end;
end;


procedure InitData;
var
  i: integer;
begin
  quitgame := false;
  mapmode := 0;
  heatmode := false;
  motionmode := false;
  turnrate := 0;
  moverate := 0;
  fallrate := 0;
  strafrate := 0;
  MapZoom := 8;
  secretbuf := '';
  if playback then
  begin
    demobuffer := CA_LoadFile('demo1');
    recordindex := 0;
  end;
  if recording then
  begin
    demobuffer := CA_CacheLump(CA_GetNamedNum('demo'));
    memset(demobuffer, 0, RECBUFSIZE);
    recordindex := 0;
  end;
  probe.moveSpeed := MAXPROBE;
  probe.movesize := 16 * FRACUNIT; // half a tile
  probe.spawnid := playernum;
  currentViewSize := sc.screensize;
  resetdisplay;
end;


procedure SaveDemo;
var
  f: file;
begin
  fopen(f, 'demo1', fOpenReadWrite);
  fwrite(demobuffer, RECBUFSIZE, 1, f);
  fclose(f);
end;


procedure maingame;
begin
  I_SetPalette(CA_CachePalette(CA_GetNamedNum('palette')));
  InitData;
  INT_TimerHook(PlayerCommand);   // the players actions are sampled by an interrupt
  newlights;
  PlayLoop;
  player.timecount := timecount;
  if netmode then
    NetQuitGame;
  if recording then
    SaveDemo;
  M_SaveDefaults;
  playback := false;
end;

end.


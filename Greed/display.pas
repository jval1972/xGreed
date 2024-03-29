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

unit display;

interface

uses
  d_video;

const
  primnames: array[0..21] of string[30] = (
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
    'Power Coupler'
   );

const
  secnames: array[0..40] of string[30] = (
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
  );

const
  ammonames: array[0..2] of string[6] = (
    'ENERGY',
    'BULLET',
    'PLASMA'
  );

const
  inventorynames: array[0..12] of string[14] = (
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
  );


var
  oldcharges: array[0..6] of byte;  // delta values (only changes if different)
  oldbodycount, oldscore, oldlevelscore: integer;
  oldshield, oldangst, oldshots, oldgoalitem, oldangle: integer;
  statcursor: integer = 269;
  inventorycursor: integer = -1;
  oldangstpic, oldinventory, totaleffecttime: integer;
  inventorylump, primarylump, secondarylump, fraglump: integer;
  heart: array[0..9] of Ppic_t;
  firegrenade: boolean;

procedure resetdisplay;

procedure updatedisplay;

procedure inventoryright;

procedure inventoryleft;

procedure useinventory;

procedure displaymapmode;

procedure displayswingmapmode;

procedure displayheatmapmode;

procedure displayheatmode;

procedure displaymotionmapmode;

procedure displaymotionmode;

implementation

uses
  g_delphi,
  constant,
  d_disk,
  d_font,
  d_ints,
  i_video,
  modplay,
  net,
  protos_h,
  raven,
  r_conten,
  r_public_h,
  r_public,
  r_refdef,
  r_render,
  r_walls,
  spawn,
  utils;

procedure resetdisplay;
var
  i: integer;
begin
  memset(@oldcharges, -1, 7);
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
    for i := 0 to MAXCHARTYPES - 1 do
      CA_CacheLump(fraglump + i);
  end;
end;


procedure inventoryright;
begin
  if inventorycursor = -1 then
    inventorycursor := 0
  else
    inc(inventorycursor);
  while (inventorycursor < MAXINVENTORY) and (player.inventory[inventorycursor] = 0) do
    inc(inventorycursor);
  if inventorycursor >= MAXINVENTORY then
  begin
    inventorycursor := 0;
    while (inventorycursor < MAXINVENTORY) and (player.inventory[inventorycursor] = 0) do
      inc(inventorycursor);
    if inventorycursor = MAXINVENTORY then
      inventorycursor := -1; // nothing found
   end;
end;


procedure inventoryleft;
begin
  dec(inventorycursor);
  while (inventorycursor >= 0) and (player.inventory[inventorycursor] = 0) do
    dec(inventorycursor);
  if inventorycursor <= -1 then
  begin
    inventorycursor := MAXINVENTORY - 1;
    while (inventorycursor >= 0) and (player.inventory[inventorycursor] = 0) do
      dec(inventorycursor);
  end;
end;


procedure useinventory;
var
  mindist, pic, x, y, dist, angle, angleinc, i, scale: integer;
  sp: Pscaleobj_t;
begin
  if (inventorycursor = -1) or (player.inventory[inventorycursor] = 0) then
    exit;

  case inventorycursor of
  0: // medtube
    begin
      if player.angst < player.maxangst then
      begin
        medpaks(50);
        dec(player.inventory[inventorycursor]);
        writemsg('Used Medtube');
      end;
    end;

  1: // shield
    begin
      if player.shield < player.maxshield then
      begin
        heal(50);
        dec(player.inventory[inventorycursor]);
        writemsg('Used Shield Charge');
      end;
    end;

  2: // grenade
    begin
      firegrenade := true;
    end;

  3: // reversopill
    begin
      if specialeffect <> SE_REVERSOPILL then
      begin
        specialeffect := SE_REVERSOPILL;
        specialeffecttime := timecount + TICRATE * 15;
        totaleffecttime := TICRATE * 15;
        dec(player.inventory[inventorycursor]);
        writemsg('Used Reverso Pill');
      end;
    end;

  4:
    begin
      SpawnSprite(S_PROXMINE, player.x, player.y, 0, 0, 0, 0, false, playernum);
      dec(player.inventory[inventorycursor]);
      writemsg('Dropped Proximity Mine');
    end;

  5:
    begin
      SpawnSprite(S_TIMEMINE, player.x, player.y, 0, 0, 0, 0, false, playernum);
      dec(player.inventory[inventorycursor]);
      writemsg('Dropped Time Bomb');
    end;

  6:
    begin
      SpawnSprite(S_DECOY, player.x, player.y, 0, 0, 0, 0, false, player.chartype);
      dec(player.inventory[inventorycursor]);
      writemsg('Activated Decoy');
    end;

  7:
    begin
      SpawnSprite(S_INSTAWALL, player.x, player.y, 0, 0, 0, 0, false, playernum);
      dec(player.inventory[inventorycursor]);
      writemsg('Activated InstaWall');
    end;

  8: // clone
    begin
      SpawnSprite(S_CLONE, player.x, player.y, 0, 0, 0, 0, false, player.chartype);
      dec(player.inventory[inventorycursor]);
      writemsg('Clone Activated');
    end;

  9: // holosuit
    begin
      mindist := $7FFFFFFF;
      pic := 0; // JVAL: Avoid compiler warning
      sp := firstscaleobj.next;
      while sp <> @lastscaleobj do
      begin
        if not sp.active and (sp.hitpoints = 0) then
        begin
          x := (player.x - sp.x) div FRACTILEUNIT;
          y := (player.y - sp.y) div FRACTILEUNIT;
          dist := x * x + y * y;
          if dist < mindist then
          begin
            pic := sp.basepic;
            scale := sp.scale;
            mindist := dist;
          end;
        end;
        sp := sp.next;
      end;
      if mindist <> $7FFFFFFF then
      begin
        dec(player.inventory[inventorycursor]);
        player.holopic := pic;
        player.holoscale := scale;
        writemsg('HoloSuit Active');
      end
      else
        writemsg('Unsuccessful Holo');
    end;
(*   10: // portable hole
    if mapsprites[player.mapspot] <> 0 then
    begin
      SpawnSprite(S_HOLE, player.x, player.y, 0, 0, 0, 0, false, player.chartype);
      dec(player.inventory[inventorycursor]);
      writemsg('Dropped Portable Hole');
       end;
    else
     writemsg('Portable Hole Blocked');
    break; *)
  10: // invisibility
    begin
      if specialeffect <> SE_INVISIBILITY then
      begin
        specialeffect := SE_INVISIBILITY;
        specialeffecttime := timecount + TICRATE * 30;
        totaleffecttime := TICRATE * 30;
        dec(player.inventory[inventorycursor]);
        writemsg('Activated Invisibility Shield');
      end;
    end;

  11: // warp jammer
    begin
      warpjammer := true;
    end;

  12: // soul stealer
    begin
      angleinc := ANGLES div 16;
      angle := 0;
      for i := 0 to 15 do
      begin
        SpawnSprite(S_SOULBULLET, player.x, player.y, player.z, player.height - (52 * FRACUNIT),angle, 0, true, playernum);
        angle := angle + angleinc;
      end;
      SoundEffect(SN_SOULSTEALER, 0, player.x, player.y);
      SoundEffect(SN_SOULSTEALER, 0, player.x, player.y);
      if netmode then
      begin
        NetSendSpawn(S_SOULBULLET, player.x, player.y, player.z, player.height - (52 * FRACUNIT),angle, 0, true, playernum);
        NetSoundEffect(SN_SOULSTEALER, 0, player.x, player.y);
        NetSoundEffect(SN_SOULSTEALER, 0, player.x, player.y);
      end;
      dec(player.inventory[inventorycursor]);
      writemsg('Used Soul Stealer');
    end;
  end;
  oldinventory := -2;
  inventoryleft;
  inventoryright;
end;


procedure displaystats1(const ofs: integer);
var
  d, i, j, c: integer;
  str1: string;
begin
  d := (player.shield * 28) div player.maxshield;
  for i := 152 + ofs to 159 + ofs do
  begin
    c := (d * (i - (152 + ofs))) div 8 + 140;
    for j := 272 to 300 do
      if ylookup[i][j] = 254 then
        ylookup[i][j] := c;
  end;
  for i := 193 + ofs to 199 + ofs do
  begin
    c := (d * ((199 + ofs) - i)) div 7 + 140;
    for j := 272 to 300 do
      if ylookup[i][j] = 254 then
        ylookup[i][j] := c;
  end;
  for j := 307 to 315 do
  begin
    c := (d * (315 - j)) div 9 + 140;
    for i := 165 + ofs to 187 + ofs do
      if ylookup[i][j] = 254 then
        ylookup[i][j] := c;
  end;
  for j := 257 to 265 do
  begin
    c := (d * (j - 257)) div 9 + 140;
    for i := 165 + ofs to 187 + ofs do
      if ylookup[i][j] = 254 then
        ylookup[i][j] := c;
  end;
  d := (player.angst * 10) div player.maxangst;
  if d >= 10 then
    d := 9;
  VI_DrawMaskedPicToBuffer(269, 161 + ofs, heart[d]);
  statcursor := 269 + timecount mod 54;
  for j := 269 to 305 do
  begin
    if j > statcursor then
      c := 113
    else
    begin
      c := 139 - (statcursor - j);
      if c < 120 then
        c := 113;
    end;
    for i := 161 + ofs to 185 + ofs do
      if ylookup[i][j] = 254 then
        ylookup[i][j] := c;
  end;
  font := font2;
  fontbasecolor := 0;
  sprintf(str1, '%3d', [player.angst]);
  printx := 280;
  printy := 188 + ofs;
  FN_RawPrint4(str1);
end;

type
  compassbackinfo_t = record
    line: integer;
    start, finish: integer;
  end;

const
  NUMCOMPASSBACK = 19;

const
  compassbackinfo: array[0..NUMCOMPASSBACK - 1] of compassbackinfo_t = (
    (line: 152; start: 234; finish: 240),
    (line: 153; start: 231; finish: 243),
    (line: 154; start: 230; finish: 244),
    (line: 155; start: 228; finish: 246),
    (line: 156; start: 228; finish: 246),
    (line: 157; start: 227; finish: 247),
    (line: 158; start: 227; finish: 247),
    (line: 159; start: 226; finish: 248),
    (line: 160; start: 226; finish: 248),
    (line: 161; start: 226; finish: 248),
    (line: 162; start: 226; finish: 248),
    (line: 163; start: 226; finish: 248),
    (line: 164; start: 227; finish: 247),
    (line: 165; start: 227; finish: 247),
    (line: 166; start: 228; finish: 246),
    (line: 167; start: 228; finish: 246),
    (line: 168; start: 230; finish: 244),
    (line: 169; start: 231; finish: 243),
    (line: 170; start: 234; finish: 240)
  );

procedure displaycompassback(const ofs: integer);
var
  c, x, y: integer;
  dest: PByteArray;
begin
  for c := 0 to NUMCOMPASSBACK - 1 do
  begin
    dest := @ylookup[compassbackinfo[c].line + ofs][0];
    for x := compassbackinfo[c].start to compassbackinfo[c].finish do
      if dest[x] = 0 then
        dest[x] := approx_zero;
  end;
end;

procedure displaycompass1(const ofs: integer);
var
  c, x, y, i: integer;
  x1, y1: fixed_t;
begin
  displaycompassback(ofs);
  x := 237;
  x1 := x * FRACUNIT;
  y := 161 + ofs;
  y1 := y * FRACUNIT;
  c := 139;
  for i := 0 to 9 do
  begin
    ylookup[y][x] := c;
    x1 := x1 + costable[player.angle];
    y1 := y1 - FIXEDMUL(sintable[player.angle], 54394);
    x := x1 div FRACUNIT;
    y := y1 div FRACUNIT;
    dec(c);
  end;
end;


procedure displaysettings1(const ofs: integer);
begin
  if heatmode then
    memset(@ylookup[199 + ofs][236], 102, 6)
  else
    memset(@ylookup[199 + ofs][236], approx_zero, 6);
  if motionmode then
    memset(@ylookup[199 + ofs][246], 156, 6)
  else
    memset(@ylookup[199 + ofs][246], approx_zero, 6);
  if mapmode <> 0 then
    memset(@ylookup[199 + ofs][226], 133, 6)
  else
    memset(@ylookup[199 + ofs][226], approx_zero, 6);
end;


procedure displayinventory1(const ofs: integer);
var
  n, ammo, lump, maxshots, i, j, count, top, bottom, x, y: integer;
  str1: string;
  pic: Pscalepic_t;
  collumn: PByteArray;
begin
  font := font2;
  fontbasecolor := 0;
  n := player.weapons[player.currentweapon];
  if weapons[n].ammorate > 0 then
  begin
    ammo := player.ammo[weapons[n].ammotype];
    maxshots := weapons[n].ammorate;
  end
  else
  begin
    ammo := 999;
    maxshots := 999;
  end;
  printx := 186;
  printy := 183 + ofs;
  sprintf(str1, '%3d', [ammo]);
  FN_RawPrint2(str1);
  printx := 203;
  printy := 183 + ofs;
  sprintf(str1, '%3d', [maxshots]);
  FN_RawPrint2(str1);
  printx := 187;
  printy := 191 + ofs;
  FN_RawPrint2(ammonames[weapons[n].ammotype]);

  if (inventorycursor = -1) or (player.inventory[inventorycursor] = 0) then
    inventoryright;
  if inventorycursor <> -1 then
  begin
    lump := inventorylump + inventorycursor;
    printx := 149;         // name
    printy := 163 + ofs;
    FN_RawPrint2(inventorynames[inventorycursor]);
    font := font3;         // number of items
    printx := 150;
    printy := 172 + ofs;
    sprintf(str1, '%2d', [player.inventory[inventorycursor]]);
    FN_RawPrint2(str1);
    pic := lumpcache[lump].data;  // draw the pic for it
    x := 128 - (pic.width div 2);
    for i := 0 to pic.width - 1 do
    begin
      if pic.collumnofs[i] <> 0 then
      begin
        collumn := PByteArray(pic);
        collumn := @collumn[pic.collumnofs[i]];
        top := collumn[1];
        bottom := collumn[0];
        count := bottom - top + 1;
        collumn := @collumn[2];
        y := (188 + ofs) - top - count;
        for j := 0 to count - 1 do
        begin
          if collumn[0] <> 0 then
            ylookup[y][x] := collumn[0];
          inc(y);
          collumn := @collumn[1];
        end;
      end;
      inc(x);
    end;
  end
  else
  begin
    printx := 149;   // name
    printy := 163 + ofs;
    str1 := '              ';
    FN_RawPrint2(str1);
    font := font3;   // number of items
    printx := 150;
    printy := 172 + ofs;
    FN_RawPrint2('  ');
  end;
end;


procedure displaynetbonusitem1(const ofs: integer);
var
  typ, name, str1: string;
  i, j, count, top, bottom, x, y, lump, score: integer;
  pic: Pscalepic_t;
  p: Ppic_t;
  collumn: PByteArray;
  b: PByte;
  time: integer;
begin
  font := font2;
  fontbasecolor := 0;
  if goalitem = -1 then
  begin
    if BonusItem.score <> 0 then
      togglegoalitem := true;
    exit;
  end;
  if goalitem = 0 then
  begin
    if BonusItem.score = 0 then  // bonus item go bye-bye
    begin
      togglegoalitem := true;
      exit;
    end;
    lump := BonusItem.sprite.basepic;
    score := BonusItem.score;
    typ := 'Bonus  ';
    time := (BonusItem.time - timecount) div TICRATE;
    if time > 10000 then
      time := 0;
    sprintf(str1, '%3d s ', [time]);
    name := BonusItem.name;
    pic := lumpcache[lump].data;
    x := 34 - (pic.width div 2);
    for i := 0 to pic.width - 1 do
    begin
      if pic.collumnofs[i] <> 0 then
      begin
        collumn := PByteArray(pic);
        collumn := @collumn[pic.collumnofs[i]];
        top := collumn[1];
        bottom := collumn[0];
        count := bottom - top + 1;
        collumn := @collumn[2];
        y := (188 + ofs) - top - count;
        for j := 0 to count - 1 do
        begin
          if collumn[0] <> 0 then
            ylookup[y][x] := collumn[0];
          inc(y);
          collumn := @collumn[1];
        end;
      end;
      inc(x);
    end;
  end
  else
  begin
    lump := fraglump + playerdata[goalitem - 1].chartype;
    p := lumpcache[lump].data;
    typ := 'Player ';
    name := netnames[goalitem - 1];
    sprintf(str1, '%5d', [fragcount[goalitem - 1]]);
    b := @p.data;
    for y := 0 to 29 do
      for x := 0 to 29 do
      begin
        ylookup[y + 158 + ofs][19 + x] := b^;
        inc(b);
      end;
  end;
  printx := 53;
  printy := 172 + ofs;
  FN_RawPrint2(str1);
  printx := 53;
  printy := 182 + ofs;
  FN_RawPrint2(typ);
  printx := 22;
  printy := 192 + ofs;
  str1 := name;
  while Length(str1) < 32 do
    str1 := ' ' + str1;
  FN_RawPrint2(str1);
end;


procedure displaybonusitem1(const ofs: integer);
var
  typ, name, str1: string;
  i, j, count, top, bottom, x, y, lump, score, found, total: integer;
  pic: Pscalepic_t;
  collumn: PByteArray;
  time: integer;
begin
  font := font2;
  fontbasecolor := 0;
  if goalitem = -1 then
  begin
    if BonusItem.score <> 0 then
      togglegoalitem := true;
    exit;
  end;
  if goalitem = 0 then
  begin
    if BonusItem.score = 0 then // bonus item go bye-bye
    begin
      togglegoalitem := true;
      exit;
    end;
    lump := BonusItem.sprite.basepic;
    score := BonusItem.score;
    typ := 'Bonus  ';
    time := (BonusItem.time - timecount) div TICRATE;
    if time > 10000 then
      time := 0;
    sprintf(str1, '%3d s', [time]);
    name := BonusItem.name;
  end
  else if (goalitem >= 1) and (goalitem <= 2) then
  begin
    lump := primarylump + primaries[(goalitem - 1) * 2];
    score := primaries[(goalitem - 1) * 2 + 1];
    typ := 'Primary';
    found := player.primaries[goalitem - 1];
    total := pcount[goalitem - 1];
    sprintf(str1, '%2d/%2d', [found, total]);
    name := primnames[primaries[(goalitem - 1) * 2]];
  end
  else if goalitem >= 3 then
  begin
    lump := secondarylump + secondaries[(goalitem - 3) * 2];
    score := secondaries[(goalitem - 3) * 2 + 1];
    typ := 'Second ';
    found := player.secondaries[goalitem - 3];
    total := scount[goalitem - 3];
    sprintf(str1, '%2d/%2d', [found, total]);
    name := secnames[secondaries[(goalitem - 3) * 2]];
  end;

  pic := lumpcache[lump].data;
  x := 34 - (pic.width div 2);
  for i := 0 to pic.width - 1 do
  begin
    if pic.collumnofs[i] <> 0 then
    begin
      collumn := PbyteArray(pic);
      collumn := @collumn[pic.collumnofs[i]];
      top := collumn[1];
      bottom := collumn[0];
      count := bottom - top + 1;
      collumn := @collumn[2];
      y := (188 + ofs) - top - count;
      for j := 0 to count - 1 do
      begin
        if collumn[0] <> 0 then
          ylookup[y][x] := collumn[0];
        inc(y);
        collumn := @collumn[1];
      end;
    end;
    inc(x);
  end;

  printx := 53;
  printy := 162 + ofs;
  FN_RawPrint2(str1);
  sprintf(str1, '%5d', [score]);
  printx := 53;
  printy := 172 + ofs;
  FN_RawPrint2(str1);
  printx := 53;
  printy := 182 + ofs;
  FN_RawPrint2(typ);
  printx := 22;
  printy := 192 + ofs;
  str1 := name;
  while Length(str1) < 32 do
    str1 := ' ' + str1;
  FN_RawPrint2(str1);
end;


procedure displayrightstats1(const ofs: integer);
var
  n, shots: integer;
  str1: string;
begin
  n := player.weapons[player.currentweapon];
  if weapons[n].ammorate > 0 then
    shots := player.ammo[weapons[n].ammotype] div weapons[n].ammorate
  else
    shots := 999;
  font := font3;
  printx := 225;
  printy := 178 + ofs;
  fontbasecolor := 0;
  sprintf(str1, '%3d', [shots]);
  FN_RawPrint2(str1);
  displaycompass1(ofs);
  displaysettings1(ofs);
  displaystats1(ofs);
end;


procedure displaystats2;
var
  d, i, j, c, p: integer;
  str1: string;
begin
  if player.shield <> oldshield then
  begin
    oldshield := player.shield;
    d := (player.shield * 28) div player.maxshield;
    for i := 152 to 159 do
    begin
      c := (d * (i - 152)) div 8 + 140;
      for j := 272 to 300 do
      begin
        p := ylookup[i][j];
        if (p = 254) or ((p >= 140) and (p <= 168)) then
          ylookup[i][j] := c;
      end;
    end;
    for i := 193 to 199 do
    begin
      c := (d * (199 - i)) div 7 + 140;
      for j := 272 to 300 do
      begin
        p := ylookup[i][j];
        if (p = 254) or ((p >= 140) and (p <= 168)) then
          ylookup[i][j] := c;
      end;
    end;
    for j := 307 to 315 do
    begin
      c := (d * (315 - j)) div 9 + 140;
      for i := 165 to 187 do
      begin
        p := ylookup[i][j];
        if (p = 254) or ((p >= 140) and (p <= 168)) then
          ylookup[i][j] := c;
      end;
    end;
    for j := 257 to 265 do
    begin
      c := (d * (j - 257)) div 9 + 140;
      for i := 165 to 187 do
      begin
        p := ylookup[i][j];
        if (p = 254) or ((p >= 140) and (p <= 168)) then
          ylookup[i][j] := c;
      end;
    end;
  end;
  if player.angst <> oldangst then
  begin
    d := (player.angst * 10) div player.maxangst;
    if d >= 10 then
      d := 9;
    if oldangstpic <> d then
    begin
      VI_DrawPicSolid(269, 161, heart[d]);
      oldangstpic := d;
    end;
    oldangst := player.angst;
    font := font2;
    fontbasecolor := 0;
    sprintf(str1, '%3d', [player.angst]);
    printx := 280;
    printy := 188;
    FN_RawPrint(str1);
  end;
  statcursor := 269 + timecount mod 54;
  for j := 269 to 305 do
  begin
    if j > statcursor then
      c := 113
    else
    begin
      c := 139 - (statcursor - j);
      if c < 120 then
        c := 113;
    end;
    for i := 161 to 185 do
    begin
      p := ylookup[i][j];
      if (p = 254) or ((p >= 113) and (p <= 139)) then
        ylookup[i][j] := c;
    end;
  end;
end;


procedure displaycompass2;
var
  c, x, y, i: integer;
  x1, y1: fixed_t;
begin
  displaycompassback(0);
  if oldangle <> -1 then
  begin
    x := 237;
    x1 := x * FRACUNIT;
    y := 161;
    y1 := y * FRACUNIT;
    for i := 0 to 9 do
    begin
      ylookup[y][x] := 0;
      x1 := x1 + costable[oldangle];
      y1 := y1 - FIXEDMUL(sintable[oldangle], 54394);
      x := x1 div FRACUNIT;
      y := y1 div FRACUNIT;
    end;
  end;
  oldangle := player.angle;
  x := 237;
  x1 := x * FRACUNIT;
  y := 161;
  y1 := y * FRACUNIT;
  c := 139;
  for i := 0 to 9 do
  begin
    ylookup[y][x] := c;
    x1 := x1 + costable[oldangle];
    y1 := y1 - FIXEDMUL(sintable[oldangle], 54394);
    x := x1 div FRACUNIT;
    y := y1 div FRACUNIT;
    dec(c);
  end;
end;


procedure displaysettings2;
begin
  if heatmode then
    memset(@ylookup[199][236], 102, 6)
  else
    memset(@ylookup[199][236], approx_zero, 6);
  if motionmode then
    memset(@ylookup[199][246], 156, 6)
  else
    memset(@ylookup[199][246], approx_zero, 6);
  if mapmode <> 0 then
    memset(@ylookup[199][226], 133, 6)
  else
    memset(@ylookup[199][226], approx_zero, 6);
end;


procedure displayinventory2;
var
  n, ammo, lump, i, j, count, top, bottom, x, y, maxshots: integer;
  str1: string;
  pic: Pscalepic_t;
  collumn: PByteArray;
begin
  font := font2;
  fontbasecolor := 0;
  n := player.weapons[player.currentweapon];
  if weapons[n].ammorate>0 then
  begin
    ammo := player.ammo[weapons[n].ammotype];
    maxshots := weapons[n].ammorate;
  end
  else
  begin
    maxshots := 999;
    ammo := 999;
  end;
  printx := 186;
  printy := 183;
  FN_Printf('%3d', [ammo]);
  printx := 203;
  printy := 183;
  FN_Printf('%3d', [maxshots]);
  printx := 187;
  printy := 191;
  FN_RawPrint(ammonames[weapons[n].ammotype]);

  if (inventorycursor = -1) or (player.inventory[inventorycursor] = 0) then
    inventoryright;
  if inventorycursor <> oldinventory then
  begin
    oldinventory := inventorycursor;
    for i := 162 to 184 do
      memset(@ylookup[i][113], approx_zero, 30);
    if inventorycursor <> -1 then
    begin
      lump := inventorylump + inventorycursor;
      printx := 149;  // name
      printy := 163;
      FN_RawPrint(inventorynames[inventorycursor]);
      pic := lumpcache[lump].data;  // draw the pic for it
      x := 128 - (pic.width div 2);
      for i := 0 to pic.width - 1 do
      begin
        if pic.collumnofs[i] <> 0 then
        begin
          collumn := PByteArray(pic);
          collumn := @collumn[pic.collumnofs[i]];
          top := collumn[1];
          bottom := collumn[0];
          count := bottom - top + 1;
          collumn := @collumn[2];
          y := 188 - top - count;
          for j := 0 to count - 1 do
          begin
            if collumn[0] <> 0 then
              ylookup[y][x] := collumn[0];
            inc(y);
            collumn := @collumn[1];
          end;
        end;
        inc(x);
      end;
      font := font3;  // number of items
      printx := 150;
      printy := 172;
      sprintf(str1, '%2d', [player.inventory[inventorycursor]]);
      FN_RawPrint(str1);
    end
    else
    begin
      printx := 149;  // name
      printy := 163;
      str1 := '              ';
      FN_RawPrint(str1);
      font := font3;  // number of items
      printx := 150;
      printy := 172;
      FN_RawPrint('  ');
    end;
  end;
end;


procedure displaynetbonusitem2;
var
  typ, name, str1: string;
  i, j, count, top, bottom, x, y, lump, score: integer;
  pic: Pscalepic_t;
  p: Ppic_t;
  collumn: PByteArray;
  b: PByte;
  time: integer;
begin
  if goalitem = -1 then
  begin
    if BonusItem.score <> 0 then
      togglegoalitem := true;
    for i := 158 to 187 do
      memset(@ylookup[i][19], approx_zero, 30);
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
    str1 := '';
    while Length(str1) < 32 do
      str1 := str1 + ' ';
    FN_RawPrint(str1);
    exit;
  end;
  if (goalitem = 0) and (BonusItem.score = 0) then
  begin
    togglegoalitem := true;
    exit;
  end;
  if oldgoalitem = goalitem then
    exit;
  font := font2;
  fontbasecolor := 0;
  if goalitem = 0 then
  begin
    lump := BonusItem.sprite.basepic;
    score := BonusItem.score;
    typ := 'Bonus  ';
    time := (BonusItem.time - timecount) div TICRATE;
    if time > 10000 then
      time := 0;
    sprintf(str1, '%3d s', [time]);
    name := BonusItem.name;
    pic := lumpcache[lump].data;
    x := 34 - (pic.width div 2);
    for i := 158 to 187 do
      memset(@ylookup[i][19], approx_zero, 30);
    for  i := 0 to pic.width - 1 do
    begin
      if pic.collumnofs[i] <> 0 then
      begin
        collumn := PByteArray(pic);
        collumn := @collumn[pic.collumnofs[i]];
        top := collumn[1];
        bottom := collumn[0];
        count := bottom - top + 1;
        collumn := @collumn[2];
        y := 188 - top - count;
        for j := 0 to count - 1 do
        begin
          if collumn[0] <> 0 then
            ylookup[y][x] := collumn[0];
          inc(y);
          collumn := @collumn[1];
        end;
      end;
      inc(x);
    end;
  end
  else
  begin
    lump := fraglump + playerdata[goalitem - 1].chartype;
    p := lumpcache[lump].data;
    typ := 'Player';
    name := netnames[goalitem - 1];
    sprintf(str1, '%d', [fragcount[goalitem - 1]]);
    while Length(str1) < 5 do
      str1 := ' ' + str1;

    b := @p.data;
    for  y := 0 to 29 do
      for x := 0 to 29 do
      begin
        ylookup[y + 158][19 + x] := b^;
        inc(b);
      end;
  end;
  oldgoalitem := goalitem;
  for i := 162 to 167 do
    memset(@ylookup[i][53], approx_zero, 23);
  for i := 172 to 177 do
    memset(@ylookup[i][53], approx_zero, 30);
  for i := 182 to 187 do
    memset(@ylookup[i][53], approx_zero, 39);
  for i := 192 to 197 do
    memset(@ylookup[i][22], 0, 159);
  printx := 53;
  printy := 162;
  FN_RawPrint('     ');
  printx := 53;
  printy := 172;
  FN_RawPrint(str1);
  printx := 53;
  printy := 182;
  FN_RawPrint(typ);
  printx := 22;
  printy := 192;
  str1 := name;
  while Length(str1) < 32 do
    str1 := ' ' + str1;
  FN_RawPrint(str1);
end;


procedure displaybonusitem2;
var
  typ, name, str1: string;
  i, j, count, top, bottom, x, y, lump, score, found, total: integer;
  pic: Pscalepic_t;
  collumn: PByteArray;
  time: integer;
begin
  if goalitem < 0 then
  begin
    if BonusItem.score <> 0 then
      togglegoalitem := true;
    for i := 158 to 187 do
      memset(@ylookup[i][19], approx_zero, 30);
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
    str1 := '';
    while Length(str1) < 32 do
      str1 := str1 + ' ';
    FN_RawPrint(str1);
    exit;
  end;
  if (goalitem = 0) and (BonusItem.score = 0) then
  begin
    togglegoalitem := true;
    exit;
  end;
  if (oldgoalitem = goalitem) and (goalitem <> 0) then
    exit;
  font := font2;
  fontbasecolor := 0;
  if goalitem = 0 then
  begin
    lump := BonusItem.sprite.basepic;
    score := BonusItem.score;
    typ := 'Bonus  ';
    time := (BonusItem.time - timecount) div TICRATE;
    if time > 10000 then
      time := 0;
    sprintf(str1, '%3d s', [time]);
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
    lump := primarylump + primaries[(goalitem - 1) * 2];
    score := primaries[(goalitem - 1) * 2 + 1];
    typ := 'Primary';
    found := player.primaries[goalitem - 1];
    total := pcount[goalitem - 1];
    sprintf(str1, '%2d/%2d', [found, total]);
    name := primnames[primaries[(goalitem - 1) * 2]];
  end
  else if goalitem >= 3 then
  begin
    lump := secondarylump + secondaries[(goalitem - 3) * 2];
    score := secondaries[(goalitem - 3) * 2 + 1];
    typ := 'Second ';
    found := player.secondaries[goalitem - 3];
    total := scount[goalitem - 3];
    sprintf(str1, '%2d/%2d', [found, total]);
    name := secnames[secondaries[(goalitem - 3) * 2]];
  end;

  oldgoalitem := goalitem;

  for i := 158 to 187 do
    memset(@ylookup[i][19], approx_zero, 30);
  pic := lumpcache[lump].data;
  x := 34 - (pic.width div 2);
  for i := 0 to pic.width - 1 do
  begin
    if pic.collumnofs[i] <> 0 then
    begin
      collumn := PByteArray(pic);
      collumn := @collumn[pic.collumnofs[i]];
      top := collumn[1];
      bottom := collumn[0];
      count := bottom - top + 1;
      collumn := @collumn[2];
      y := 188 - top - count;
      for j := 0 to count - 1 do
      begin
        if collumn[0] <> 0 then
          ylookup[y][x] := collumn[0];
        inc(y);
        collumn := @collumn[1];
      end;
    end;
    inc(x);
  end;

  for i := 162 to 167 do
    memset(@ylookup[i][53], approx_zero, 23);
  for i := 172 to 177 do
    memset(@ylookup[i][53], approx_zero, 30);
  for i := 182 to 187 do
    memset(@ylookup[i][53], approx_zero, 39);
  for i := 192 to 197 do
    memset(@ylookup[i][22], approx_zero, 159);

  printx := 53;
  printy := 162;
  FN_RawPrint(str1);
  printx := 53;
  printy := 172;
  FN_Printf('%5d', [score]);
  printx := 53;
  printy := 182;
  FN_RawPrint(typ);
  printx := 22;
  printy := 192;
  str1 := name;
  while Length(str1) < 32 do
    str1 := ' ' + str1;
  FN_RawPrint(str1);
end;


procedure displayrightstats2;
var
  n, shots: integer;
begin
  n := player.weapons[player.currentweapon];
  if weapons[n].ammorate > 0 then
    shots := player.ammo[weapons[n].ammotype] div weapons[n].ammorate
  else
    shots := 999;
  if shots <> oldshots then
  begin
    font := font3;
    printx := 225;
    printy := 178;
    fontbasecolor := 0;
    FN_Printf('%3d', [shots]);
    oldshots := shots;
  end;
  displaycompass2;
  displaysettings2;
  displaystats2;
end;


procedure displaybodycount2;
var
  str1: string;
  i, j, d, d1, c: integer;
begin
  // Bodycount
  font := font2;
  printx := 178;
  printy := 3;
  fontbasecolor := 0;
  sprintf(str1, '%8d', [player.bodycount]);
  FN_RawPrint(str1);
  oldbodycount := player.bodycount;

  // Score
  font := font2;
  printx := 28;
  printy := 3;
  fontbasecolor := 0;
  sprintf(str1, '%9d', [player.score]);
  FN_RawPrint(str1);
  oldscore := player.score;

  // Levelscore
  font := font2;
  printx := 104;
  printy := 3;
  fontbasecolor := 0;
  sprintf(str1, '%9d', [player.levelscore]);
  FN_RawPrint(str1);
  oldlevelscore := player.levelscore;

  if specialeffecttime <> $7FFFFFFF then
  begin
    d1 := (specialeffecttime - timecount) div 4;
    if d1 > 97 then
      d := 97
    else if d1 < 0 then
      d := 0
    else
      d := d1;

    for j := 0 to d - 1 do
    begin
      c := (j * 26) div d1;
      for i := 2 to 8 do
        ylookup[i][j + 221] := c + 140;
    end;
    if d < 97 then
      for j := d to 97 do
        for i := 2 to 8 do
          ylookup[i][j + 221] := approx_zero;
  end;
end;

procedure displayinventoryitem;
var
  lump, i, j, count, top, bottom, x, y: integer;
  str1: string;
  pic: Pscalepic_t;
  collumn: PByteArray;
begin
  if inventorycursor < 0 then
    exit;
  for i := 0 to 26 do
  begin
    memset(@ylookup[i][windowWidth - 54], approx_zero, 54);
    ylookup[i][windowWidth - 55] := 30;
  end;
  memset(@ylookup[27][windowWidth - 55], 30, 55);
  lump := inventorylump + inventorycursor;
  pic := lumpcache[lump].data; // draw the pic for it
  x := windowWidth - 31;
  for i := 0 to pic.width - 1 do
  begin
    if pic.collumnofs[i] <> 0 then
    begin
      collumn := PByteArray(pic);
      collumn := @collumn[pic.collumnofs[i]];
      top := collumn[1];
      bottom := collumn[0];
      count := bottom - top + 1;
      collumn := @collumn[2];
      y := 28 - top - count;
      for j := 0 to count - 1 do
      begin
        if collumn[0] <> 0 then
          ylookup[y][x] := collumn[0];
        inc(y);
        collumn := @collumn[1];
      end;
    end;
    inc(x);
  end;
  fontbasecolor := 0;
  font := font3;         // number of items
  printx := windowWidth - 53;
  printy := 6;
  sprintf(str1, '%2d', [player.inventory[inventorycursor]]);
  FN_RawPrint4(str1);
end;

procedure updatedisplay;
begin
  case currentViewSize of
  0:
    begin
      if timecount < inventorytime then
        displayinventoryitem;
    end;

  1,
  2,
  3:
    begin
      if currentViewSize >= 3 then
        displayinventory1(0);   // level 3 to view
      if currentViewSize >= 2 then
      begin
        if not netmode then
          displaybonusitem1(0)   // level 2 to view
        else
          displaynetbonusitem1(0);
      end;
      if currentViewSize >= 1 then
      begin
        displayrightstats1(0);  // level 1 to view
        if (currentViewSize < 3) and (timecount < inventorytime) then
          displayinventoryitem;
      end;
    end;

  4:  // level 4 to view + top to screen
    begin
      displayinventory1(0);
      if not netmode then
        displaybonusitem1(0)
      else
        displaynetbonusitem1(0);
      displayrightstats1(0);
      displaybodycount2;
    end;

  5,  // smaller screen sizes
  6,
  7,
  8,
  9:
    begin
      displayinventory2;
      if not netmode then
        displaybonusitem2
      else
        displaynetbonusitem2;
      displayrightstats2;
      displaybodycount2;
    end;
  end;
end;


procedure displayarrow(const x, y: integer);
var
  angle: integer;
begin
  ylookup[y][x] := 26;
  angle := (((player.angle + DEGREE45_2) and ANGLES) * 8) div ANGLES;
  case angle of
  0:
    begin
      ylookup[y][x + 1] := 40;
      ylookup[y][x - 1] := 20;
    end;

  1:
    begin
      ylookup[y - 1][x + 1] := 40;
      ylookup[y + 1][x - 1] := 20;
    end;

  2:
    begin
      ylookup[y - 1][x] := 40;
      ylookup[y + 1][x] := 20;
    end;

  3:
    begin
      ylookup[y - 1][x - 1] := 40;
      ylookup[y + 1][x + 1] := 20;
    end;

  4:
    begin
      ylookup[y][x - 1] := 40;
      ylookup[y][x + 1] := 20;
    end;

  5:
    begin
      ylookup[y + 1][x - 1] := 40;
      ylookup[y - 1][x + 1] := 20;
    end;

  6:
    begin
      ylookup[y + 1][x] := 40;
      ylookup[y - 1][x] := 20;
    end;

   7:
    begin
      ylookup[y + 1][x + 1] := 40;
      ylookup[y - 1][x - 1] := 20;
    end;
  end;
end;


// head up display map
procedure displaymapmode;
var
  i, j, ofsx, ofsy, x, y, px, py, mapy, mapx, c, a, miny, maxy, minx, maxx: integer;
  mapspot: integer;
  b: integer;
begin
  y := windowHeight div 4;
  miny := -(y div 2);
  maxy := y div 2;
  x := windowWidth div 4;
  minx := -(x div 2);
  maxx := x div 2;
  ofsx := 1 - (_SHR(player.x, (FRACBITS + 4)) and 3);
  ofsy := 1 - (_SHR(player.y, (FRACBITS + 4)) and 3);
  px := player.x div FRACTILEUNIT;
  py := player.y div FRACTILEUNIT;

  y := ofsy - 4;
  for i := miny to maxy do  // display north maps
  begin
    y := y + 4;
    mapy := py + i;
    if (mapy < 0) or (mapy >= MAPROWS) then
      continue;
    mapx := px + minx;
    mapspot := mapy * MAPCOLS + mapx;
    x := ofsx;
    for j := minx to maxx do
    begin
      if (mapx >= 0) and (mapx < MAPCOLS) and (player.northmap[mapspot] <> 0) then
      begin
        c := player.northmap[mapspot];
        if c = DOOR_COLOR then
        begin
          for a := 0 to 4 do
          begin
            if (x >= 0) and (x < windowWidth) and (y + 2 < windowHeight) and (y + 2 >= 0) then
              ylookup[y + 2][x] := c;
            inc(x);
          end;
        end
        else
        begin
          for a := 0 to 4 do
          begin
            if (x >= 0) and (x < windowWidth) and (y < windowHeight) and (y >= 0) then
              ylookup[y][x] := c;
            inc(x);
          end;
        end;
        dec(x);
      end
      else
        x := x + 4;
      inc(mapspot);
      inc(mapx);
    end;
  end;

  x := ofsx - 4;
  for j := minx to maxx do  // display west maps
  begin
    x := x + 4;
    mapx := px + j;
    if (mapx < 0) or (mapx >= MAPCOLS) then
      continue;
    mapy := py + miny;
    mapspot := mapy * MAPCOLS + mapx;
    y := ofsy;
    for i := miny to maxy do
    begin
      if (mapy >= 0) and (mapy < MAPROWS) and (player.westmap[mapspot] <> 0) then
      begin
        c := player.westmap[mapspot];
        if c = DOOR_COLOR then
        begin
          for a := 0 to 4 do
          begin
            if (y >= 0) and (y < windowHeight) and (x + 2 < windowWidth) and (x + 2 >= 0) then
              ylookup[y][x + 2] := c;
            inc(y);
          end;
        end
        else
        begin
          for a := 0 to 4 do
          begin
            if (y >= 0) and (y < windowHeight) and (x < windowWidth) and (x >= 0) then
              ylookup[y][x] := c;
            inc(y);
          end;
        end;
        dec(y);
      end
      else
        y := y + 4;
      mapspot := mapspot + MAPCOLS;
      inc(mapy);
    end;
  end;

  displayarrow(windowWidth div 2 + 1, windowHeight div 2 + 1);
  if BonusItem.score <> 0 then
  begin
    y := ofsy + 4 * (BonusItem.tiley - py);
    y := y + windowHeight div 2;
    x := ofsx + 4 * (BonusItem.tilex - px);
    x := x + windowWidth div 2;
    c := 44;
    for a := 0 to 3 do
      for b := 0 to 3 do
        if (x + b < windowWidth) and (x + b >= 0) and (y + a < windowHeight) and (y + a >= 0) then
          ylookup[y + a][b + x] := c;
  end;

  if exitexists then
  begin
    y := ofsy + 4 * (exity - py);
    y := y + windowHeight div 2;
    x := ofsx + 4 * (exitx - px);
    x := x + windowWidth div 2;
    for a := 0 to 3 do
      for b := 0 to 3 do
        if (x + b < windowWidth) and (x + b >= 0) and (y + a < windowHeight) and (y + a >= 0) then
          ylookup[y + a][b + x] := 187;
  end;
end;


// rotating map display
procedure displayswingmapmode;
var
  i, j, ofsx, ofsy, x, y, px, py, c, a, x1, y1, y2, x2: integer;
  xfrac, yfrac, xfrac2, yfrac2, xfracstep, yfracstep, xfracstep2, yfracstep2: fixed_t;
  mapspot: integer;
begin
  case MapZoom of
  8:
    begin
      ofsx := 1 - (_SHR(player.x, (FRACBITS + 3)) and 7);  // compute player tile offset
      ofsy := 1 - (_SHR(player.y, (FRACBITS + 3)) and 7);
    end;

  4:
    begin
      ofsx := 1 - (_SHR(player.x, (FRACBITS + 4)) and 3);  // compute player tile offset
      ofsy := 1 - (_SHR(player.y, (FRACBITS + 4)) and 3);
    end;

  16:
    begin
      ofsx := 1 - (_SHR(player.x, (FRACBITS + 2)) and 15); // compute player tile offset
      ofsy := 1 - (_SHR(player.y, (FRACBITS + 2)) and 15);
    end;
  end;

  px := (player.x div FRACTILEUNIT) * MapZoom - ofsx;  // compute player position
  py := (player.y div FRACTILEUNIT) * MapZoom - ofsy;
  // compute incremental values for both diagonal axis
  xfracstep := cosines[((player.angle + SOUTH) and ANGLES) * FINEUNIT];
  yfracstep := sines[((player.angle + SOUTH) and ANGLES) * FINEUNIT];
  xfracstep2 := cosines[player.angle * FINEUNIT];
  yfracstep2 := sines[player.angle * FINEUNIT];
  xfrac2 := ((windowWidth div 2) * FRACUNIT) - (py * xfracstep2 + px * xfracstep);
  yfrac2 := ((windowHeight div 2) * FRACUNIT) - (py * yfracstep2 + px * yfracstep);
  y := yfrac2 div FRACUNIT;
  x := xfrac2 div FRACUNIT;
  mapspot := 0;
  // don't ask me to explain this not  not  not
  // basically you start at upper left corner, adding one axis increment
  // on the y axis and then updating the one for the x axis as it draws
  if BonusItem.score <> 0 then
  begin
    yfrac2 := yfrac2 + yfracstep2 * MapZoom * BonusItem.tiley + (yfracstep2 * MapZoom div 2);
    xfrac2 := xfrac2 + xfracstep2 * MapZoom * BonusItem.tiley + (xfracstep2 * MapZoom div 2);

    xfrac := xfrac2 + xfracstep * MapZoom * BonusItem.tilex + (xfracstep * MapZoom div 2);
    yfrac := yfrac2 + yfracstep * MapZoom * BonusItem.tilex + (yfracstep * MapZoom div 2);

    x1 := xfrac div FRACUNIT;
    y1 := yfrac div FRACUNIT;

    if (y1 >= 0) and (x1 >= 0) and (x1 < windowWidth) and (y1 < windowHeight) then
      ylookup[y1][x1] := 44;
    if (y1 + 1 >= 0) and (x1 >= 0) and (x1 < windowWidth) and (y1 + 1 < windowHeight) then
      ylookup[y1 + 1][x1] := 44;
    inc(x1);
    if (y1 >= 0) and (x1 >= 0) and (x1 < windowWidth) and (y1 < windowHeight) then
      ylookup[y1][x1] := 44;
    inc(y1);
    if (y1 >= 0) and (x1 >= 0) and (x1 < windowWidth) and (y1 < windowHeight) then
      ylookup[y1][x1] := 44;

    xfrac2 := ((windowWidth div 2) * FRACUNIT) - (py * xfracstep2 + px * xfracstep);
    yfrac2 := ((windowHeight div 2) * FRACUNIT) - (py * yfracstep2 + px * yfracstep);
    y := yfrac2 div FRACUNIT;
    x := xfrac2 div FRACUNIT;
  end;
  if exitexists then
  begin
    yfrac2 := yfrac2 + yfracstep2 * MapZoom * exity + (yfracstep2 * MapZoom div 2);
    xfrac2 := xfrac2 + xfracstep2 * MapZoom * exity + (xfracstep2 * MapZoom div 2);

    xfrac := xfrac2 + xfracstep * MapZoom * exitx + (xfracstep * MapZoom div 2);
    yfrac := yfrac2 + yfracstep * MapZoom * exitx + (yfracstep * MapZoom div 2);

    x1 := xfrac div FRACUNIT;
    y1 := yfrac div FRACUNIT;

    if (y1 >= 0) and (x1 >= 0) and (x1 < windowWidth) and (y1 < windowHeight) then
      ylookup[y1][x1] := 187;
    if (y1 + 1 >= 0) and (x1 >= 0) and (x1 < windowWidth) and (y1 + 1 < windowHeight) then
      ylookup[y1 + 1][x1] := 187;
    inc(x1);
    if (y1 >= 0) and (x1 >= 0) and (x1 < windowWidth) and (y1 < windowHeight) then
      ylookup[y1][x1] := 187;
    inc(y1);
    if (y1 >= 0) and (x1 >= 0) and (x1 < windowWidth) and (y1 < windowHeight) then
      ylookup[y1][x1] := 187;

    xfrac2 := ((windowWidth div 2) * FRACUNIT) - (py * xfracstep2 + px * xfracstep);
    yfrac2 := ((windowHeight div 2) * FRACUNIT) - (py * yfracstep2 + px * yfracstep);
    y := yfrac2 div FRACUNIT;
    x := xfrac2 div FRACUNIT;
  end;

  for i := 0 to MAPCOLS - 1 do
  begin
    xfrac := xfrac2;
    yfrac := yfrac2;
    x1 := x;
    y1 := y;
    for j := 0 to MAPROWS - 1 do
    begin
      if player.northmap[mapspot] <> 0 then
      begin
        c := player.northmap[mapspot];
        if c = DOOR_COLOR then
        begin
          for a := 0 to MapZoom do
          begin
            y2 := y1 + (((MapZoom div 2) * yfracstep2) div FRACUNIT);
            x2 := x1 + (((MapZoom div 2) * xfracstep2) div FRACUNIT);
            if (y2 >= 0) and (x2 >= 0) and (x2 < windowWidth) and (y2 < windowHeight) then
              ylookup[y2][x2] := c;
            xfrac := xfrac + xfracstep;
            x1 := xfrac div FRACUNIT;
            yfrac := yfrac + yfracstep;
            y1 := yfrac div FRACUNIT;
          end;
        end
        else
        begin
          for a := 0 to MapZoom do
          begin
            if (y1 >= 0) and (x1 >= 0) and (x1 < windowWidth) and (y1 < windowHeight) then
              ylookup[y1][x1] := c;
            xfrac := xfrac + xfracstep;
            x1 := xfrac div FRACUNIT;
            yfrac := yfrac + yfracstep;
            y1 := yfrac div FRACUNIT;
          end;
        end;
        xfrac := xfrac - xfracstep;
        x1 := xfrac div FRACUNIT;
        yfrac := yfrac - yfracstep;
        y1 := yfrac div FRACUNIT;
      end
      else
      begin
        xfrac := xfrac + xfracstep * MapZoom;
        x1 := xfrac div FRACUNIT;
        yfrac := yfrac + yfracstep * MapZoom;
        y1 := yfrac div FRACUNIT;
      end;
      inc(mapspot);
    end;
    yfrac2 := yfrac2 + yfracstep2 * MapZoom;
    y := yfrac2 div FRACUNIT;
    xfrac2 := xfrac2 + xfracstep2 * MapZoom;
    x := xfrac2 div FRACUNIT;
  end;

  xfrac := ((windowWidth div 2) * FRACUNIT) - (py * xfracstep2 + px * xfracstep);
  yfrac := ((windowHeight div 2) * FRACUNIT) - (py * yfracstep2 + px * yfracstep);
  y := yfrac div FRACUNIT;
  x := xfrac div FRACUNIT;
  for i := 0 to MAPCOLS - 1 do
  begin
    xfrac2 := xfrac;
    yfrac2 := yfrac;
    x1 := x;
    y1 := y;
    mapspot := i;
    for j := 0 to MAPROWS - 1 do
    begin
      if player.westmap[mapspot] <> 0 then
      begin
        c := player.westmap[mapspot];
        if c = DOOR_COLOR then
        begin
          for a := 0 to MapZoom do
          begin
            y2 := y1 + (((MapZoom div 2) * yfracstep) div FRACUNIT);
            x2 := x1 + (((MapZoom div 2) * xfracstep) div FRACUNIT);
            if (y2 >= 0) and (x2 >= 0) and (x2 < windowWidth) and (y2 < windowHeight) then
              ylookup[y2][x2] := c;
            xfrac2 := xfrac2 + xfracstep2;
            x1 := xfrac2 div FRACUNIT;
            yfrac2 := yfrac2 + yfracstep2;
            y1 := yfrac2 div FRACUNIT;
          end;
        end
        else
        begin
          for a := 0 to MapZoom do
          begin
            if (y1 >= 0) and (x1 >= 0) and (x1 < windowWidth) and (y1 < windowHeight) then
              ylookup[y1][x1] := c;
            xfrac2 := xfrac2 + xfracstep2;
            x1 := xfrac2 div FRACUNIT;
            yfrac2 := yfrac2 + yfracstep2;
            y1 := yfrac2 div FRACUNIT;
          end;
        end;
        xfrac2 := xfrac2 - xfracstep2;
        x1 := xfrac2 div FRACUNIT;
        yfrac2 := yfrac2 - yfracstep2;
        y1 := yfrac2 div FRACUNIT;
      end
      else
      begin
        xfrac2 := xfrac2 + xfracstep2 * MapZoom;
        x1 := xfrac2 div FRACUNIT;
        yfrac2 := yfrac2 + yfracstep2 * MapZoom;
        y1 := yfrac2 div FRACUNIT;
      end;
      mapspot := mapspot + MAPCOLS;
    end;
    yfrac := yfrac + yfracstep * MapZoom;
    y := yfrac div FRACUNIT;
    xfrac := xfrac + xfracstep * MapZoom;
    x := xfrac div FRACUNIT;
  end;
  ylookup[windowHeight div 2 + 1][windowWidth div 2 + 1] := 40;
end;


// display overhead heat sensor
procedure displayheatmode;
var
  i, j, c: integer;
begin
  for i := 0 to 63 do
    for j := 0 to 63 do
      if reallight[i * 64 + j] <> 0 then
      begin
        c := -reallight[i * 64 + j] div 48;
        if c > 15 then
          c := 15
        else if c < 0 then
          c := 0;
        ylookup[i + 21][j + 3] := 88 - c;
      end;

  memset(@ylookup[20][2], 73, 66);
  memset(@ylookup[85][2], 73, 66);
  for i := 21 to 84 do
  begin
    ylookup[i][2] := 73;
    ylookup[i][67] := 73;
  end;
  ylookup[(player.y div FRACTILEUNIT) + 21][(player.x div FRACTILEUNIT) + 3] := 40;
  if BonusItem.score <> 0 then
    ylookup[BonusItem.tiley + 21][BonusItem.tilex + 3] := 44;
  if exitexists then
    ylookup[exity + 21][exitx + 3] := 187;
end;


// display heat traces on the overhead map
procedure displayheatmapmode;
var
  i, j, ofsx, ofsy, x, y, px, py, mapy, mapx, c, a, miny, maxy, minx, maxx: integer;
  mapspot, b: integer;
begin
  y := windowHeight div 4;
  miny := -(y div 2);
  maxy := y div 2;
  x := windowWidth div 4;
  minx := -(x div 2);
  maxx := x div 2;
  ofsx := 1 - (_SHR(player.x, (FRACBITS + 4)) and 3);
  ofsy := 1 - (_SHR(player.y, (FRACBITS + 4)) and 3);
  px := player.x div FRACTILEUNIT;
  py := player.y div FRACTILEUNIT;
  y := ofsy - 4;
  for i := miny to maxy do
  begin
    y := y + 4;
    mapy := py + i;
    if (mapy < 0) or (mapy >= MAPROWS) then
      continue;
    mapx := px + minx;
    mapspot := mapy * MAPCOLS + mapx;
    x := ofsx;
    for j := minx to maxx do
    begin
      if (mapx >= 0) and (mapx < MAPCOLS) and (reallight[mapspot] <> 0) then
      begin
        c := -reallight[mapspot] div 48;
        if c > 15 then
          c := 15
        else if c < 0 then
          c := 0;
        c := 88 - c;
        for a := 0 to 3 do
          if (y + a < windowHeight) and (y + a >= 0) then
            for b := 0 to 3 do
              if (x + b < windowWidth) and (x + b >= 0) then
                ylookup[y + a][b + x] := c;
      end;
      x := x + 4;
      inc(mapspot);
      inc(mapx);
    end;
  end;
end;


// display sensors on overhead display
procedure displaymotionmode;
var
  sp: Pscaleobj_t;
  sx, sy, i: integer;
begin
  sp := firstscaleobj.next;
  while sp <> @lastscaleobj do
  begin
    if sp.active and (sp.hitpoints <> 0) then
    begin
      sx := sp.x div FRACTILEUNIT;
      sy := sp.y div FRACTILEUNIT;
      ylookup[sy + 21][sx + 3] := 152;
    end;
    sp := sp.next;
  end;

  memset(@ylookup[20][2], 73, 66);
  memset(@ylookup[85][2], 73, 66);
  for i := 21 to 84 do
  begin
    ylookup[i][2] := 73;
    ylookup[i][67] := 73;
  end;
  ylookup[(player.y div FRACTILEUNIT) + 21][(player.x div FRACTILEUNIT) + 3] := 40;
  if BonusItem.score <> 0 then
    ylookup[BonusItem.tiley + 21][BonusItem.tilex + 3] := 44;
  if exitexists then
    ylookup[exity + 21][exitx + 3] := 187;
end;


// display sensors on overhead map
procedure displaymotionmapmode;
var
  ofsx, ofsy, x, y, a, b, px, py: integer;
  sp: Pscaleobj_t;
begin
  ofsx := 1 - (_SHR(player.x, (FRACBITS + 4)) and 3) + windowWidth div 2;
  ofsy := 1 - (_SHR(player.y, (FRACBITS + 4)) and 3) + windowHeight div 2;
  px := player.x div FRACTILEUNIT;
  py := player.y div FRACTILEUNIT;
  sp := firstscaleobj.next;
  while sp <> @lastscaleobj do
  begin
    if (sp.active) and (sp.hitpoints <> 0) then
    begin
      x := (((sp.x div FRACTILEUNIT) - px) * 4) + ofsx;
      y := (((sp.y div FRACTILEUNIT) - py) * 4) + ofsy;
      for a := 0 to 3 do
        if (y + a < windowHeight) and (y + a >= 0) then
          for b := 0 to 3 do
            if (x + b < windowWidth) and (x + b >= 0) then
              ylookup[y + a][b + x] := 152;
    end;
    sp := sp.next;
  end;
end;

end.


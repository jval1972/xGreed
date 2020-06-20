(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020 by Jim Valavanis                                     *)
(*                                                                         *)
(***************************************************************************)

{$I xGreed.inc}

unit event;

interface

uses
  r_public_h;
  
const
  MAXZONES = 255;
  ACTIVATIONTYPE = 0;
  MAPZONETYPE = 1;
  SPAWNTYPE = 2;
  TRIGGERTYPE = 3;
  SOUNDTYPE = 4;
  FLITYPE = 5;
  AREATRIGGERTYPE = 6;

const
  MAXPROCESS = 128;

const
  C_NORTHWALL = 0;
  C_NORTHFLAGS = 1;
  C_WESTWALL = 2;
  C_WESTFLAGS = 3;
  C_FLOOR = 4;
  C_FLOORFLAGS = 5;
  C_CEILING = 6;
  C_CEILINGFLAGS = 7;
  C_FLOORHEIGHT = 8;
  C_CEILINGHEIGHT = 9;
  C_FLOORDEF = 10;
  C_FLOORDEFFLAGS = 11;
  C_CEILINGDEF = 12;
  C_CEILINGDEFFLAGS = 13;
  C_LIGHTS = 14;
  C_EFFECTS = 15;
  C_SPRITES = 16;
  C_SLOPES = 17;

type
  zone_t = record
    x1, y1, x2, y2: integer;
    eval, endeval: integer;
    rate, layer, newvalue, stype, removeable: integer;
    typ: integer;
  end;
  Pzone_t = ^zone_t;

var
  triggers: array[0..MAPROWS - 1, 0..MAPCOLS - 1] of byte;
  switches: array[0..MAPROWS - 1, 0..MAPCOLS - 1] of byte;
  processes: array[0..MAXPROCESS -1] of integer;
  numprocesses, numzones, fliplayed: integer;
  zones: array[0..MAXZONES - 1] of zone_t;
  fliname: array[0..2] of string[12] = (
    'JETTISON.FLI',
    'TMPL_DIE.FLI',
    'KAAL_DIE.FLI'
  );

procedure RunEvent(const eval: integer; const netsend: boolean);

procedure LoadScript(const lump: integer; const newgame: boolean);

procedure Process;

implementation

uses
  g_delphi,
  Classes,
  constant,
  d_disk,
  d_font,
  d_ints,
  d_misc,
  d_video,
  intro,
  menu,
  modplay,
  playfli,
  protos_h,
//  net,
  raven,
  r_conten,
  r_public,
  r_render,
  scriptengine,
  spawn,
  sprites,
  utils;

procedure AddProcess(const n: integer);
var
  i: integer;
begin
  if numprocesses = MAXPROCESS then
    MS_Error('AddProcess(): Too many active processes! (%d)', [MAXPROCESS]);
  i := 0;
  while (i < MAXPROCESS) and (processes[i] <> 0) do
    inc(i);
  if i = MAXPROCESS then
  MS_Error('AddProcess(): Process array overflow');
  processes[i] := 1000 + n;
  inc(numprocesses);
end;


procedure RunEvent(const eval: integer; const netsend: boolean);
var
  i, j: integer;
  elev_p: Pelevobj_t;
  sp: Pscaleobj_t;
  x, y: integer;
  x1, y1: fixed_t;
  vrscr: PByteArray;
  name: string;
begin
//  if netsend and netmode then
//    NetEvent(eval);

  if eval < 256 then
  begin
    player.events[eval] := 1;
    if (eval > 200) and (eval and 1 = 0) then
      player.events[eval - 1] := 0;
  end;

  for i := 0 to MAPCOLS - 1 do
    for j := 0 to MAPROWS - 1 do
      if triggers[j, i] = eval then
        triggers[j, i] := 0;
  for i := 0 to MAPCOLS - 1 do
    for j := 0 to MAPROWS - 1 do
      if switches[j, i] = eval then
        switches[j, i] := 0;

  elev_p := firstelevobj.next;
  while elev_p <> @lastelevobj do
  begin
    if (elev_p.eval = eval) and (eval > 0) then
    begin
      if elev_p.position = elev_p.floor then
      begin
        elev_p.elevUp := true;
        elev_p.eval := 0;
        elev_p.elevTimer := timecount;
        SoundEffect(SN_ELEVATORSTART, 15, (elev_p.mapspot and 63) * FRACTILEUNIT, (elev_p.mapspot shr 6) * FRACTILEUNIT);
      end
      else if elev_p.position = elev_p.ceiling then
      begin
        elev_p.elevDown := true;
        elev_p.eval := 0;
        elev_p.elevTimer := timecount;
        SoundEffect(SN_ELEVATORSTART, 15, (elev_p.mapspot and 63) * FRACTILEUNIT, (elev_p.mapspot shr 6) * FRACTILEUNIT);
      end;
    end;
    elev_p := elev_p.next;
  end;

// if (eval = 50)
//   begin
//   debug := fopen('debug.txt','wt');
//   for (i := 0;i<numzones;i++)
//    fprintf(debug,'zone:%i eval:%i type:%i\n',i,zones[i].eval,zones[i].typ);
//   fclose(debug);
//    end;

  for i := 0 to numzones - 1 do
    if zones[i].eval = eval then
    begin
      if zones[i].typ = ACTIVATIONTYPE then
      begin
        sp := firstscaleobj.next;
        while sp <> @lastscaleobj do
        begin
          if (sp.active = false) and (sp.moveSpeed <> 0) then
          begin
            x := sp.x div FRACTILEUNIT;
            y := sp.y div FRACTILEUNIT;
            if (x >= zones[i].x1) and (x <= zones[i].x2) and (y >= zones[i].y1) and (y <= zones[i].y2) then
            begin
              sp.active := true;
              sp.actiontime := timecount + 40;
              ActivationSound(sp);
            end;
          end;
          sp := sp.next;
        end;

        if zones[i].removeable <> 0 then
        begin
          zones[i].typ := -1;
          zones[i].eval := 0;
        end
      end
      else if zones[i].typ = MAPZONETYPE then
      begin
        AddProcess(i);
        if zones[i].removeable <> 0 then
        begin
          zones[i].typ := -1;
          zones[i].eval := 0;
        end;
      end
      else if (zones[i].typ = SPAWNTYPE) and (eval > 0) then
      begin
        gameloading := true;
        if not eventloading or (zones[i].endeval <> 0) then
        begin
          x1 := (zones[i].x1 * MAPSIZE + 32) * FRACUNIT;
          y1 := (zones[i].y1 * MAPSIZE + 32) * FRACUNIT;
          SpawnSprite(S_WARP, x1, y1, RF_GetFloorZ(x1, y1) + 10 * FRACUNIT, 0, 0, 0, true, 0);
          sp := SpawnSprite(zones[i].stype, x1, y1, RF_GetFloorZ(x1, y1) + 10 * FRACUNIT, 0, 0, 0, true, 0);
          sp.deathevent := zones[i].endeval;
        end;
        gameloading := false;
        if zones[i].removeable <> 0 then
        begin
          zones[i].typ := -1;
          zones[i].eval := 0;
        end;
      end
      else if (zones[i].typ = TRIGGERTYPE) and (eval > 0) then
      begin
        triggers[zones[i].x1, zones[i].y1] := zones[i].endeval;
        if zones[i].removeable <> 0 then
        begin
          zones[i].typ := -1;
          zones[i].eval := 0;
        end;
      end
      else if (zones[i].typ = SOUNDTYPE) and (eval > 0) then
      begin
        SoundEffect(zones[i].endeval, 0, (zones[i].x1 * MAPSIZE + 32) * FRACUNIT, (zones[i].y1 * MAPSIZE + 32) * FRACUNIT);
        if zones[i].removeable <> 0 then
        begin
          zones[i].typ := -1;
          zones[i].eval := 0;
        end;
      end
      else if zones[i].typ = AREATRIGGERTYPE then
      begin
        for y := zones[i].y1 to zones[i].y2 - 1 do
          for x := zones[i].x1 to zones[i].x2 - 1 do
            triggers[x, y] := zones[i].endeval;
        if zones[i].removeable <> 0 then
        begin
          zones[i].typ := -1;
          zones[i].eval := 0;
        end;
      end
      else if (zones[i].typ = FLITYPE) and (eval > 0) and not netmode then
      begin
        if DEMO then
          DoPlayFLI('GREED.BLO', infotable[CA_GetNamedNum(fliname[zones[i].endeval])].filepos)
        else
        begin
          if CDROMGREEDDIR then
            name := Chr(cdr_drivenum + Ord('A')) + ':\GREED\MOVIES\' + fliname[zones[i].endeval]
          else
            name := Chr(cdr_drivenum + Ord('A')) + ':\MOVIES\' + fliname[zones[i].endeval];
          DoPlayFLI(name,0);
        end;
        font := font1;
        fontbasecolor := 8;
        printx := 160;
        printy := 185;
        case zones[i].endeval of
        0: FN_PrintCentered('Do not taunt happy fun airlock.');
        1: FN_PrintCentered('Original recipe or extra crispy?');
        2: FN_PrintCentered('Thank you for recycling!');
        end;
        fliplayed := 1;
        zones[i].eval := 0;
        zones[i].typ := -1;
        player.angst := 0;

        if SC.vrhelmet = 1 then
        begin
          screen := vrscr;
          for j := 0 to SCREENHEIGHT - 1 do
            ylookup[j] := @screen[j * SCREENWIDTH];
        end;
      end;
    end;
end;


procedure Process;
var
  count, index, x, y, mapspot: integer;
  z: Pzone_t;
  layer: PByteArray;
  changed: boolean;
begin
  count := numprocesses;
  index := -1;
  repeat
    inc(index);
    dec(count);
    while (index < MAXPROCESS) and (processes[index] = 0) do
      inc(index);
    if index = MAXPROCESS then
      MS_Error('Processes(): can''t find next process!');
    z := @zones[processes[index] - 1000];
    case z.layer  of
    C_NORTHWALL: layer := @northwall;
    C_WESTWALL: layer := @westwall;
    C_LIGHTS: layer := @maplights;
    C_FLOORHEIGHT: layer := @floorheight;
    C_CEILINGHEIGHT: layer := @ceilingheight;
    C_EFFECTS: layer := @mapeffects;
    C_CEILING: layer := @ceilingpic;
    C_FLOOR: layer := @floorpic;
    else
      MS_Error('Layer %d is not implemented', [z.layer]);
    end;

    changed := false;
    for y := z.y1 to z.y2 do
      for x := z.x1 to z.x2 do
      begin
        mapspot := y * MAPCOLS + x;
        if layer[mapspot] < z.newvalue then
        begin
          if integer(layer[mapspot]) + z.rate > z.newvalue then
            layer[mapspot] := z.newvalue
          else
            layer[mapspot] := layer[mapspot] + z.rate;
          changed := true;
        end
        else if layer[mapspot] > z.newvalue then
        begin
          if integer(layer[mapspot]) - z.rate < z.newvalue then
            layer[mapspot] := z.newvalue
          else
            layer[mapspot] := layer[mapspot] - z.rate;
          if layer[mapspot] < z.newvalue then
            layer[mapspot] := z.newvalue;
          changed := true;
        end;
      end;

    if not changed then
    begin
      dec(numprocesses);
      processes[index] := 0;
      if z.endeval <> 0 then
        RunEvent(z.endeval, false);
    end;
  until count<= 0;
end;


procedure LoadScript(const lump: integer; const newgame: boolean);
var
  s, fname: string;
  sl: TStringList;
  sce: TScriptEngine;
  stmp: string;
  i, j, x, y, eval, line, etype, upper, lower, speed, result, endeval: integer;
  num, val, psprite, total, ceval, def1, def2, x1, y1, x2, y2, removeable: integer;
  elevator_p: Pelevobj_t;
  z: Pzone_t;
  numloadsprites, eventlump: integer;
  loadsprites, loadspritesn: array[0..15] of integer;
begin
  memset(@triggers, 0, SizeOf(triggers));
  memset(@switches, 0, SizeOf(switches));
  memset(@zones, 0, SizeOf(zones));
  memset(@processes, 0, SizeOf(processes));
  numprocesses := 0;
  numzones := 0;
  fliplayed := 0;
  numloadsprites := 0;

  memset(@secondaries, -1, SizeOf(secondaries));
  memset(@primaries, -1, SizeOf(primaries));
  memset(@pcount, 0, SizeOf(pcount));
  memset(@scount, 0, SizeOf(scount));
  bonustime := 3150;
  levelscore := 100000;
  player.levelscore := 100000;
  eventlump := CA_GetNamedNum('BACKDROP');
  sl := TStringList.Create;

  if MS_CheckParm('file') > 0 then
  begin
    fname := CA_LumpName(lump);
    s := fname;
    i := 1;
    while (i <= Length(s)) and (s[i] <> '.') do inc(i);
    SetLength(s, i);
    s := s + '.SUX';
    sl.Text := CA_FileAsText(s);
  end
  else
    sl.Text := CA_LumpAsText(lump - CA_GetNamedNum('MAP') + CA_GetNamedNum('SUX'));

  sce := TScriptEngine.Create(sl.Text);
  while sce.GetString do
  begin
    stmp := strupper(sce._String);
    if stmp = 'END' then
      break
    else if stmp = 'TRIGGER' then
    begin
      sce.MustGetInteger;
      x := sce._Integer;
      sce.MustGetInteger;
      y := sce._Integer;
      sce.MustGetInteger;
      eval := sce._Integer;
      triggers[x][y] := eval;
    end
    else if stmp = 'AREATRIGGER' then
    begin
      sce.MustGetInteger;
      x1 := sce._Integer;
      sce.MustGetInteger;
      y1 := sce._Integer;
      sce.MustGetInteger;
      x2 := sce._Integer;
      sce.MustGetInteger;
      y2 := sce._Integer;
      sce.MustGetInteger;
      eval := sce._Integer;
      for i := y1 to y2 do
        for j := x1 to x2 do
          triggers[j][i] := eval;
    end
    else if stmp = 'WALLSWITCH' then
    begin
      sce.MustGetInteger;
      x := sce._Integer;
      sce.MustGetInteger;
      y := sce._Integer;
      sce.MustGetInteger;
      eval := sce._Integer;
      switches[x][y] := eval;
    end
    else if stmp = 'ELEVATOR' then
    begin
      sce.MustGetInteger;
      x := sce._Integer;
      sce.MustGetInteger;
      y := sce._Integer;
      sce.MustGetInteger;
      eval := sce._Integer;
      sce.MustGetInteger;
      endeval := sce._Integer;
      sce.MustGetInteger;
      etype := sce._Integer;
      sce.MustGetInteger;
      upper := sce._Integer;
      sce.MustGetInteger;
      lower := sce._Integer;
      sce.MustGetInteger;
      speed := sce._Integer;
      elevator_p := RF_GetElevator;
      elevator_p.floor := lower;
      elevator_p.mapspot := y * MAPCOLS + x;
      elevator_p.ceiling := upper;
      if etype = 0 then
        elevator_p.position := lower
      else
        elevator_p.position := upper;
      elevator_p.typ := E_TRIGGERED;
      elevator_p.elevTimer := $70000000;
      elevator_p.speed := speed;
      elevator_p.eval := eval;
      elevator_p.endeval := endeval;
      elevator_p.elevTimer := player.timecount;
      elevator_p.nosave := 1;
      floorheight[elevator_p.mapspot] := elevator_p.position;
    end
    else if stmp = 'SPAWNELEVATOR' then
    begin
      sce.MustGetInteger;
      x := sce._Integer;
      sce.MustGetInteger;
      y := sce._Integer;
      sce.MustGetInteger;
      eval := sce._Integer;
      sce.MustGetInteger;
      etype := sce._Integer;
      sce.MustGetInteger;
      upper := sce._Integer;
      sce.MustGetInteger;
      lower := sce._Integer;
      sce.MustGetInteger;
      speed := sce._Integer;
      elevator_p := RF_GetElevator;
      elevator_p.floor := lower;
      elevator_p.mapspot := y * MAPCOLS + x;
      elevator_p.ceiling := upper;
      if etype = 0 then
        elevator_p.position := lower
      else
        elevator_p.position := upper;
      elevator_p.typ := E_NORMAL;
      elevator_p.elevTimer := $70000000;
      elevator_p.speed := speed;
      elevator_p.eval := eval;
      elevator_p.endeval := endeval;
      elevator_p.elevTimer := player.timecount;
      elevator_p.nosave := 1;
      floorheight[elevator_p.mapspot] := elevator_p.position;
    end
    else if stmp = 'ACTIVATIONZONE' then
    begin
      z := @zones[numzones];
      inc(numzones);
      if numzones = MAXZONES then
        MS_Error('Out of mapzones');
      sce.MustGetInteger;
      z.x1 := sce._Integer;
      sce.MustGetInteger;
      z.y1 := sce._Integer;
      sce.MustGetInteger;
      z.x2 := sce._Integer;
      sce.MustGetInteger;
      z.y2 := sce._Integer;
      sce.MustGetInteger;
      z.eval := sce._Integer;
      sce.MustGetInteger;
      z.removeable := sce._Integer;
      z.typ := ACTIVATIONTYPE;
    end
    else if stmp = 'MAPZONE' then
    begin
      z := @zones[numzones];
      inc(numzones);
      if numzones = MAXZONES then
        MS_Error('Out of mapzones');
      z.x1 := sce._Integer;
      sce.MustGetInteger;
      z.y1 := sce._Integer;
      sce.MustGetInteger;
      z.x2 := sce._Integer;
      sce.MustGetInteger;
      z.y2 := sce._Integer;
      sce.MustGetInteger;
      z.eval := sce._Integer;
      sce.MustGetInteger;
      z.endeval := sce._Integer;
      sce.MustGetInteger;
      z.layer := sce._Integer;
      sce.MustGetInteger;
      z.newvalue := sce._Integer;
      sce.MustGetInteger;
      z.rate := sce._Integer;
      sce.MustGetInteger;
      z.removeable := sce._Integer;
      z.typ := MAPZONETYPE;
    end
    else if stmp = 'BONUSTIME' then
    begin
      sce.MustGetInteger;
      bonustime := sce._Integer * 70;
    end
    else if stmp = 'PRIMARY' then
    begin
      sce.MustGetInteger;
      num := sce._Integer;
      sce.MustGetInteger;
      val := sce._Integer;
      sce.MustGetInteger;
      total := sce._Integer;
      sce.MustGetInteger;
      psprite := sce._Integer;
      primaries[num * 2] := psprite;
      primaries[num * 2 + 1] := val;
      pcount[num] := total;
    end
    else if stmp = 'SECONDARY' then
    begin
      sce.MustGetInteger;
      num := sce._Integer;
      sce.MustGetInteger;
      val := sce._Integer;
      sce.MustGetInteger;
      total := sce._Integer;
      sce.MustGetInteger;
      psprite := sce._Integer;
      secondaries[num * 2] := psprite;
      secondaries[num * 2 + 1] := val;
      scount[num] := total;
    end
    else if stmp = 'LEVELSCORE' then
    begin
      sce.MustGetInteger;
      player.levelscore := sce._Integer;
    end
    else if stmp = 'SPRITE' then
    begin
      sce.MustGetInteger;
      x := sce._Integer;
      sce.MustGetInteger;
      y := sce._Integer;
      sce.MustGetInteger;
      num := sce._Integer;
      sce.MustGetInteger;
      ceval := sce._Integer;
      sce.MustGetInteger;
      def1 := sce._Integer;
      sce.MustGetInteger;
      def2 := sce._Integer;
      if (newgame) and (player.difficulty >= 5 - def2) and (player.difficulty <= 5 - def1) then
      begin
        gameloading := true;
        mapsprites[y * MAPCOLS + x] := num;
        gameloading := false;
      end;
    end
    else if stmp = 'SPAWN' then
    begin
      sce.MustGetInteger;
      x := sce._Integer;
      sce.MustGetInteger;
      y := sce._Integer;
      sce.MustGetInteger;
      eval := sce._Integer;
      sce.MustGetInteger;
      num := sce._Integer;
      sce.MustGetInteger;
      ceval := sce._Integer;
      sce.MustGetInteger;
      def1 := sce._Integer;
      sce.MustGetInteger;
      def2 := sce._Integer;
      sce.MustGetInteger;
      removeable := sce._Integer;
      if (player.difficulty >= 5 - def2) and (player.difficulty <= 5 - def1) and
         (newgame or ((not newgame) and ((removeable = 0) or (player.events[eval] = 0)))) then
      begin
        z := @zones[numzones];
        inc(numzones);
        if numzones = MAXZONES then
          MS_Error('Out of mapzones');
        z.x1 := x;
        z.y1 := y;
        z.eval := eval;
        z.endeval := ceval;
        z.stype := num;
        z.typ := SPAWNTYPE;
        z.removeable := removeable;
      end;
   end
   else if stmp = 'SPAWNTRIGGER' then
   begin
      sce.MustGetInteger;
      x := sce._Integer;
      sce.MustGetInteger;
      y := sce._Integer;
      sce.MustGetInteger;
      eval := sce._Integer;
      sce.MustGetInteger;
      ceval := sce._Integer;
      sce.MustGetInteger;
      removeable := sce._Integer;
      z := @zones[numzones];
      inc(numzones);
      if numzones = MAXZONES then
        MS_Error('Out of mapzones');
      z.x1 := x;
      z.y1 := y;
      z.eval := eval;
      z.endeval := ceval;
      z.typ := TRIGGERTYPE;
      z.removeable := removeable;
    end
    else if stmp = 'SPAWNSOUND' then
   begin
      sce.MustGetInteger;
      x := sce._Integer;
      sce.MustGetInteger;
      y := sce._Integer;
      sce.MustGetInteger;
      eval := sce._Integer;
      sce.MustGetInteger;
      ceval := sce._Integer;
      sce.MustGetInteger;
      removeable := sce._Integer;
      z := @zones[numzones];
      inc(numzones);
      if numzones = MAXZONES then
        MS_Error('Out of mapzones');
      z.x1 := x;
      z.y1 := y;
      z.eval := eval;
      z.endeval := ceval;
      z.typ := SOUNDTYPE;
      z.removeable := removeable;
    end
    else if stmp = 'SPAWNFLI' then
    begin
      sce.MustGetInteger;
      eval := sce._Integer;
      sce.MustGetInteger;
      ceval := sce._Integer;
      z := @zones[numzones];
      inc(numzones);
      if numzones = MAXZONES then
        MS_Error('Out of mapzones');
      z.eval := eval;
      z.endeval := ceval;
      z.typ := FLITYPE;
    end
    else if stmp = 'FORCELOAD' then
    begin
      sce.MustGetString;
      s := sce._String;
      sce.MustGetInteger;
      x := sce._Integer;
      loadsprites[numloadsprites] := CA_GetNamedNum(s);
      loadspritesn[numloadsprites] := x;
      inc(numloadsprites);
    end
    else if stmp = 'SPAWNAREATRIGGER' then
    begin
      z := @zones[numzones];
      inc(numzones);
      if numzones = MAXZONES then
        MS_Error('Out of mapzones');
      sce.MustGetInteger;
      z.x1 := sce._Integer;
      sce.MustGetInteger;
      z.y1 := sce._Integer;
      sce.MustGetInteger;
      z.x2 := sce._Integer;
      sce.MustGetInteger;
      z.y2 := sce._Integer;
      sce.MustGetInteger;
      z.eval := sce._Integer;
      sce.MustGetInteger;
      z.endeval := sce._Integer;
      sce.MustGetInteger;
      z.removeable := sce._Integer;
      z.typ := AREATRIGGERTYPE;
    end
    else if stmp = 'BACKDROP' then
    begin
      sce.MustGetString;
      s := sce._String;
      eventlump := CA_GetNamedNum(s);
    end
    else if stmp = 'REM' then
    begin
      sce.GetStringEOL;
    end
  end;

  sce.Free;
  sl.Free;

  for x := 0 to numloadsprites - 1 do
  begin
    UpdateWait;
    DemandLoadMonster(loadsprites[x], loadspritesn[x]);
    UpdateWait;
  end;
  seek(cachehandle, infotable[eventlump].filepos + 8);
  x := 256 * 128;
  fread(@backdrop[0], x, 1, cachehandle);
  seek(cachehandle, infotable[eventlump + 1].filepos + 8);
  fread(@backdrop[x], x, 1, cachehandle);
  RunEvent(0, false);
end;

end.

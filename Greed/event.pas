
#include <STDLIB.H>
#include <STRING.H>
#include <STDIO.H>
#include <DOS.H>
#include <FCNTL.H>
#include <IO.H>
#include <TIME.H>
#include 'd_global.h'
#include 'r_public.h'
#include 'r_refdef.h'
#include 'protos.h'
#include 'd_disk.h'
#include 'd_ints.h'
#include 'd_misc.h'

(**** CONSTANTS ****)

#define MAXZONES         255
#define ACTIVATIONTYPE   0
#define MAPZONETYPE      1
#define SPAWNTYPE        2
#define TRIGGERTYPE      3
#define SOUNDTYPE        4
#define FLITYPE          5
#define AREATRIGGERTYPE  6

#define MAXPROCESS       128

#define NORTHWALL        0
#define NORTHFLAGS       1
#define WESTWALL         2
#define WESTFLAGS        3
#define FLOOR            4
#define FLOORFLAGS       5
#define CEILING          6
#define CEILINGFLAGS     7
#define FLOORHEIGHT      8
#define CEILINGHEIGHT    9
#define FLOORDEF         10
#define FLOORDEFFLAGS    11
#define CEILINGDEF       12
#define CEILINGDEFFLAGS  13
#define LIGHTS           14
#define EFFECTS          15
#define SPRITES          16
#define SLOPES           17

#define CHECKERROR(n)                                                               \
   if (result <> n)                                                             \
    MS_Error('Must have %i parms on line %i. %i parms found.',n,line,result);

(**** TYPES ****)

typedef struct
begin
  x1, y1, x2, y2: integer;
  eval, endeval: integer;
  rate, layer, newvalue, stype, removeable: integer;
  type: integer;
   end; zone_t;


(**** VARIABLES ****)

byte   triggers[MAPROWS][MAPCOLS], switches[MAPROWS][MAPCOLS];
int    processes[MAXPROCESS];
  numprocesses, numzones, fliplayed: integer;
extern int cdr_drivenum;
zone_t zones[MAXZONES];
char  *fliname[] := 
begin
  'JETTISON.FLI',
  'TMPL_DIE.FLI',
  'KAAL_DIE.FLI',
   end;
extern bool eventloading;
extern SoundCard SC;


(**** FUNCTIONS ****)

procedure AddProcess(int n);
begin
  i: integer;

  if numprocesses = MAXPROCESS then
  MS_Error('AddProcess: Too many active processes!');
  i := 0;
  while (i<MAXPROCESS) and (processes[i] <> 0) i++;
  if i = MAXPROCESS then
  MS_Error('AddProcess: Process array overflow');
  processes[i] := 1000+n;
  numprocesses++;
  end;


procedure Event(int eval,bool netsend);
begin
  i, j: integer;
  elevobj_t  *elev_p;
  scaleobj_t *sp;
  x, y: integer;
  x1, y1: fixed_t;
  byte      *vrscr;
#ifndef DEMO
  char       name[64];
{$ENDIF}

// FILE *debug;


  if (netsend) and (netmode) then
  NetEvent(eval);
  if eval<256 then
  begin
   player.events[eval] := 1;
   if (eval>200) and ((eval) and (1) = 0) then
    player.events[eval-1] := 0;
    end;
  for (i := 0;i<MAPCOLS;i++)
  for (j := 0;j<MAPROWS;j++)
   if triggers[j][i] = eval then
    triggers[j][i] := 0;
  for (i := 0;i<MAPCOLS;i++)
  for (j := 0;j<MAPROWS;j++)
   if switches[j][i] = eval then
    switches[j][i] := 0;

  for(elev_p := firstelevobj.next;elev_p <> @lastelevobj;elev_p := elev_p.next)
  if (elev_p.eval = eval) and (eval>0) then
  begin
    if elev_p.position = elev_p.floor then
    begin
      elev_p.elevUp := true;
      elev_p.eval := 0;
      elev_p.elevTimer := timecount;
      SoundEffect(SN_ELEVATORSTART,15,(elev_p.mapspot) and (63) shl FRACTILESHIFT,(elev_p.mapspot shr 6) shl FRACTILESHIFT);
    end
    else if elev_p.position = elev_p.ceiling then
    begin
      elev_p.elevDown := true;
      elev_p.eval := 0;
      elev_p.elevTimer := timecount;
      SoundEffect(SN_ELEVATORSTART,15,(elev_p.mapspot) and (63) shl FRACTILESHIFT,(elev_p.mapspot shr 6) shl FRACTILESHIFT);
       end;
     end;

// if (eval = 50)
//   begin 
//   debug := fopen('debug.txt','wt');
//   for (i := 0;i<numzones;i++)
//    fprintf(debug,'zone:%i eval:%i type:%i\n',i,zones[i].eval,zones[i].typ);
//   fclose(debug);
//    end;

  for(i := 0;i<numzones;i++)
  if zones[i].eval = eval then
  begin
    if zones[i].typ = ACTIVATIONTYPE then
    begin
      for(sp := firstscaleobj.next;sp <> @lastscaleobj;sp := sp.next)
       if (sp.active = false) and (sp.moveSpeed) then
       begin
   x := sp.x shr FRACTILESHIFT;
   y := sp.y shr FRACTILESHIFT;
   if (x >= zones[i].x1) and (x <= zones[i].x2) and (y >= zones[i].y1) and (y <= zones[i].y2) then
   begin
     sp.active := true;
     sp.actiontime := timecount+40;
     ActivationSound(sp);
      end;
    end;
       if zones[i].removeable then
       begin
   zones[i].typ := -1;
   zones[i].eval := 0;
    end;
     end
     else if zones[i].typ = MAPZONETYPE then
     begin
       AddProcess(i);
       if zones[i].removeable then
       begin
   zones[i].typ := -1;
   zones[i].eval := 0;
    end;
     end
     else if (zones[i].typ = SPAWNTYPE) and (eval>0) then
     begin
       gameloading := true;
       if (not eventloading) or (zones[i].endeval) then
       begin
   x1 := (zones[i].x1*MAPSIZE+32) shl FRACBITS;
   y1 := (zones[i].y1*MAPSIZE+32) shl FRACBITS;
   SpawnSprite(S_WARP,x1,y1,RF_GetFloorZ(x1,y1)+10*FRACUNIT,0,0,0,true,0);
   sp := SpawnSprite(zones[i].stype,x1,y1,RF_GetFloorZ(x1,y1)+10*FRACUNIT,0,0,0,true,0);
   sp.deathevent := zones[i].endeval;
    end;
       gameloading := false;
       if zones[i].removeable then
       begin
   zones[i].typ := -1;
   zones[i].eval := 0;
    end;
     end
     else if (zones[i].typ = TRIGGERTYPE) and (eval>0) then
     begin
       triggers[zones[i].x1][zones[i].y1] := zones[i].endeval;
       if zones[i].removeable then
       begin
   zones[i].typ := -1;
   zones[i].eval := 0;
    end;
     end
     else if (zones[i].typ = SOUNDTYPE) and (eval>0) then
     begin
       SoundEffect(zones[i].endeval,0,(zones[i].x1*MAPSIZE+32) shl FRACBITS,(zones[i].y1*MAPSIZE+32) shl FRACBITS);
       if zones[i].removeable then
       begin
   zones[i].typ := -1;
   zones[i].eval := 0;
    end;
     end
     else if zones[i].typ = AREATRIGGERTYPE then
     begin
       for (y := zones[i].y1;y<zones[i].y2;y++)
  for (x := zones[i].x1;x<zones[i].x2;x++)
   triggers[x][y] := zones[i].endeval;
       if zones[i].removeable then
       begin
   zones[i].typ := -1;
   zones[i].eval := 0;
    end;
     end
     else if (zones[i].typ = FLITYPE) and (eval>0) and ( not netmode) then
     begin

{$IFDEF DEMO}
       playfli('GREED.BLO',infotable[CA_GetNamedNum(fliname[zones[i].endeval])].filepos);
{$ELSE}

{$IFDEF CDROMGREEDDIR}
       sprintf(name,'%c:\\GREED\\MOVIES\\%s',cdr_drivenum+'A',fliname[zones[i].endeval]);
{$ELSE}
       sprintf(name,'%c:\\MOVIES\\%s',cdr_drivenum+'A',fliname[zones[i].endeval]);
{$ENDIF}
       playfli(name,0);
//       playfli('E:\\PSYBORG\\MAKEDATA\\FLI\\JETTISON.FLI',0);

{$ENDIF}

       font := font1;
       fontbasecolor := 8;
       printx := 160;
       printy := 185;
       case zones[i].endeval  of
       begin
   0:
    FN_PrintCentered('Do not taunt happy fun airlock.');
    break;
   1:
    FN_PrintCentered('Original recipe or extra crispy?');
    break;
   2:
    FN_PrintCentered('Thank you for recycling!');
    break;
    end;
       fliplayed := 1;
       zones[i].eval := 0;
       zones[i].typ := -1;
       player.angst := 0;

       if SC.vrhelmet = 1 then
       begin
   screen := vrscr;
   for (j := 0;j<SCREENHEIGHT;j++)
    ylookup[j] := screen+j*SCREENWIDTH;
    end;

        end;
      end;
  end;


procedure Process;
begin
  count, index, x, y, mapspot: integer;
  zone_t  *z;
  byte    *layer;
  changed: boolean;

  count := numprocesses;
  index := -1;
  do
  begin
   index++;
   count--;
   while (index<MAXPROCESS) and (processes[index] = 0) index++;
   if index = MAXPROCESS then
    MS_Error('Processes: can''t find next process!');
   z := @zones[processes[index]-1000];
   case z.layer  of
   begin
     NORTHWALL:
      layer := northwall;
      break;
     WESTWALL:
      layer := westwall;
      break;
     LIGHTS:
      layer := maplights;
      break;
     FLOORHEIGHT:
      layer := floorheight;
      break;
     CEILINGHEIGHT:
      layer := ceilingheight;
      break;
     EFFECTS:
      layer := mapeffects;
      break;
     CEILING:
      layer := ceilingpic;
      break;
     FLOOR:
      layer := floorpic;
      break;
     default:
      MS_Error('Layer %i is not implemented',z.layer);
      end;
   changed := false;
   for (y := z.y1;y <= z.y2;y++)
    for (x := z.x1;x <= z.x2;x++)
    begin
      mapspot := y*MAPCOLS+x;
      if layer[mapspot]<z.newvalue then
      begin
  if ((int)layer[mapspot]+z.rate>z.newvalue) then
   layer[mapspot] := z.newvalue;
  else
   layer[mapspot] := layer[mapspot] + z.rate;
  changed := true;
      end
      else if layer[mapspot]>z.newvalue then
      begin
  if ((int)layer[mapspot]-z.rate<z.newvalue) then
   layer[mapspot] := z.newvalue;
  else
   layer[mapspot] := layer[mapspot] - z.rate;
  if layer[mapspot]<z.newvalue then
   layer[mapspot] := z.newvalue;
  changed := true;
   end;
       end;
   if not changed then
   begin
     --numprocesses;
     processes[index] := 0;
     if z.endeval then
      Event(z.endeval,false);
      end;
    end; while (count>0);
  end;


procedure LoadScript(int lump,bool newgame);
begin
  char       s[100], *fname, token[100];
  i, j, x, y, eval, line, etype, upper, lower, speed, result, endeval: integer;
  num, val, psprite, total, ceval, def1, def2, x1, y1, x2, y2, removeable: integer;
  FILE       *f;
  elevobj_t  *elevator_p;
  zone_t     *z;
  int        numloadsprites, loadsprites[16], loadspritesn[16], eventlump;

  memset(triggers,0,SizeOf(triggers));
  memset(switches,0,SizeOf(switches));
  memset(zones,0,SizeOf(zones));
  memset(processes,0,SizeOf(processes));
  numprocesses := 0;
  numzones := 0;
  fliplayed := 0;
  numloadsprites := 0;

  memset(secondaries,-1,SizeOf(secondaries));
  memset(primaries,-1,SizeOf(primaries));
  memset(pcount,0,SizeOf(pcount));
  memset(scount,0,SizeOf(scount));
  bonustime := 3150;
  levelscore := 100000;
  player.levelscore := 100000;
  eventlump := CA_GetNamedNum('BACKDROP');

  if (MS_CheckParm('file')) then
  begin
   fname := infotable[lump].nameofs + (char *)infotable;
   strcpy(s,fname);
   i := 0;
   while (i<20) and (s[i] <> '.') and (s[i] <> 0) i++;
   strcpy and (s[i],'.SUX');
   f := fopen(s,'rt');
   if (f = NULL) MS_Error('LoadScript: Error opening %s',s);
    end;
  else
  begin
   close(cachehandle);
   lump := lump-CA_GetNamedNum('MAP')+CA_GetNamedNum('SUX');
   f := fopen('GREED.BLO','rt');
   if (f = NULL) MS_Error('LoadScript: Error reopening GREED.BLO');
   fseek(f,infotable[lump].filepos,SEEK_SET);
    end;

  line := 1;
  while 1 do
  begin
   UpdateWait;
   fscanf(f,' %s ',token);
   if (stricmp(token,'END') = 0) then
    break;
   else if (stricmp(token,'TRIGGER') = 0) then
   begin
     result := fscanf(f,'%i %i %i \n',) and (x,) and (y,) and (eval);
     CHECKERROR(3);
     triggers[x][y] := eval;
   end
   else if (stricmp(token,'AREATRIGGER') = 0) then
   begin
     result := fscanf(f,'%i %i %i %i %i \n',) and (x1,) and (y1,) and (x2,) and (y2,) and (eval);
     CHECKERROR(5);
     for (i := y1;i <= y2;i++)
      for (j := x1;j <= x2;j++)
       triggers[j][i] := eval;
   end
   else if (stricmp(token,'WALLSWITCH') = 0) then
   begin
     result := fscanf(f,'%i %i %i \n',) and (x,) and (y,) and (eval);
     CHECKERROR(3);
     switches[x][y] := eval;
   end
   else if (stricmp(token,'ELEVATOR') = 0) then
   begin
     result := fscanf(f,'%i %i %i %i %i %i %i %i \n',) and (x,) and (y,) and (eval,) and (endeval,) and (etype,) and (upper,) and (lower,) and (speed);
     CHECKERROR(8);
     elevator_p := RF_GetElevator;
     elevator_p.floor := lower;
     elevator_p.mapspot := y*MAPCOLS+x;
     elevator_p.ceiling := upper;
     if etype = 0 then
      elevator_p.position := lower;
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
   else if (stricmp(token,'SPAWNELEVATOR') = 0) then
   begin
     result := fscanf(f,'%i %i %i %i %i %i %i \n',) and (x,) and (y,) and (eval,) and (etype,) and (upper,) and (lower,) and (speed);
     CHECKERROR(7);
     elevator_p := RF_GetElevator;
     elevator_p.floor := lower;
     elevator_p.mapspot := y*MAPCOLS+x;
     elevator_p.ceiling := upper;
     if etype = 0 then
      elevator_p.position := lower;
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
   else if (stricmp(token,'ACTIVATIONZONE') = 0) then
   begin
     z := @zones[numzones];
     ++numzones;
     if numzones = MAXZONES then
      MS_Error('Out of mapzones');
     result := fscanf(f,'%i %i %i %i %i %i \n',) and (z.x1,) and (z.y1,) and (z.x2,) and (z.y2,) and (z.eval,) and (z.removeable);
     CHECKERROR(6);
     z.typ := ACTIVATIONTYPE;
   end
   else if (stricmp(token,'MAPZONE') = 0) then
   begin
     z := @zones[numzones];
     ++numzones;
     if numzones = MAXZONES then
      MS_Error('Out of mapzones');
     result := fscanf(f,'%i %i %i %i %i %i %i %i %i %i \n',) and (z.x1,) and (z.y1,) and (z.x2,) and (z.y2,) and (z.eval,) and (z.endeval,) and (z.layer,) and (z.newvalue,) and (z.rate,) and (z.removeable);
     CHECKERROR(10);
     z.typ := MAPZONETYPE;
   end
   else if (stricmp(token,'BONUSTIME') = 0) then
   begin
     result := fscanf(f,'%i \n',) and (bonustime);
     CHECKERROR(1);
     bonustime := bonustime * 70;
   end
   else if (stricmp(token,'PRIMARY') = 0) then
   begin
     result := fscanf(f,'%i %i %i %i \n',) and (num,) and (val,) and (total,) and (psprite);
     CHECKERROR(4);
     primaries[num*2] := psprite;
     primaries[num*2+1] := val;
     pcount[num] := total;
   end
   else if (stricmp(token,'SECONDARY') = 0) then
   begin
     result := fscanf(f,'%i %i %i %i \n',) and (num,) and (val,) and (total,) and (psprite);
     CHECKERROR(4);
     secondaries[num*2] := psprite;
     secondaries[num*2+1] := val;
     scount[num] := total;
   end
   else if (stricmp(token,'LEVELSCORE') = 0) then
   begin
     result := fscanf(f,'%i \n',) and (levelscore);
     player.levelscore := levelscore;
     CHECKERROR(1);
   end
   else if (stricmp(token,'SPRITE') = 0) then
   begin
     result := fscanf(f,'%i %i %i %i %i %i \n',) and (x,) and (y,) and (num,) and (ceval,) and (def1,) and (def2);
     CHECKERROR(6);
     if (newgame) and (player.difficulty >= 5-def2) and (player.difficulty <= 5-def1) then
     begin
       gameloading := true;
       mapsprites[y*MAPCOLS+x] := num;
       gameloading := false;
        end;
   end
   else if (stricmp(token,'SPAWN') = 0) then
   begin
     result := fscanf(f,'%i %i %i %i %i %i %i %i \n',) and (x,) and (y,) and (eval,) and (num,) and (ceval,) and (def1,) and (def2,) and (removeable);
     CHECKERROR(8);
     if (player.difficulty >= 5-def2) and (player.difficulty <= 5-def1) and (
      (newgame) or ((not newgame) and ((not removeable) or ( not player.events[eval]))))
      begin
       z := @zones[numzones];
       ++numzones;
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
   else if (stricmp(token,'SPAWNTRIGGER') = 0) then
   begin
     result := fscanf(f,'%i %i %i %i %i\n',) and (x,) and (y,) and (eval,) and (ceval,) and (removeable);
     CHECKERROR(5);
     z := @zones[numzones];
     ++numzones;
     if numzones = MAXZONES then
      MS_Error('Out of mapzones');
     z.x1 := x;
     z.y1 := y;
     z.eval := eval;
     z.endeval := ceval;
     z.typ := TRIGGERTYPE;
     z.removeable := removeable;
   end
   else if (stricmp(token,'SPAWNSOUND') = 0) then
   begin
     result := fscanf(f,'%i %i %i %i %i\n',) and (x,) and (y,) and (eval,) and (ceval,) and (removeable);
     CHECKERROR(5);
     z := @zones[numzones];
     ++numzones;
     if numzones = MAXZONES then
      MS_Error('Out of mapzones');
     z.x1 := x;
     z.y1 := y;
     z.eval := eval;
     z.endeval := ceval;
     z.typ := SOUNDTYPE;
     z.removeable := removeable;
   end
   else if (stricmp(token, 'SPAWNFLI') = 0) then
   begin
     result := fscanf(f,'%i %i \n',) and (eval,) and (ceval);
     CHECKERROR(2);
     z := @zones[numzones];
     ++numzones;
     if numzones = MAXZONES then
      MS_Error('Out of mapzones');
     z.eval := eval;
     z.endeval := ceval;
     z.typ := FLITYPE;
   end
   else if (stricmp(token,'FORCELOAD') = 0) then
   begin
     result := fscanf(f,'%s %i \n',s,) and (x);
     CHECKERROR(2);
     loadsprites[numloadsprites] := CA_GetNamedNum(s);
     loadspritesn[numloadsprites] := x;
     numloadsprites++;
   end
   else if (stricmp(token,'SPAWNAREATRIGGER') = 0) then
   begin
     z := @zones[numzones];
     ++numzones;
     if numzones = MAXZONES then
      MS_Error('Out of mapzones');
     result := fscanf(f,'%i %i %i %i %i %i %i \n',) and (z.x1,) and (z.y1,) and (z.x2,) and (z.y2,) and (z.eval,) and (z.endeval,) and (z.removeable);
     CHECKERROR(7);
     z.typ := AREATRIGGERTYPE;
   end
   else if (stricmp(token,'BACKDROP') = 0) then
   begin
     result := fscanf(f,'%s \n',s);
     CHECKERROR(1);
     eventlump := CA_GetNamedNum(s);
      end;
   else while (fgetc(f) <> '\n') ;
   line++;
    end;
  fclose(f);
  if (not MS_CheckParm('file')) then
  begin
   if ((cachehandle := open('GREED.BLO',O_RDONLY) or (O_BINARY)) = -1) then
    MS_Error('LoadScript: Can''t open GREED.BLO!');
    end;
  for (x := 0;x<numloadsprites;x++)
  begin
   UpdateWait;
   DemandLoadMonster(loadsprites[x],loadspritesn[x]);
   UpdateWait;
    end;
  lseek(cachehandle,infotable[eventlump].filepos+8,SEEK_SET);
  read(cachehandle,backdrop,256*128);
  lseek(cachehandle,infotable[eventlump+1].filepos+8,SEEK_SET);
  read(cachehandle,backdrop+256*128,256*128);
  Event(0,false);
  end;

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

#include <STDIO.H>
#include <STRING.H>
#include <DOS.H>
#include <CONIO.H>
#include <STDLIB.H>
#include 'd_global.h'
#include 'd_ints.h'
#include 'd_misc.h'
#include 'r_public.h'
#include 'protos.h'
#include 'd_disk.h'
#include 'r_refdef.h'

(**** CONSTANTS ****)

#define CMD_SEND          1
#define CMD_GET           2
#define GREEDCOM_ID       $C7C7C7C7L
#define NETIPX            1
#define NETSERIAL         2
#define NETMODEM          3

#define INITEVENTID       1
#define PLAYEREVENTID     2
#define SPAWNEVENTID      3
#define QUITEVENTID       4
#define DOOREVENTID       5
#define FRAGEVENTID       6
#define NEWPLAYEREVENTID  7
#define ITEMEVENTID       8
#define BONUSEVENTID      9
#define PAUSEEVENTID      10
#define UNPAUSEEVENTID    11
#define TRIGGEREVENTID    12
#define SOUNDEVENTID      13
#define JAMMEREVENTID     14
#define EVENTEVENTID      15
#define MESSAGEEVENTID    16

#define QUESIZE        4095

#define PEL_WRITE_ADR       $3c8
#define PEL_DATA            $3c9
#define I_ColorBlack(r,g,b) outp(PEL_WRITE_ADR,0); \
          outp(PEL_DATA,r);      \
          outp(PEL_DATA,g);      \
          outp(PEL_DATA,b)

#define NETINT // send data on network


(**** TYPES ****)

typedef struct
begin
  id: integer;
  playerid: integer;
  found: integer;
  start: integer;
  char    netname[13];
  map: integer;
  difficulty: integer;
   end; ievent_t; // initialization

typedef struct
begin
  id: integer;
  playerid: integer;
  value: integer;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  zadj: fixed_t;
  angle: integer;
  angle2: integer;
  active: integer;
  spawnid: integer;
   end; sevent_t; // spawn

typedef struct
begin
  id: integer;
  playerid: integer;
   end; qevent_t; // quit game

typedef struct
begin
  id: integer;
  playerid: integer;
  x, y: fixed_t;
  angle: integer;
   end; devent_t; // door open (by player) / trigger flipped

typedef struct
begin
  id: integer;
  playerid: integer;
  bulletid: integer;
   end; fevent_t; // frag

typedef struct
begin
  id: integer;
  playerid: integer;
  time, score: integer;
  tilex, tiley: integer;
  num: integer;
   end; bevent_t; // bonus item spawn

typedef struct
begin
  id: integer;
  playerid: integer;
  tilex, tiley, mapspot: integer;
  type, chartype: integer;
   end; ipevent_t; // item pickup

typedef struct
begin
  id: integer;
  playerid: integer;
  x, y: fixed_t;
  effect, variation: integer;
   end; eevent_t; // sound effect

typedef struct
begin
  id: integer;
  playerid: integer;
  char    message[30];
   end; mevent_t;


enum  begin UART_8250, UART_16550 end; uart_type;

typedef struct
begin
  long head, tail;    // bytes are put on head and pulled from tail
  byte data[QUESIZE+1];
  end; que_t;

typedef struct
begin
  que_t in;
  que_t out;
  short uart, uarttype, irqintnum;
  short intseg, intofs;
  short rsent, rreceived;
  short psent, preceived;
  end; ques_t;


(**** VARIABLES ****)

pevent_t      *pevent;
sevent_t      *sevent;
ievent_t      *ievent;
qevent_t      *qevent;
devent_t      *devent;
fevent_t      *fevent;
bevent_t      *bevent;
ipevent_t     *ipevent;
eevent_t      *eevent;
mevent_t      *mevent;
greedcom_t    *greedcom;
char          msg[60];
scaleobj_t    *playersprites[MAXPLAYERS], *sprite_p, *sprite2_p, *temp_p;
pevent_t      playerdata[MAXPLAYERS];
char          netnames[MAXPLAYERS][13];
  playernum := 1, netpaused, netwarpjamtime: integer;
  netwarpjammer: boolean;
int           playermapspot[MAXPLAYERS], pmapspot, oldsprites[MAXPLAYERS];
ques_t        *que;
  uart, irqintnum, maxcount: integer;
  pseg, pofs, rseg, rofs: integer;
int           fragcount[MAXPLAYERS];

extern SoundCard SC;


(**** FUNCTIONS ****)

void SpawnNewPlayer
begin
  sprite_p := RF_GetSprite;
  playersprites[pevent.playerid] := sprite_p;
  sprite_p.rotate := rt_eight;
  sprite_p.basepic := CA_GetNamedNum(charnames[pevent.chartype]);
  DemandLoadMonster(sprite_p.basepic,48);
  sprite_p.scale := 1;
  sprite_p.startpic := sprite_p.basepic;
  sprite_p.intelligence := 255;
  sprite_p.x := pevent.x;
  sprite_p.y := pevent.y;
  sprite_p.z := pevent.z;
  sprite_p.angle := pevent.angle;
  sprite_p.type := S_NETPLAYER;
  sprite_p.hitpoints := 500;
  sprite_p.height := 60 shl FRACBITS;
  pmapspot := (sprite_p.y shr FRACTILESHIFT)*MAPCOLS+(sprite_p.x shr FRACTILESHIFT);
  playermapspot[pevent.playerid] := pmapspot;
  if mapsprites[pmapspot] = 0 then
  mapsprites[pmapspot] := SM_NETPLAYER;
  end;


procedure NetInit(void *addr);
begin
  printf('Multiplayer:\n');
  greedcom := (greedcom_t *)addr;
  if (greedcom.id <> GREEDCOM_ID) MS_Error('Invalid ComData Address not  ID := $%X',greedcom.id);
  printf('\tPlayers := %i\n',greedcom.numplayers);
  playernum := greedcom.consoleplayer;
  printf('\tYou are player #%i\n',playernum+1);
  printf('\tNetMode := ');
  if (greedcom.nettype = NETIPX) printf('IPX Net');
  else if (greedcom.nettype = NETSERIAL) printf('Serial');
  else if (greedcom.nettype = NETMODEM) printf('Modem');
  else MS_Error('Unknown net type!');
  printf('\n');
  pevent := (pevent_t *)greedcom.data;
  sevent := (sevent_t *)greedcom.data;
  ievent := (ievent_t *)greedcom.data;
  qevent := (qevent_t *)greedcom.data;
  devent := (devent_t *)greedcom.data;
  fevent := (fevent_t *)greedcom.data;
  bevent := (bevent_t *)greedcom.data;
  ipevent := (ipevent_t *)greedcom.data;
  eevent := (eevent_t *)greedcom.data;
  mevent := (mevent_t *)greedcom.data;
  end;


procedure PlayerCommand;


procedure NetWaitStart;
begin
  int     players[MAXPLAYERS], found, playersfound[MAXPLAYERS], ready, i;
  timeout, waittime: integer;

  INT_TimerHook(NULL);
  StartWait;
  memset(players,0,sizeof(players));
  memset(playersfound,0,sizeof(playersfound));
  strncpy(netnames[playernum],SC.netname,12);
  if netnames[playernum][10] = ' ' then
  begin
   i := 10;
   while (i>0) and (netnames[playernum][i] = ' ') do
   begin
     netnames[playernum][i] := 0;
     i--;
      end;
    end;
  players[playernum] := 1; // found ourself
  found := 1;
  ready := 0;
  timeout := timecount+42000; // 10 minute wait
  newascii := false;
  waittime := timecount+70;
  while 1 do
  begin
   UpdateWait;
   if timecount>timeout then
    MS_Error('Multiplayer synch time-out error');
   if (newascii) and (lastascii = 27) then
    MS_Error('Multiplay Cancelled');
   newascii := false;
   if timecount>waittime then
   begin
     found := 0;
     for(i := 0;i<greedcom.numplayers;i++)
      if (players[i]) found++;                   // count how many we've found
     playersfound[playernum] := found;
     greedcom.command := CMD_SEND;
     greedcom.remotenode := MAXPLAYERS;           // broadcast
     greedcom.datalength := sizeof(ievent_t);
     ievent.id := INITEVENTID;
     ievent.playerid := playernum;                 // tell who we are
     ievent.found := found;                        // tell how many we've found
     ievent.start := ready;                        // player 0 tells when to start
     ievent.map := player.map;
     ievent.difficulty := player.difficulty;
     strncpy(ievent.netname,netnames[playernum],12);
     NETINT;
     waittime := timecount + 140;
      end;
   if ievent.start = greedcom.numplayers then
    break;
   greedcom.command := CMD_GET;
   NETINT;
   if greedcom.remotenode = -1 then
    continue; // no broadcasts
    if ievent.id <> INITEVENTID then
    continue; // wrong packet id not 
   if (greedcom.nettype <> NETIPX) and (ievent.start = greedcom.numplayers) then
    break; // we can start now

   if ievent.playerid = 0 then
    player.difficulty := ievent.difficulty;

   if ievent.map <> player.map then
    MS_Error('Player #%i is playing a different map!',ievent.playerid);

   players[ievent.playerid] := 1;                  // found new player
   playersfound[ievent.playerid] := ievent.found; // how many they've found
   strncpy(netnames[ievent.playerid],ievent.netname,12);
   if (playernum = 0) // player 0 checks for readiness
   begin
     ready := 0;
     for(i := 0;i<greedcom.numplayers;i++)
      if playersfound[i] = greedcom.numplayers then
       ready++; // check everybody
      end;
    end;
  timecount := 0;
  greedcom.maxusage := 0;
  EndWait;
  NetNewPlayerData;
  INT_TimerHook(PlayerCommand);
  if (greedcom.nettype <> NETIPX) and (greedcom.consoleplayer = 0) then
  timecount := 19;
  NetGetData;
  end;


procedure NetGetData;
begin
  static int i, angle, angleinc;

  do
  begin
  (*  if (greedcom.nettype = NETIPX) and (greedcom.maxusage = 25)
    MS_Error('Network Overload\n'
       'Possible solutions:\n'
       ' 1. increase the speed of this machine\n'
       ' 2. remove other non-game machines from the net\n'
       ' 3. reduce number of players in game\n'); *)
   greedcom.command := CMD_GET;
   NETINT;
   if (greedcom.remotenode = -1) exit;
   if (pevent.playerid = playernum) continue;
   case pevent.id  of
   begin
     PLAYEREVENTID:
      sprite_p := playersprites[pevent.playerid];
      if sprite_p = NULL then
       continue;
      sprite_p.x := pevent.x;
      sprite_p.y := pevent.y;
      sprite_p.z := pevent.z-pevent.height;
      sprite_p.angle := pevent.angle;
      sprite_p.hitpoints := 500;
      pmapspot := playermapspot[pevent.playerid];
      if mapsprites[pmapspot] = SM_NETPLAYER then
       mapsprites[pmapspot] := 0;
      pmapspot := (sprite_p.y shr FRACTILESHIFT)*MAPCOLS+(sprite_p.x shr FRACTILESHIFT);
      if mapsprites[pmapspot] = 0 then
       mapsprites[pmapspot] := SM_NETPLAYER;
      playermapspot[pevent.playerid] := pmapspot;

      if (pevent.status = 1)  // hit
      begin
  sprite_p.basepic := sprite_p.startpic+32;
  sprite_p.modetime := timecount+12;
      end
      else if (pevent.status = 2) // firing
      begin
  sprite_p.basepic := sprite_p.startpic+24;
  sprite_p.modetime := timecount+12;
  playerdata[pevent.playerid].x := -1; // so it draws the walk frame
   end;

      if timecount>sprite_p.modetime then
      begin
  if (playerdata[pevent.playerid].x <> pevent.x) or (playerdata[pevent.playerid].y <> pevent.y) then
  begin
    if sprite_p.movemode = 3 then
    begin
      sprite_p.movemode := 0;
      sprite_p.basepic := sprite_p.startpic;
    end
    else if sprite_p.movemode = 2 then
    begin
      sprite_p.basepic := sprite_p.startpic + 8; // midstep
      ++sprite_p.movemode;
       end;
    else
    begin
      ++sprite_p.movemode;
      sprite_p.basepic := sprite_p.startpic+sprite_p.movemode*8;
       end;
     end;
  sprite_p.modetime := timecount+12;
   end;

      memcpy and (playerdata[pevent.playerid],pevent,sizeof(pevent_t));

      if pevent.holopic then
      begin
//  if (MS_RndT>253)
//    begin 
//    sprite_p.basepic := sprite_p.startpic;
//    sprite_p.scale := 1;
//    sprite_p.rotate := rt_eight;
//     end;
//  else
//    begin 
    sprite_p.basepic := pevent.holopic;
    sprite_p.scale := pevent.holoscale;
    sprite_p.rotate := rt_one;
//     end;
   end;

      if pevent.specialeffect = SE_INVISIBILITY then
       sprite_p.specialtype := st_transparent;
      else
       sprite_p.specialtype := 0;

      break;
     SPAWNEVENTID:
      gameloading := true;
      if sevent.value = S_BULLET18 then
      begin
  angleinc := ANGLES/12;
  angle := 0;
  for(i := 0,angle := 0;i<12;i++,angle+:= angleinc)
   SpawnSprite(sevent.value,sevent.x,sevent.y,sevent.z,sevent.zadj,angle,sevent.angle2,sevent.active,sevent.spawnid);
      end
      else if sevent.value = S_SOULBULLET then
      begin
  angleinc := ANGLES/16;
  angle := 0;
  for(i := 0,angle := 0;i<16;i++,angle+:= angleinc)
   SpawnSprite(sevent.value,sevent.x,sevent.y,sevent.z,sevent.zadj,angle,sevent.angle2,sevent.active,sevent.spawnid);
   end;
      else SpawnSprite(sevent.value,sevent.x,sevent.y,sevent.z,sevent.zadj,sevent.angle,sevent.angle2,sevent.active,sevent.spawnid);
      gameloading := false;
      break;
     DOOREVENTID:
      TryDoor(devent.x,devent.y);
      break;
     ITEMEVENTID:
      mapsprites[ipevent.mapspot] := ipevent.type;
      CheckItems(ipevent.tilex,ipevent.tiley,false,ipevent.chartype);
      mapsprites[ipevent.mapspot] := 0;
      break;
     SOUNDEVENTID:
      SoundEffect(eevent.effect,eevent.variation,eevent.x,eevent.y);
      break;
     BONUSEVENTID:
      if BonusItem.score>0 then
      begin
  for (sprite_p := firstscaleobj.next; sprite_p <> @lastscaleobj;sprite_p := sprite_p.next)
   if sprite_p.type = S_BONUSITEM then
   begin
     RF_RemoveSprite(sprite_p);
     mapsprites[BonusItem.mapspot] := 0;
     break;
      end;
   SpawnSprite(S_WARP,(BonusItem.tilex*MAPSIZE+32) shl FRACBITS,(BonusItem.tiley*MAPSIZE+32) shl FRACBITS,0,0,0,0,false,0);
   end;
      do
      begin
  BonusItem.tilex := bevent.tilex;
  BonusItem.tiley := bevent.tiley;
  BonusItem.mapspot := BonusItem.tiley*MAPCOLS + BonusItem.tilex;
   end; while (floorpic[BonusItem.mapspot] = 0) or (mapsprites[BonusItem.mapspot]>0) or (mapeffects[BonusItem.mapspot]) and (FL_FLOOR);
      BonusItem.score := bevent.score;
      BonusItem.time := bevent.time;
      BonusItem.num := bevent.num;
      BonusItem.name := randnames[BonusItem.num];
      BonusItem.sprite := SpawnSprite(S_BONUSITEM,(BonusItem.tilex*MAPSIZE+32) shl FRACBITS,(BonusItem.tiley*MAPSIZE+32) shl FRACBITS,0,0,0,0,false,0);
      SpawnSprite(S_WARP,(BonusItem.tilex*MAPSIZE+32) shl FRACBITS,(BonusItem.tiley*MAPSIZE+32) shl FRACBITS,0,0,0,0,false,0);
      BonusItem.sprite.basepic := BonusItem.sprite.basepic + BonusItem.num;
      oldgoalitem := -1;
      writemsg('Bonus item located!');
      break;
     TRIGGEREVENTID:
      CheckHere(false,devent.x,devent.y,devent.angle);
      break;
     FRAGEVENTID:
      if fevent.bulletid<MAXPLAYERS then
      begin
  oldgoalitem := -1;
  fragcount[fevent.bulletid]++;
  goalitem := fevent.bulletid+1;
   end;
      if playernum = fevent.bulletid then
      begin
  player.frags[fevent.playerid]++;
  addscore(5000);
  sprintf(msg,'Fragged %s not  %i of %i',netnames[fevent.playerid],player.frags[fevent.playerid],fragcount[playernum]);
  writemsg(msg);
      end
      else if fevent.bulletid<MAXPLAYERS then
      begin
  sprintf(msg,'%s fragged %s.',netnames[fevent.bulletid],netnames[fevent.playerid]);
  writemsg(msg);
   end;
      else
      begin
  sprintf(msg,'%s was killed.',netnames[fevent.playerid]);
  writemsg(msg);
   end;

      sprite_p := playersprites[fevent.playerid];
      if (sprite_p.startpic = CA_GetNamedNum(charnames[0])) then
      begin
  gameloading := true;  // do not transmit
  sprite2_p := SpawnSprite(S_TIMEMINE,sprite_p.x,sprite_p.y,0,0,0,0,false,playernum);
  gameloading := false;
  sprite2_p.basepic := sprite_p.startpic+40;
  sprite_p.basepic := sprite_p.startpic+40;
  sprite2_p.scale := 1;
  sprite_p.animation := 0 + (0 shl 1) + (0 shl 5) + (0 shl 9) + ANIM_SELFDEST;
   end;
      else
      begin
  sprite_p.basepic := sprite_p.startpic + 40;
  sprite_p.animation :=  0 + (0 shl 1) + (8 shl 5) + ((6+(MS_RndT) and (3)) shl 9);
   end;
      sprite_p.rotate := rt_one;
      sprite_p.heat := 0;
      sprite_p.active := false;
      sprite_p.moveSpeed := 0;
      sprite_p.hitpoints := 0;
      sprite_p.intelligence := 0;
      mapsprites[playermapspot[fevent.playerid]] := 0;
      playersprites[fevent.playerid] := NULL;
      break;
     NEWPLAYEREVENTID:
      SpawnNewPlayer; // new player
      break;
     PAUSEEVENTID:
      netpaused := true;
      break;
     UNPAUSEEVENTID:
      netpaused := false;
      break;
     JAMMEREVENTID:
      for (sprite_p := firstscaleobj.next; sprite_p <> @lastscaleobj;sprite_p := sprite_p.next)
       if (sprite_p.type = S_GENERATOR) or ((sprite_p.type >= S_GENSTART) and (sprite_p.type <= S_GENEND)) then
       begin
   mapsprites[(sprite_p.y shr FRACTILESHIFT)*MAPCOLS + (sprite_p.x shr FRACTILESHIFT)] := 0;
   temp_p := sprite_p;
   sprite_p := sprite_p.next;
   RF_RemoveSprite(temp_p);
    end;
       else
  sprite_p := sprite_p.next;
      sprintf(msg,'%s activated Warp Jammer!',netnames[qevent.playerid]);
      writemsg(msg);
      netwarpjammer := true;
      netwarpjamtime := timecount+70*60;
      break;
     EVENTEVENTID:
      Event(fevent.bulletid,false);
      break;
     QUITEVENTID:
      sprintf(msg,'%s has left the game!',netnames[qevent.playerid]);
      writemsg(msg);
      break;
     MESSAGEEVENTID:
      sprintf(msg,'%s: %s',netnames[mevent.playerid],mevent.message);
      writemsg(msg);
      SoundEffect(SN_NEXUS,0,player.x,player.y);
      break;
      end;
   end; while (1);
  end;


procedure NetSendPlayerData;
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS; // broadcast
  greedcom.datalength := sizeof(pevent_t);
  pevent.playerid := playernum;
  pevent.id := PLAYEREVENTID;
  pevent.x := player.x;
  pevent.y := player.y;
  pevent.z := player.z;
  pevent.angle := player.angle;
  pevent.angst := player.angst;
  pevent.height := player.height;
  pevent.chartype := player.chartype;
  pevent.status := player.status;
  pevent.holopic := player.holopic;
  pevent.holoscale := player.holoscale;
  pevent.specialeffect := specialeffect;
  player.status := 0;
  memcpy and (playerdata[playernum],pevent,sizeof(pevent_t));
  NETINT;
  end;


procedure NetNewPlayerData;
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS; // broadcast
  greedcom.datalength := sizeof(pevent_t);
  pevent.playerid := playernum;
  pevent.id := NEWPLAYEREVENTID;
  pevent.x := player.x;
  pevent.y := player.y;
  pevent.z := player.z;
  pevent.angle := player.angle;
  pevent.angst := player.angst;
  pevent.height := player.height;
  pevent.chartype := player.chartype;
  pevent.status := player.status;
  pevent.holopic := player.holopic;
  pevent.specialeffect := specialeffect;
  player.status := 0;
  memcpy and (playerdata[playernum],pevent,sizeof(pevent_t));
  NETINT;
  end;


procedure NetSendSpawn(int value, fixed_t x, fixed_t y, fixed_t z,fixed_t zadj,int angle,int angle2,bool active,int spawnid);
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS; // broadcast
  greedcom.datalength := sizeof(sevent_t);
  sevent.id := SPAWNEVENTID;
  sevent.value := value;
  sevent.x := x;
  sevent.y := y;
  sevent.z := z;
  sevent.zadj := zadj;
  sevent.angle := angle;
  sevent.angle2 := angle2;
  sevent.active := active;
  sevent.spawnid := spawnid;
  sevent.playerid := playernum;
  NETINT;
  end;


procedure NetQuitGame;
begin
  NetDeath(255);
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := sizeof(qevent_t);
  qevent.id := QUITEVENTID;
  qevent.playerid := playernum;
  NETINT;
  end;


procedure NetOpenDoor(fixed_t x,fixed_t y);
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := sizeof(devent_t);
  devent.id := DOOREVENTID;
  devent.playerid := playernum;
  devent.x := x;
  devent.y := y;
  NETINT;
  end;
procedure netstub;
begin
  end;


procedure NetDeath(int bulletid);
begin
  char str1[50];

  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := sizeof(fevent_t);
  fevent.id := FRAGEVENTID;
  fevent.playerid := playernum;
  fevent.bulletid := bulletid;
  if fevent.bulletid<MAXPLAYERS then
  begin
   oldgoalitem := -1;
   fragcount[bulletid]++;
   goalitem := bulletid+1;
   sprintf(str1,'You were fragged by %s!',netnames[fevent.bulletid]);
   writemsg(str1);
    end;
  NETINT;
  end;


procedure NetItemPickup(int x,int y);
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := sizeof(ipevent_t);
  ipevent.id := ITEMEVENTID;
  ipevent.playerid := playernum;
  ipevent.tilex := x;
  ipevent.tiley := y;
  ipevent.mapspot := y*MAPCOLS+x;
  ipevent.type := mapsprites[ipevent.mapspot];
  ipevent.chartype := player.chartype;
  NETINT;
  end;


procedure NetBonusItem;
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := sizeof(bevent_t);
  bevent.id := BONUSEVENTID;
  bevent.playerid := playernum;
  bevent.time := BonusItem.time;
  bevent.score := BonusItem.score;
  bevent.tilex := BonusItem.tilex;
  bevent.tiley := BonusItem.tiley;
  bevent.num := BonusItem.num;
  NETINT;
  end;


procedure NetGetClosestPlayer(int sx,int sy);
begin
  mindist, minplayer, dist: integer;
  i, px, py: integer;

  minplayer := -1;
  mindist := $7FFFFFFFL;
  for(i := 0;i<greedcom.numplayers;i++)
  if (playerdata[i].angst) and (playerdata[i].specialeffect <> SE_INVISIBILITY) then
   // gotta be alive) and (visible
   begin
    px := playerdata[i].x shr FRACTILESHIFT;
    py := playerdata[i].y shr FRACTILESHIFT;
    dist := (px-sx)*(px-sx) + (py-sy)*(py-sy);
    if dist<mindist then
    begin
      mindist := dist;
      minplayer := i;
       end;
     end;
  targx := playerdata[minplayer].x;
  targy := playerdata[minplayer].y;
  targz := playerdata[minplayer].z;
  end;


procedure NetPause;
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := sizeof(qevent_t);
  qevent.id := PAUSEEVENTID;
  qevent.playerid := playernum;
  NETINT;
  end;


procedure NetUnPause;
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := sizeof(qevent_t);
  qevent.id := UNPAUSEEVENTID;
  qevent.playerid := playernum;
  NETINT;
  end;


procedure NetCheckHere(fixed_t centerx,fixed_t centery,int angle);
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := sizeof(devent_t);
  devent.id := TRIGGEREVENTID;
  devent.playerid := playernum;
  devent.x := centerx;
  devent.y := centery;
  devent.angle := angle;
  NETINT;
  end;


procedure NetSoundEffect(int n,int variation,fixed_t x,fixed_t y);
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := sizeof(eevent_t);
  eevent.id := SOUNDEVENTID;
  eevent.playerid := playernum;
  eevent.x := x;
  eevent.y := y;
  eevent.variation := variation;
  eevent.effect := n;
  NETINT;
  end;


procedure NetWarpJam;
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := sizeof(qevent_t);
  qevent.id := JAMMEREVENTID;
  qevent.playerid := playernum;
  NETINT;
  end;


procedure NetEvent(int n);
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := sizeof(fevent_t);
  fevent.id := EVENTEVENTID;
  fevent.playerid := playernum;
  fevent.bulletid := n;
  NETINT;
  end;


procedure NetSendMessage(char *s);
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := sizeof(mevent_t);
  mevent.id := MESSAGEEVENTID;
  mevent.playerid := playernum;
  strcpy(mevent.message,s);
  NETINT;
  end;

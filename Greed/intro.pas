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

unit intro;

interface

const
  VERSION = '1.000.041';

const
  charinfo: array[0..4, 0..26] of string[40] = (  // character profiles
  (
    'CYBORG',
    '.',
    'NAME: TOBIAS LOCKE',
    '.',
    'RACE: HOMO SAPIEN',
    '.',
    'AGE: 27',
    '.',
    'HEIGHT: 6''1''''',
    '.',
    'WEIGHT: 450 LBS',
    '(INCLUDING POWERED LIMBS)',
    '.',
    'BIO: CYBERNETICALLY ENHANCED HUMAN',
    '.',
    'BACKGROUND: BORN INTO THE LOTHLOS',
    'CASTE OF HUNTERS, TOBIAS WAS',
    'REBUILT AT THE AGE OF 22 FOLLOWING',
    'HIS INITIATION RITE INTO THE ELITE',
    'LOTH MAL ESCH, OR "SCAVENGER',
    'BROOD."',
    '     HE WAS SOON RECRUITED BY THE',
    'GREEN QUARTER HUNT SQUAD AND',
    'ASSIGNED TO THE SCAVENGER VESSEL,',
    'RED HUNTER, FOR COMPETITION IN THE',
    'GAME.',
    '.'
  ),
  (
    'LIZARD MAN',
    '.',
    'NAME: XITH',
    '.',
    'RACE: SAPIOSAURUS ROBUSTUS',
    '.',
    'AGE: 43',
    '.',
    'HEIGHT: 4''11''''',
    '.',
    'WEIGHT: 100 LBS',
    '.',
    'BIO: ZOLLEESIAN LIZARD MAN',
    '.',
    'BACKGROUND: XITH WAS BORN BETWEEN',
    'LIZARD CLANS AND FROM BIRTH HAS',
    'BEEN AN OUTCAST AMONG HIS TRIBES.',
    'HE ENTERED THE GAME HOPING TO USE',
    'THE LIGHTNING QUICK SPEED INHERENT',
    'IN HIS RACE TO VINDICATE HIMSELF.',
    '     XITH WAS TRADED TO GREEN',
    'QUARTER AND SUBSEQUENTLY PLACED',
    'ABOARD THE RED HUNTER.',
    '.',
    '.',
    '.',
    '.'
  ),
  (
    'MOOMAN',
    '.',
    'NAME: ALDUS KADEN',
    '.',
    'RACE: BRAHMAN ERECTUS',
    '.',
    'AGE: 35',
    '.',
    'HEIGHT: 7''0''''',
    '.',
    'WEIGHT: 375 LBS',
    '.',
    'BIO: BORN ON ELTHO III',
    '.',
    'BACKGROUND: THE BOVINARIAN OR',
    '"MOOMEN" AS RIMWARD WORLDS CALL',
    'THEM, HAVE BEEN FASCINATED BY THE',
    'GAME FROM THE BEGINNING.  HAVING',
    'PARTICIPATED IN THE INSURRECTION',
    'AT ALPHA PRAM AND THEN IN THE',
    'FAILED COUP AT SARTUS I, ALDUS',
    'KADEN WENT INTO THE ONLY',
    'PROFESSION LEFT TO HIM.',
    '     THE GREEN QUARTER TOOK HIM',
    'IMMEDIATELY AND AFTER ONLY THREE',
    'HUNTS HE WAS TRANSFERED TO THE',
    'RED HUNTER UNDER TOBIAS''S COMMAND.'
  ),
  (
    'MUTANT',
    '.',
    'NAME: SPECIMEN 7',
    '.',
    'RACE: HOMO DEGENEROUS',
    '.',
    'AGE: ?',
    '.',
    'HEIGHT: 5''10'''' (WHEN STANDING)',
    '.',
    'WEIGHT: 250 LBS',
    '.',
    'BIO: HUMAN VARIANT ENGINEERED BY',
    'JANEX CORP. GEN-TECH DIVISION.',
    '.',
    'BACKGROUND: AN ERROR IN OXYGEN',
    'FEEDS TO THE BIRTHING TANKS',
    'RESULTED IN ABNORMAL INTELLIGENCE',
    'LEVELS IN HIS STRAIN.  ESCAPING THE',
    'STERILIZATION THAT FOLLOWED',
    'SPECIMEN 7 IS THE ONLY REMAINING',
    'MEMBER OF HIS RACE.',
    '     HE JOINED GREEN QUARTER HUNT',
    'SQUAD WHEN THEY REALIZED HIS',
    'POTENTIAL AS A HUNTER.',
    '.',
    '.'
  ),
  (
    'DOMINATRIX',
    '.',
    'NAME: THEOLA NOM',
    '.',
    'RACE: HOMO MAJESTRIX',
    '.',
    'AGE: 22',
    '.',
    'HEIGHT: 5''11''''',
    '.',
    'WEIGHT: 140 LBS',
    '.',
    'BIO: HUMAN VARIANT ENGINEERED BY',
    'JANEX CORP. GEN-TECH DIVISION.',
    '.',
    'BACKGROUND: INITIALLY ENGINEERED',
    'BY JANEX FOR SALE AS A ''HOME',
    'ENTERTAINMENT SYSTEM'', THEOLA',
    'FIRST USED HER PREVIOUSLY LATENT',
    'PSYCHIC ABILITIES ON HER FIRST',
    'OWNER.  THEY NEVER FOUND THE BODY.',
    '     SINCE THEN, SHE HAS BEEN A',
    'FUGITIVE FROM CORE LAW.  RECENTLY',
    'SHE HAS SOUGHT REFUGE WITHIN THE',
    'RED HUNTER HUNT SQUAD.',
    '.',
    '.'
  )
  );

(**** VARIABLES ****)
var
  colors: array[0..767] of byte;
  nextchar: boolean;
  nointro, nobriefing: boolean;


(**** FUNCTIONS ****)

function loadscreen(const s: string): boolean;

procedure DoIntroMenu;

procedure Wait(time: integer; sleeptime: integer = 0);

procedure startup;

implementation

uses
  g_delphi,
  i_windows,
  i_video,
  constant,
  d_font,
  d_ints_h,
  d_misc,
  d_video,
  d_disk,
  d_ints,
  display,
  m_defs,
  menu,
  modplay,
  net,
  protos_h,
  playfli,
  raven,
  r_public_h,
  r_public,
  r_render,
  timer,
  utils;

function loadscreen(const s: string): boolean;
var
  l: Ppic_t;
  pal: PByteArray;
  i: integer;
begin
  i := CA_CheckNamedNum(s);
  if i < 0 then
  begin
    result := false;
    exit;
  end;
  l := CA_CacheLump(i);
  R_ClearRenderBuffer;
  VI_DrawPicSolidUntranslated(0, 0, l);
  CA_FreeLump(i);
  pal := CA_CacheLump(i + 1);
  memcpy(@colors, pal, 768);
  CA_FreeLump(i + 1);
  for i := 0 to 767 do
    colors[i] := colors[i] * 4;
  result := true;
end;


procedure Wait(time: integer; sleeptime: integer = 0);
var
  t: integer;
begin
  t := timecount + time;
  while not CheckTime(timecount, t) do
  begin
    I_PeekAndDisplatch;
    I_Sleep(sleeptime);
  end;
end;


procedure ShowPortrait(const n: integer);
var
  str1: string;
  i: integer;
begin
  sprintf(str1, 'CHAR%d', [n]);
  loadscreen(str1);
  VI_FadeIn(0, 256, @colors, 48);
  font := font1;

  nextchar := false;
  for i := 0 to 26 do
  begin
    if not nextchar then
      UpdateSound;
    fontbasecolor := 0;
    while fontbasecolor < 9 do
    begin
      if charinfo[n - 1][i][1] <> '.' then
      begin
        printx := 144;
        printy := 19 + 6 * i;
        str1 := charinfo[n - 1][i];
        FN_RawPrint3(str1);
        if not nextchar or activatemenu then
          Wait(2, 1);
      end;
      inc(fontbasecolor);
    end;
    if activatemenu then
    begin
      DoIntroMenu;
      if quitgame or gameloaded then
        exit;
    end;
  end;

  nextchar := false;

  for i := 0 to 49 do
  begin
    UpdateSound;
    Wait(35, 1);
    if activatemenu then
    begin
      DoIntroMenu;
      if quitgame or gameloaded then
        exit;
    end;
    if nextchar then
    begin
      nextchar := false;
      break;
    end;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
end;


procedure IntroCommand;
begin
  if (keyboard[SC_ESCAPE] = 1) or (keyboard[SC_ENTER] = 1) then
  begin
    eat_key(SC_ESCAPE);
    eat_key(SC_ENTER);
    activatemenu := true;
    keyboardDelay := timecount + ACTIVATEMENUDELAY;
  end;
  if (keyboard[SC_SPACE] = 1) then
  begin
    eat_key(SC_SPACE);
    nextchar := true;
    keyboardDelay := timecount + KBDELAY;
  end;
end;

procedure DoIntroMenu;
var
  oldcolors: packed array[0..767] of byte;
  temp: PByteArray;
begin
  memcpy(@oldcolors, @colors, 768);
  temp := malloc(64000);
  if temp = nil then
    MS_Error('DoIntroMenu(): No memory for temp screen');
  memcpy(temp, screen, 64000);
  memset(screen, 0, 64000);
  I_SetPalette(CA_CachePalette(CA_GetNamedNum('palette')));
  player.timecount := timecount;
  ShowMenu(0);
  if not quitgame and not gameloaded then
  begin
    memset(screen, 0, 64000);
    memcpy(@colors, @oldcolors, 768);
    I_SetPalette(@colors);
    memcpy(screen, temp, 64000);
  end;
  memfree(pointer(temp));
  timecount := player.timecount;
  activatemenu := false;
  INT_TimerHook(IntroCommand);
end;


function CheckDemoExit: boolean;
begin
  if activatemenu then
  begin
    activatemenu := false;
    nextchar := false;
    result := true;
    exit;
  end;
  result := false;
end;


procedure DemoIntroFlis(const path: string);
var
  name: string;
begin
  fontbasecolor := 0;
  font := font1;

  name := path + 'TEXT.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'WARP01.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'WARP02.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'INSHIP01.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'ARBITER.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'INSHIP02.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;
  Wait(2 * TICRATE);

  name := path + 'CHAR1.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'CHAR2.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'CHAR3.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'CHAR4.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'CHAR5.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'INSHIP03.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'DROPPOD.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'SHP1.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'CITYBURN.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'RUBBLE.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'THF1.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'THF2.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'THF3.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'THF4.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'INSHIP04.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  name := path + 'WARP05.FLI';
  DoPlayFLI(name, 0);
  if CheckDemoExit then exit;

  if not ASSASSINATOR then
  begin
    name := path + 'LOGOFLY.FLI';
    DoPlayFLI(name, 0);
    if CheckDemoExit then exit;
  end;

  Wait(3 * TICRATE);
end;

procedure DemoIntro(const path: string);
var
  i: integer;
  fliname: string;
begin
  fontbasecolor := 0;
  font := font1;

  fliname := 'TEXT.FLI';

  if FindFLIFile(fliname) then
  begin
    DemoIntroFlis(fpath(fliname));
    exit;
  end;

  VI_FillPalette(0, 0, 0);
  if not loadscreen('SOFTLOGO') then exit;
  VI_FadeIn(0, 256, @colors, 48);
  Wait(3 * TICRATE, 1);
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  if CheckDemoExit then exit;

  if not loadscreen('C7LOGO') then exit;
  VI_FadeIn(0, 256, @colors, 48);
  Wait(3 * TICRATE, 1);
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  if CheckDemoExit then exit;

  if not loadscreen('LOGO') then exit;
  VI_FadeIn(0, 256, @colors, 48);
  Wait(3 * TICRATE, 1);
  VI_FillPalette(255, 255, 255);
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  if CheckDemoExit then exit;

  if not loadscreen('INTRO00') then exit;
  VI_FadeIn(0, 256, @colors, 48);
  fontbasecolor := 0;
  while fontbasecolor < 9 do
  begin
    printy := 160;
    FN_PrintCentered(
      'IT IS THE YEAR 15392 DURING THE THIRD AGE OF MAN.'#13#10 +
      'SCAVENGER HUNTS MEAN BIG MONEY FOR THE CRIMINAL'#13#10 +
      'ELITE.  COVERTLY RECRUITED BY AN ENIGMATIC FACTION'#13#10 +
      'OF THE A.V.C. YOU ARE A MEMBER OF THE RED HUNTER'#13#10 +
      'ELITE ACQUISITION SQUAD.'
    );
    Wait(5, 1);
    inc(fontbasecolor);
  end;
  for i := 0 to 69 do
  begin
    Wait(10, 1);
    if CheckDemoExit then exit;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  if CheckDemoExit then exit;


  if not loadscreen('INTRO01') then exit;
  VI_FadeIn(0, 256, @colors, 48);
  fontbasecolor := 0;
  while fontbasecolor < 9 do
  begin
    printy := 160;
    FN_PrintCentered(
      'USING YOUR NEEDLING SHIP, THE RED HUNTER, IT IS YOUR'#13#10 +
      'JOB TO WARP THROUGH TO UNSUSPECTING FRINGE WORLDS...'
    );
    Wait(5, 1);
    inc(fontbasecolor);
  end;
  for i := 0 to 41 do
  begin
    Wait(10, 1);
    if CheckDemoExit then exit;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  if CheckDemoExit then exit;


  if not loadscreen('INTRO02') then exit;
  VI_FadeIn(0, 256, @colors, 48);
  fontbasecolor := 0;
  while fontbasecolor < 9 do
  begin
    printy := 160;
    FN_PrintCentered(
      '...PLUMMET FROM ORBIT IN YOUR DROP SHIP, SUPPRESSING'#13#10 +
      'NONCOOPERATIVE ENTITIES (NOPS) AS BEST YOU CAN IN'#13#10 +
      'ORDER TO ACQUIRE YOUR PRIMARY TARGET ITEMS.'
    );
    Wait(5, 1);
    inc(fontbasecolor);
  end;
  for i := 0 to 41 do
  begin
    Wait(10, 1);
    if CheckDemoExit then exit;
  end;
  if CheckDemoExit then exit;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  if CheckDemoExit then exit;


  if not loadscreen('INTRO03') then exit;
  VI_FadeIn(0, 256, @colors, 48);
  fontbasecolor := 0;
  while fontbasecolor < 9 do
  begin
    printy := 160;
    FN_PrintCentered(
      'THE SIZE AND SPEED OF THE DROP SHIP SHOULD BE SUFFICIENT'#13#10 +
      'TO DRIVE NONCOOPERATIVES FROM THE DROP ZONE UPON IMPACT.'
    );
    Wait(5, 1);
    inc(fontbasecolor);
  end;
  for i := 0 to 41 do
  begin
    Wait(10);
    if CheckDemoExit then exit;
  end;
  if CheckDemoExit then exit;
  VI_FillPalette(0, 0, 0);
  if CheckDemoExit then exit;


  if not loadscreen('INTRO04') then exit;
  I_SetPalette(@colors);
  for i := 0 to 20 do
  begin
    Wait(10, 1);
    if CheckDemoExit then exit;
  end;
  if CheckDemoExit then exit;
  VI_FadeOut(0, 256, 255, 255, 255, 48);
  if CheckDemoExit then exit;


  if not loadscreen('INTRO05') then exit;
  VI_FadeIn(0, 256, @colors, 48);
  for i := 0 to 20 do
  begin
    Wait(10, 1);
    if CheckDemoExit then exit;
  end;
  if CheckDemoExit then exit;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  if CheckDemoExit then exit;


  if not loadscreen('INTRO06') then exit;
  VI_FadeIn(0, 256, @colors, 48);
  fontbasecolor := 0;
  while fontbasecolor < 9 do
  begin
    printy := 160;
    FN_PrintCentered('IN SHORT, IF IT''S MOVING AROUND, KILL IT...');
    Wait(5, 1);
    inc(fontbasecolor);
  end;
  for i := 0 to 27 do
  begin
    Wait(10, 1);
    if CheckDemoExit then exit;
  end;
  if CheckDemoExit then exit;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  if CheckDemoExit then exit;


  if not loadscreen('INTRO07') then exit;
  VI_FadeIn(0, 256, @colors, 48);
  fontbasecolor := 0;
  while fontbasecolor < 9 do
  begin
    printy := 160;
    FN_PrintCentered('...AND IF IT''S NOT NAILED DOWN, STEAL IT.');
    Wait(5, 1);
    inc(fontbasecolor);
  end;
  for i := 0 to 27 do
  begin
    Wait(10, 1);
    if CheckDemoExit then exit;
  end;
  if CheckDemoExit then exit;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  if CheckDemoExit then exit;

  if not loadscreen('INTRO08') then exit;
  VI_FadeIn(0, 256, @colors, 48);
  fontbasecolor := 0;
  while fontbasecolor < 9 do
  begin
    printy := 160;
    FN_PrintCentered(
      'YOU''RE A SCAVENGER.  YOU''VE GOT A GUN.'#13#10 +
      'LET''S GET SOME.'
    );
    Wait(5, 1);
    inc(fontbasecolor);
  end;
  for i := 0 to 27 do
  begin
    Wait(10, 1);
    if CheckDemoExit then exit;
  end;
  if CheckDemoExit then exit;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  if CheckDemoExit then exit;
end;

procedure MainIntro;
var
  path: string;
begin
  if CDROMGREEDDIR then
    path := Chr(cdr_drivenum + Ord('A')) + ':\GREED\MOVIES\'
  else
    path := Chr(cdr_drivenum + Ord('A')) + ':\MOVIES\';
  DemoIntro(path);
end;

procedure dointro;
var
  i: integer;
begin
  INT_TimerHook(IntroCommand);

  PlaySong('INTRO.S3M', 0);

  VI_FillPalette(0, 0, 0);

  quitgame := false;
  gameloaded := false;

  if not redo then
    MainIntro;

  redo := false;

  VI_FillPalette(0, 0, 0);
  activatemenu := false;
  while true do
  begin
    for i := 1 to 5 do
    begin
      ShowPortrait(i);
      if quitgame or gameloaded then
      begin
        INT_TimerHook(nil);
        exit;
      end;
    end;
  end;
end;


procedure LoadMiscData;
var
  i: integer;
begin
  printf('LoadMiscData().');
  font1 := CA_CacheLump(CA_GetNamedNum('FONT1'));
  printf('.');
  font2 := CA_CacheLump(CA_GetNamedNum('FONT2'));
  printf('.');
  font3 := CA_CacheLump(CA_GetNamedNum('FONT3'));
  statusbar[0] := CA_CacheLump(CA_GetNamedNum('STATBAR1'));
  statusbar[1] := CA_CacheLump(CA_GetNamedNum('STATBAR2'));
  statusbar[2] := CA_CacheLump(CA_GetNamedNum('STATBAR3'));
  statusbar[3] := CA_CacheLump(CA_GetNamedNum('STATBAR4'));
  printf('.');
  for i := 0 to 9 do
    heart[i] := CA_CacheLump(CA_GetNamedNum('HEART') + i);
  printf('.');
  backdrop := malloc(256 * 256);
  if backdrop = nil then
    MS_Error('LoadMiscData(): Out of memory for BackDrop');
  printf('.');
  for i := 0 to 255 do
    backdroplookup[i] := @backdrop[256 * i];
  printf('.Done!'#13#10);
end;


procedure FreeMiscData;
begin
  memfree(pointer(backdrop));
end;


procedure checkexit;
begin
  if newascii and (lastascii = #27) then
    MS_Error('Cancel Startup');
  newascii := false;
end;


procedure LoadData;
var
  netplay: boolean;
  parm: integer;
  netaddr: integer;
begin
  netplay := false;

  M_ResolveCommandLineEpisode;

  if MS_CheckParm('nointro') > 0 then
    nointro := true;
  if MS_CheckParm('nobriefing') > 0 then
    nobriefing := true;
  if MS_CheckParm('record') > 0 then
    recording := true;
  if MS_CheckParm('playback') > 0 then
    playback := true;
  if MS_CheckParm('debugmode') > 0 then
    debugmode := true;
  parm := MS_CheckParm('net');
  if (parm > 0) and (parm < my_argc - 1) then
  begin
    netaddr := atoi(my_argv(parm + 1));
    netplay := true;
    netmode := true;
  end;

  InitDefaults;
  // load config file
  if not M_LoadDefaults then
    printf('LoadDefaults: Ini file not found, using defaults'#13#10);

  if lowresolution then
  begin
    MAXSCROLL := MAXSCROLL1 div 2;
    BACKDROPHEIGHT := BACKDROPHEIGHT1 div 2;
    SCROLLRATE := SCROLLRATE1 div 2;
  end;

  if MS_CheckParm('nospawn') > 0 then
    nospawn := true;
  if MS_CheckParm('ticker') > 0 then
    ticker := true;
  CA_InitFile('GREED.BLO');
  if netplay then
  begin
    NetInit(@netaddr);
    nointro := true;
  end;
  InitSound;
  INT_Setup;
  checkexit;
  RF_PreloadGraphics;
  checkexit;
  RF_Startup;
  checkexit;
  LoadMiscData;
  checkexit;
  VI_Init;
end;


procedure startup;
label
  restart;
begin
  LoadData;

restart:

  if nointro then
  begin
    redo :=  false;
    I_SetPalette(CA_CachePalette(CA_GetNamedNum('palette')));
    if GAME1 then
      newplayer(0, 0, 2)
    else if GAME2 then
      newplayer(8, 0, 2)
    else if GAME3 then
      newplayer(16, 0, 2)
    else
      newplayer(0, 0, 2);
    needsblit := false;
    maingame;
  end
  else
  begin
    needsblit := true;
    dointro;
  end;

  if not quitgame then
  begin
    needsblit := false;
    maingame;
    if redo then
      goto restart;
  end
  else
    StopMusic;

  I_ShutDownSound;
  INT_Shutdown;
  CA_ShutDown;
  RF_ShutDown;
  FreeMiscData;
  FreeWallPosts;
end;


end.


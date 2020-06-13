(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020 by Jim Valavanis                                     *)
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
  nointro, nextchar: boolean;
  cdr_drivenum: integer;


(**** FUNCTIONS ****)

procedure loadscreen(const s: string);

procedure DoIntroMenu;

implementation

uses
  g_delphi,
  d_video,
  d_disk,
  d_ints,
  playfli;

procedure loadscreen(const s: string);
var
  l: Ppic_t;
  pal: PByteArray;
  i: integer;
begin
  i := CA_GetNamedNum(s);
  l := CA_CacheLump(i);
  VI_DrawPic(0, 0, l);
  CA_FreeLump(i);
  pal := CA_CacheLump(i + 1);
  memcpy(@colors, pal, 768);
  CA_FreeLump(i + 1);
end;


procedure Wait(time: integer);
var
  t: integer;
begin
  t := timecount + time;
  while not CheckTime(timecount,t)) do
    I_PeekAndDisplatch;
end;


procedure ShowPortrait(int n);
begin
  char str1[128];
  i: integer;

  sprintf(str1,'CHAR%i',n);
  loadscreen(str1);
  VI_FadeIn(0,256,colors,48);
  font := font1;
  for(i := 0;i<27;i++)
  begin
   UpdateSound;
   for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
    if charinfo[n-1][i][0] <> '.' then
    begin
      printx := 144;
      printy := 19+6*i;
      sprintf(str1,'%s',charinfo[n-1][i]);
      FN_RawPrint3(str1);
      Wait(2);
       end;
   if activatemenu then
   begin
     DoIntroMenu;
     if (quitgame) or (gameloaded) exit;
      end;
    end;
  for(i := 0;i<50;i++)
  begin
   UpdateSound;
   Wait(35);
   if activatemenu then
   begin
     DoIntroMenu;
     if (quitgame) or (gameloaded) exit;
      end;
   if nextchar then
   begin
     nextchar := false;
     break;
      end;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  end;


procedure IntroCommand;
begin
  if ((keyboard[SC_ESCAPE]) or (keyboard[SC_ENTER])) and (timecount>keyboardDelay) then
  begin
   activatemenu := true;
   keyboardDelay := timecount+20;
    end;
  if (keyboard[SC_SPACE]) and (timecount>keyboardDelay) then
  begin
   nextchar := true;
   keyboardDelay := timecount+20;
    end;
  end;

procedure DoIntroMenu;
begin
  byte *temp, oldcolors[768];

  memcpy(oldcolors,colors,768);
  temp := (byte *)malloc(64000);
  if (temp = NULL) MS_Error('DoIntroMenu: No memory for temp screen');
  memcpy(temp,screen,64000);
  memset(screen,0,64000);
  VI_SetPalette(CA_CacheLump(CA_GetNamedNum('palette')));
  player.timecount := timecount;
  ShowMenu(0);
  if (not quitgame) and ( not gameloaded) then
  begin
   memset(screen,0,64000);
   memcpy(colors,oldcolors,768);
   VI_SetPalette(colors);
   memcpy(screen,temp,64000);
    end;
  free(temp);
  timecount := player.timecount;
  activatemenu := false;
// lock_region((void near *)IntroCommand,(char *)IntroStub - (char near *)IntroCommand);
  INT_TimerHook(IntroCommand);
  keyboardDelay := timecount+KBDELAY;
  end;


  CheckDemoExit: boolean;
  begin
  if activatemenu then
  begin
   activatemenu := false;
   nextchar := false;
//   unlock_region((void near *)IntroCommand,(char *)IntroStub - (char near *)IntroCommand);
//   INT_TimerHook(NULL);
   return true;
    end;
  return false;
  end;


procedure DemoIntroFlis(char *path);


procedure MainIntro;
begin
  char  path[64];

{$IFDEF CDROMGREEDDIR}
  sprintf(path,'%c:\\GREED\\MOVIES\\',cdr_drivenum+'A');
{$ELSE}
  sprintf(path,'%c:\\MOVIES\\',cdr_drivenum+'A');
{$ENDIF}
  DemoIntroFlis(path);
  end;


procedure DemoIntroFlis(char *path);
begin
  char name[64];

  fontbasecolor := 0;
  font := font1;

  sprintf(name,'%sTEXT.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sWARP01.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sWARP02.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sINSHIP01.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sARBITER.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sINSHIP02.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;
  Wait(140);

  sprintf(name,'%sCHAR1.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sCHAR2.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sCHAR3.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sCHAR4.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sCHAR5.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sINSHIP03.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sDROPPOD.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sSHP1.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sCITYBURN.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sRUBBLE.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sTHF1.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sTHF2.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sTHF3.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sTHF4.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sINSHIP04.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

  sprintf(name,'%sWARP05.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;

#ifndef ASSASSINATOR
  sprintf(name,'%sLOGOFLY.FLI',path);
  playfli(name,0);
  if (CheckDemoExit) exit;
{$ENDIF}

  Wait(210);
  end;


procedure DemoIntro;
begin
  i: integer;
  FILE *f;

  fontbasecolor := 0;
  font := font1;

  f := fopen('MOVIES\\TEXT.FLI','rb');
  if f <> NULL then
  begin
   fclose(f);
   DemoIntroFlis('MOVIES\\');
   exit;
    end;

  VI_FillPalette(0,0,0);
  loadscreen('SOFTLOGO');
  VI_FadeIn(0,256,colors,48);
  Wait(210);
  VI_FadeOut(0,256,0,0,0,48);
  if (CheckDemoExit) exit;

  loadscreen('C7LOGO');
  VI_FadeIn(0,256,colors,48);
  Wait(210);
  VI_FadeOut(0,256,0,0,0,48);
  if (CheckDemoExit) exit;

  loadscreen('LOGO');
  VI_FadeIn(0,256,colors,48);
  Wait(210);
  VI_FillPalette(63,63,63);
  VI_FadeOut(0,256,0,0,0,48);
  if (CheckDemoExit) exit;

  loadscreen('INTRO00');
  VI_FadeIn(0,256,colors,48);
  for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
  begin
   printy := 160;
   FN_CenterPrintf(
    'IT IS THE YEAR 15392 DURING THE THIRD AGE OF MAN.\n'
    'SCAVENGER HUNTS MEAN BIG MONEY FOR THE CRIMINAL\n'
    'ELITE.  COVERTLY RECRUITED BY AN ENIGMATIC FACTION\n'
    'OF THE A.V.C. YOU ARE A MEMBER OF THE RED HUNTER\n'
    'ELITE ACQUISITION SQUAD.');
   Wait(5);
    end;
  for(i := 0;i<70;i++)
  begin
   Wait(10);
   if (CheckDemoExit) exit;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  if (CheckDemoExit) exit;


  loadscreen('INTRO01');
  VI_FadeIn(0,256,colors,48);
  for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
  begin
   printy := 160;
   FN_CenterPrintf(
    'USING YOUR NEEDLING SHIP, THE RED HUNTER, IT IS YOUR\n'
    'JOB TO WARP THROUGH TO UNSUSPECTING FRINGE WORLDS...');
   Wait(5);
    end;
  for(i := 0;i<42;i++)
  begin
   Wait(10);
   if (CheckDemoExit) exit;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  if (CheckDemoExit) exit;


  loadscreen('INTRO02');
  VI_FadeIn(0,256,colors,48);
  for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
  begin
   printy := 160;
   FN_CenterPrintf(
    '...PLUMMET FROM ORBIT IN YOUR DROP SHIP, SUPPRESSING\n'
    'NONCOOPERATIVE ENTITIES (NOPS) AS BEST YOU CAN IN\n'
    'ORDER TO ACQUIRE YOUR PRIMARY TARGET ITEMS.');
   Wait(5);
    end;
  for(i := 0;i<42;i++)
  begin
   Wait(10);
   if (CheckDemoExit) exit;
    end;
  if (CheckDemoExit) exit;
  VI_FadeOut(0,256,0,0,0,48);
  if (CheckDemoExit) exit;


  loadscreen('INTRO03');
  VI_FadeIn(0,256,colors,48);
  for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
  begin
   printy := 160;
   FN_CenterPrintf(
    'THE SIZE AND SPEED OF THE DROP SHIP SHOULD BE SUFFICIENT\n'
    'TO DRIVE NONCOOPERATIVES FROM THE DROP ZONE UPON IMPACT.');
   Wait(5);
    end;
  for(i := 0;i<42;i++)
  begin
   Wait(10);
   if (CheckDemoExit) exit;
    end;
  if (CheckDemoExit) exit;
  VI_FillPalette(0,0,0);
  if (CheckDemoExit) exit;


  loadscreen('INTRO04');
  VI_SetPalette(colors);
  for(i := 0;i<21;i++)
  begin
   Wait(10);
   if (CheckDemoExit) exit;
    end;
  if (CheckDemoExit) exit;
  VI_FadeOut(0,256,64,64,64,48);
  if (CheckDemoExit) exit;


  loadscreen('INTRO05');
  VI_FadeIn(0,256,colors,48);
  for(i := 0;i<21;i++)
  begin
   Wait(10);
   if (CheckDemoExit) exit;
    end;
  if (CheckDemoExit) exit;
  VI_FadeOut(0,256,0,0,0,48);
  if (CheckDemoExit) exit;


  loadscreen('INTRO06');
  VI_FadeIn(0,256,colors,48);
  for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
  begin
   printy := 160;
   FN_CenterPrintf('IN SHORT, IF IT'S MOVING AROUND, KILL IT...');
   Wait(5);
    end;
  for(i := 0;i<28;i++)
  begin
   Wait(10);
   if (CheckDemoExit) exit;
    end;
  if (CheckDemoExit) exit;
  VI_FadeOut(0,256,0,0,0,48);
  if (CheckDemoExit) exit;


  loadscreen('INTRO07');
  VI_FadeIn(0,256,colors,48);
  for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
  begin
   printy := 160;
   FN_CenterPrintf('...AND IF IT'S NOT NAILED DOWN, STEAL IT.');
   Wait(5);
    end;
  for(i := 0;i<28;i++)
  begin
   Wait(10);
   if (CheckDemoExit) exit;
    end;
  if (CheckDemoExit) exit;
  VI_FadeOut(0,256,0,0,0,48);
  if (CheckDemoExit) exit;

  loadscreen('INTRO08');
  VI_FadeIn(0,256,colors,48);
  for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
  begin
   printy := 160;
   FN_CenterPrintf(
    'YOU'RE A SCAVENGER.  YOU'VE GOT A GUN.\n'
    'LET'S GET SOME.');
   Wait(5);
    end;
  for(i := 0;i<28;i++)
  begin
   Wait(10);
   if (CheckDemoExit) exit;
    end;
  if (CheckDemoExit) exit;
  VI_FadeOut(0,256,0,0,0,48);
  if (CheckDemoExit) exit;
  end;


procedure intro;
begin
  i: integer;

  INT_TimerHook(IntroCommand);

  PlaySong('INTRO.S3M',0);

  VI_FillPalette(0,0,0);

  quitgame := 0;
  gameloaded := 0;

  if not redo then
  MainIntro;

  redo := 0;

// lock_region((void near *)IntroCommand,(char *)IntroStub - (char near *)IntroCommand);
// INT_TimerHook(IntroCommand);
  VI_FillPalette(0,0,0);
  activatemenu := false;
  for(;)
  begin
   for(i := 1;i<6;i++)
   begin
     ShowPortrait(i);
     if (quitgame) or (gameloaded) then
     begin
       INT_TimerHook(NULL);
       exit;
        end;
      end;
    end;
  end;


procedure LoadMiscData;
begin
  i: integer;

  printf('.');
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
  for(i := 0;i<10;i++)
  heart[i] := CA_CacheLump(CA_GetNamedNum('HEART')+i);
  printf('.');
  backdrop := malloc(256*256);
  if backdrop = NULL then
  MS_Error('Out of memory for BackDrop');
  printf('.');
  for(i := 0;i<256;i++)
  backdroplookup[i] := (byte*)backdrop+256*i;
  printf('.');
  end;


void checkexit
begin
  if (newascii) and (lastascii = 27) MS_Error('Cancel Startup');
  newascii := false;
  end;


procedure LoadData;
begin
  netplay :=  false: boolean;
  parm: integer;
  netaddr: integer;

  if (MS_CheckParm('nointro')) then
   nointro := true;
  if (MS_CheckParm('record')) then
   recording := true;
  if (MS_CheckParm('playback')) then
   playback := true;
  if (MS_CheckParm('debugmode')) then
   debugmode := true;
  parm := MS_CheckParm('net');
  if (parm) and (parm<my_argc-1) then
  begin
   netaddr := atoi(my_argv[parm+1]);
   netplay := true;
   netmode := 1;
    end;

  if (MS_CheckParm('nospawn')) nospawn := true;
  if (MS_CheckParm('ticker')) ticker := true;
  CA_InitFile('GREED.BLO');
  if netplay then
  begin
   NetInit((void *)netaddr);
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
  VI_Init(0);
  end;


void startup
begin
  nointro :=  true;

  LoadData;

restart:

  if nointro then
  begin
    redo :=  false;
    VI_SetPalette(CA_CacheLump(CA_GetNamedNum('palette')));
    newplayer(0,0,2);
    maingame;
   end;
  else
    intro;

  if not quitgame then
  begin
    maingame;
    if redo then
      goto restart;
   end;
  else
    StopMusic;

  INT_Shutdown;
  end;


LRESULT CALLBACK WndProc(HWND hWnd,UINT message,WPARAM uParam,LPARAM lParam)
begin
    HDC      hdc;
    PAINTSTRUCT ps;

    case message  of
    begin
    WM_PAINT:
      hdc :=  BeginPaint(hWnd,) and (ps);
      VI_ResetPalette;
      VI_BlitView;
      EndPaint(hWnd,) and (ps);
      break;

    WM_CLOSE:
      quitgame :=  true;
    break;

    WM_DESTROY:
      PostQuitMessage(0);
    break;

    default:
      return (DefWindowProc(hWnd, message, uParam, lParam));
     end;

    return (0);
  end;


BOOL InitApplication(HINSTANCE hInstance)
begin
    WNDCLASS  wc;
  ATOM    atom;

    wc.style :=  0;
    wc.lpfnWndProc :=  (WNDPROC)WndProc;
    wc.cbClsExtra :=  0;
    wc.cbWndExtra :=  0;
    wc.hInstance :=  hInstance;
    wc.hIcon :=  NULL;
    wc.hCursor :=  NULL;
    wc.hbrBackground :=  (HBRUSH)GetStockObject(BLACK_BRUSH);
    wc.lpszMenuName :=  NULL;
    wc.lpszClassName := APPNAME;

    atom :=  RegisterClass and (wc);
    return atom <> 0 ? true : false;
  end;


BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
begin
  RECT rc;  // Called in GetClientRect

  rc.left :=  0;
  rc.right :=  640;
  rc.top :=  0;
  rc.bottom :=  400;

  AdjustWindowRect and (rc,WS_VISIBLE,FALSE);

  rc.right := rc.right - rc.left;
  rc.bottom := rc.bottom - rc.top;
  rc.top :=  0;
  rc.left :=  0;

  // Use the default window settings.
  Window_Handle :=  CreateWindow(
    APPNAME,
    APPNAME,
    WS_VISIBLE) or (WS_OVERLAPPED,
    rc.left,
    rc.top,
    rc.right,
    rc.bottom,
    NULL,
    NULL,
    hInstance,
    NULL);

  if (Window_Handle = 0)    // Check whether values returned by CreateWindow are valid.
    return (FALSE);
  
    ShowWindow(Window_Handle,SW_SHOW);
    UpdateWindow(Window_Handle);

    return(TRUE);                  // Window handle hWnd is valid.
  end;




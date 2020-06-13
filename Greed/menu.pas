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

unit menu;

interface

uses
  d_video;

type
  cursor_t = record
    x, y: integer;
    w, h: integer;
  end;
  Pcursor_t = ^cursor_t;

const
  KBDELAY2 = 10;
  MENUS = 6;
  MAXSAVEGAMES = 10;

const
  cursors: array[0..MENUS - 1, 0..14] of cursor_t  = (
  (
  // main menu
   (x: 41; y: 114; w: 55; h: 20),   // new
   (x: 41; y: 138; w: 55; h: 20),   // quit
   (x: 134; y: 42; w: 127; h: 19),  // load
   (x: 134; y: 62; w: 127; h: 19),  // save
   (x: 134; y: 82; w: 127; h: 19),  // options
   (x: 134; y: 102; w: 127; h: 19), // info
   (x: 142; y: 142; w: 62; h: 15),  // quit/resume
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0)
  ),
  (
  // char menu
   (x: 41; y: 138; w: 55; h: 20),   // quit
   (x: 134; y: 32; w: 127; h: 18),  // cyborg
   (x: 134; y: 51; w: 127; h: 18),  // lizard
   (x: 134; y: 70; w: 127; h: 18),  // moo
   (x: 134; y: 89; w: 127; h: 18),  // specimen
   (x: 134; y: 108; w: 127; h: 18), // dominatrix
   (x: 142; y: 142; w: 62; h: 15),  // back
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0)
  ),
  (
  // load
   (x: 41; y: 138; w: 55; h: 20),   // quit
   (x: 137; y: 34; w: 7; h: 5),
   (x: 137; y: 44; w: 7; h: 5),
   (x: 137; y: 54; w: 7; h: 5),
   (x: 137; y: 64; w: 7; h: 5),
   (x: 137; y: 74; w: 7; h: 5),
   (x: 137; y: 84; w: 7; h: 5),
   (x: 137; y: 94; w: 7; h: 5),
   (x: 137; y: 104; w: 7; h: 5),
   (x: 137; y: 114; w: 7; h: 5),
   (x: 137; y: 124; w: 7; h: 5),
   (x: 142; y: 142; w: 62; h: 15),  // back
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0)
  ),
  (
  // save
   (x: 41; y: 138; w: 55; h: 20),   // quit
   (x: 137; y: 34; w: 7; h: 5),
   (x: 137; y: 44; w: 7; h: 5),
   (x: 137; y: 54; w: 7; h: 5),
   (x: 137; y: 64; w: 7; h: 5),
   (x: 137; y: 74; w: 7; h: 5),
   (x: 137; y: 84; w: 7; h: 5),
   (x: 137; y: 94; w: 7; h: 5),
   (x: 137; y: 104; w: 7; h: 5),
   (x: 137; y: 114; w: 7; h: 5),
   (x: 137; y: 124; w: 7; h: 5),
   (x: 142; y: 142; w: 62; h: 15),  // back
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0)
  ),
  (
  // options
   (x: 41; y: 114; w: 55; h: 20),
   (x: 41; y: 138; w: 55; h: 20),
   (x: 134; y: 32; w: 127; h: 15),
   (x: 134; y: 46; w: 127; h: 15),
   (x: 134; y: 60; w: 127; h: 15),
   (x: 134; y: 74; w: 127; h: 15),
   (x: 134; y: 88; w: 127; h: 15),
   (x: 134; y: 101; w: 127; h: 15),
   (x: 134; y: 115; w: 127; h: 15),
   (x: 142; y: 142; w: 62; h: 15),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0)
  ),
  (
  // monster menu
   (x: 41; y: 138; w: 55; h: 20),   // quit
   (x: 134; y: 30; w: 127; h: 15),  // difficulty level 0
   (x: 134; y: 45; w: 127; h: 15),
   (x: 134; y: 60; w: 127; h: 15),
   (x: 134; y: 75; w: 127; h: 15),
   (x: 134; y: 90; w: 127; h: 15),
   (x: 134; y: 117; w: 127; h: 15),
   (x: 142; y: 142; w: 62; h: 15),  // back
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0)
  )
  );


const
  menumax: array[0..MENUS - 1] of integer = ( // max cursor
    7, 7, 12, 12, 10, 8
  );

var
  menuscreen: Ppic_t;
  menulevel: integer;
  menucursor: integer;
  menucurloc: integer;
  menumaincursor: integer;
  identity: integer;
  waitanim: integer;
  saveposition: integer;
  timedelay: integer;
  quitmenu, menuexecute, downlevel, goright, goleft, waiting: boolean;
  savedir: array[0..MAXSAVEGAMES - 1] of string[22];
  waitpics: array[0..3] of Ppic_t;
extern  SoundCard SC;


(**** FUNCTIONS ****)

procedure VI_DrawMaskedPic2(int x, int y, pic_t  *pic);
(* Draws a formatted image to the screen, masked with zero *)
begin
  byte *dest, *source, *source2;
  width, height, xcor: integer;

  x := x - pic.orgx;
  y := y - pic.orgy;
  height := pic.height;
  source := @pic.data;
  while y<0 do
  begin
   source := source + pic.width;
   height--;
   y++;
    end;
  while height-- do
  begin
   if y<200 then
   begin
     dest := ylookup[y]+x;
     source2 := y*320+x+viewbuffer;
     xcor := x;
     width := pic.width;
     while width-- do
     begin
       if (xcor >= 0) and (xcor <= 319) and (*source) *dest := *source;
  else *dest := *source2;
       xcor++;
       source++;
       source2++;
       dest++;
        end;
      end;
   y++;
    end;
  end;


procedure MenuCommand;


bool ShowQuit(void (*kbdfunction);)
begin
  animtime, droptime: integer;
  anim, y, i, lump: integer;
  short   mx, my;
  pic_t   *pics[3];
  char    c;
  result: boolean;
  byte    *scr;

  INT_TimerHook(NULL);
  scr := (byte *)malloc(64000);
  if (scr = NULL) MS_Error('Error allocating ShowQuit buffer');
  MouseHide;
  memcpy(scr,viewbuffer,64000);
  memcpy(viewbuffer,screen,64000);
  MouseShow;
  if (netmode) TimeUpdate;
  lump := CA_GetNamedNum('quit');
  for(i := 0;i<3;i++) pics[i] := CA_CacheLump(lump+i);
  timedelay := timecount+KBDELAY2;
  Wait(KBDELAY2);
  if (netmode) TimeUpdate;
  newascii := false;
  anim := 0;
  MouseHide;
  if (not SC.animation) or (netmode) then
  begin
   y := 68;
   MouseShow;
    end;
  else y := -66;
  droptime := timecount;
  animtime := timecount;
  while 1 do
  begin
   if (y >= 67) and (MouseGetClick and (mx,) and (my)) and (my >= 110) and (my <= 117) then
   begin
     if (mx >= 130) and (mx <= 153) then
     begin
       c := 'y';
       break;
     end
     else if (mx >= 162) and (mx <= 186) then
     begin
       c := 'n';
       break;
        end;
      end;

   if (netmode) TimeUpdate;

   if (newascii) and (y >= 67) then
   begin
     c := lastascii;
     break;
      end;
   if (timecount >= droptime) and (y<67) then
   begin
     if (y >= 0) memcpy(ylookup[y],viewbuffer+320*y,640);
     y := y + 2;
     droptime := timecount+1;
     VI_DrawMaskedPic2(111,y,pics[anim]);
     if (y >= 67) MouseShow;
      end;
   if timecount >= animtime then
   begin
     anim++;
     anim mod  := 3;
     animtime := animtime + 10;
     MouseHide;
     VI_DrawMaskedPic2(111,y,pics[anim]);
     MouseShow;
      end;
    end;
  if (c = 'y') or (c = 'Y') result := true;
  else result := false;
  droptime := timecount;
  animtime := timecount;
  if (not SC.animation) or (netmode) y := 200;
  MouseHide;
  while y<199 do
  begin
   if timecount >= droptime then
   begin
     if (y >= 0) memcpy(ylookup[y],viewbuffer+320*y,640);
     y := y + 2;
     droptime := timecount+1;
     VI_DrawMaskedPic2(111,y,pics[anim]);
      end;
   if timecount >= animtime then
   begin
     anim++;
     anim mod  := 3;
     animtime := animtime + 10;
     VI_DrawMaskedPic2(111,y,pics[anim]);
      end;
    end;
  memcpy(screen,viewbuffer,64000);
  memcpy(viewbuffer,scr,64000);
  for(i := 0;i<3;i++) CA_FreeLump(lump+i);
  MouseShow;
  free(scr);
  timedelay := timecount+KBDELAY2;
  turnrate := 0;
  moverate := 0;
  fallrate := 0;
  strafrate := 0;
  ResetMouse;
  INT_TimerHook(kbdfunction);
  if (netmode) TimeUpdate;
  return result;
  end;


(******************************************************************************)


procedure ShowMenuSliders(int value,int range);
begin
  a, c, d, i: integer;

  MouseHide;
  d := (value*49)/range;
  for(a := 0;a<d;a++)
  begin
   c := (a*32)/d + 140;
   for(i := 49;i<65;i++)
    *(ylookup[i]+a+42) := c;
    end;
  if d<49 then
  for(a := d;a<49;a++)
  begin
    for(i := 49;i<65;i++)
     *(ylookup[i]+a+42) := 0;
     end;
  MouseShow;
  end;


void SaveDirectory
begin
  FILE *f;

{$IFDEF GAME1}
  f := fopen('SAVE1.DIR','w');
#elif defined(GAME2)
  f := fopen('SAVE2.DIR','w');
#elif defined(GAME3)
  f := fopen('SAVE3.DIR','w');
{$ELSE}
  f := fopen('SAVEGAME.DIR','w');
{$ENDIF}

  if f = NULL then
  MS_Error('SaveDirectory: Error creating SAVEGAME.DIR');
  if (not fwrite(savedir,SizeOf(savedir),1,f)) then
  MS_Error('SaveDirectory: Error saving SAVEGAME.DIR');
  fclose(f);
  end;


void InitSaveDir
begin
  i: integer;

  for(i := 0;i<MAXSAVEGAMES;i++)
  begin
   memset(savedir[i],(int)' ',20);
   savedir[i][20] := 0;
    end;
  SaveDirectory;
  end;


procedure ShowSaveDir;
begin
  FILE *f;
  i, j: integer;

{$IFDEF GAME1}
  f := fopen('SAVE1.DIR','r');
#elif defined(GAME2)
  f := fopen('SAVE2.DIR','r');
#elif defined(GAME3)
  f := fopen('SAVE3.DIR','r');
{$ELSE}
  f := fopen('SAVEGAME.DIR','r');
{$ENDIF}

  if (f = NULL) InitSaveDir;
  else
  begin
   if (not fread(savedir,SizeOf(savedir),1,f)) then
    MS_Error('ShowSaveDir: Savegame directory read failure!');
   fclose(f);
    end;
  fontbasecolor := 93;
  font := font1;
  MouseHide;
  for(i := 0;i<MAXSAVEGAMES;i++)
  begin
   printx := 148;
   printy := 34+i*10;
   for(j := 0;j<6;j++)
    memset(ylookup[printy+j]+printx,0,110);
   FN_Printf(savedir[i]);
    end;
  MouseShow;
  end;


procedure MenuShowOptions;
begin
  MouseHide;
  case menucursor  of
  begin
   2: // music vol
    VI_DrawPic(35,29,CA_CacheLump(CA_GetNamedNum('menumussli')));
    ShowMenuSliders(SC.musicvol,256);
    break;
   3: // sound vol
    VI_DrawPic(35,29,CA_CacheLump(CA_GetNamedNum('menusousli')));
    ShowMenuSliders(SC.sfxvol,256);
    break;
   4: // violence
    if SC.violence then
     VI_DrawPic(35,29,CA_CacheLump(CA_GetNamedNum('menuvioon')));
    else
     VI_DrawPic(35,29,CA_CacheLump(CA_GetNamedNum('menuviooff')));
    break;
   5: // animation
    if SC.animation then
     VI_DrawPic(35,29,CA_CacheLump(CA_GetNamedNum('menuanion')));
    else
     VI_DrawPic(35,29,CA_CacheLump(CA_GetNamedNum('menuanioff')));
    break;
   6: // ambient light
    VI_DrawPic(35,29,CA_CacheLump(CA_GetNamedNum('menuambsli')));
    ShowMenuSliders(SC.ambientlight,4096);
    break;
   7: // screen size
    VI_DrawPic(35,29,CA_CacheLump(CA_GetNamedNum('menuscrsli')));
    ShowMenuSliders(10-SC.screensize,10);
    break;
   8: // asscam
    VI_DrawPic(35,29,CA_CacheLump(CA_GetNamedNum('menucamsli')));
    ShowMenuSliders(SC.camdelay,70);
    break;
    end;
  MouseShow;
  end;


procedure MenuLeft;
begin
  if menulevel = 4 then
  begin
   MouseHide;
   case menucursor  of
   begin
     2:
      if SC.musicvol then
      begin
  SC.musicvol := SC.musicvol - 4;
  if (SC.musicvol<0) SC.musicvol := 0;
  SetVolumes(SC.musicvol,SC.sfxvol);
  ShowMenuSliders(SC.musicvol,255);
   end;
      break;
     3:
      if SC.sfxvol then
      begin
  SC.sfxvol := SC.sfxvol - 4;
  if (SC.sfxvol<0) SC.sfxvol := 0;
  SetVolumes(SC.musicvol,SC.sfxvol);
  ShowMenuSliders(SC.sfxvol,255);
   end;
      break;
     4: // violence
      SC.violence := true;
      MenuShowOptions;
      break;
     5: // animation
      SC.animation := true;
      MenuShowOptions;
      break;
     6: // ambient
      if SC.ambientlight then
      begin
  SC.ambientlight := SC.ambientlight - 64;
  if (SC.ambientlight<0) SC.ambientlight := 0;
  ShowMenuSliders(SC.ambientlight,4096);
  changelight := SC.ambientlight;
  lighting := 1;
   end;
      break;
     7: // screensize
      if SC.screensize<9 then
      begin
  SC.screensize++;
  ShowMenuSliders(10-SC.screensize,10);
  timedelay := timecount+KBDELAY2;
  goleft := false;
   end;
      break;
     8: // camera delay
      if SC.camdelay then
      begin
  SC.camdelay--;
  ShowMenuSliders(SC.camdelay,70);
   end;
      break;
      end;
   MouseShow;
    end;
  end;


procedure MenuRight;
begin
  if menulevel = 4 then
  begin
   MouseHide;
   case menucursor  of
   begin
     2:
      if SC.musicvol<255 then
      begin
  SC.musicvol := SC.musicvol + 4;
  if (SC.musicvol>255) SC.musicvol := 255;
  SetVolumes(SC.musicvol,SC.sfxvol);
  ShowMenuSliders(SC.musicvol,255);
   end;
      break;
     3:
      if SC.sfxvol<255 then
      begin
  SC.sfxvol := SC.sfxvol + 4;
  if (SC.sfxvol>255) SC.sfxvol := 255;
  SetVolumes(SC.musicvol,SC.sfxvol);
  ShowMenuSliders(SC.sfxvol,255);
   end;
      break;
     4: // violence
      SC.violence := false;
      MenuShowOptions;
      break;
     5: // animation
      SC.animation := false;
      MenuShowOptions;
      break;
     6: // ambient
      if SC.ambientlight<4096 then
      begin
  SC.ambientlight := SC.ambientlight + 64;
  if (SC.ambientlight>4096) SC.ambientlight := 4096;
  ShowMenuSliders(SC.ambientlight,4096);
  changelight := SC.ambientlight;
  lighting := 1;
   end;
      break;
     7: // screensize
      if SC.screensize then
      begin
  SC.screensize--;
  ShowMenuSliders(10-SC.screensize,10);
  timedelay := timecount+KBDELAY2;
  goright := false;
   end;
      break;
     8: // camera delay
      if SC.camdelay<70 then
      begin
  SC.camdelay++;
  ShowMenuSliders(SC.camdelay,70);
   end;
      break;
      end;
   MouseShow;
    end;
  end;


procedure MenuCommand;
begin

  if (keyboard[SC_ESCAPE]) and (timecount>timedelay) then
  begin
   downlevel := true;
   timedelay := timecount+KBDELAY2;
    end;

  if (keyboard[SC_UPARROW]) and (timecount>timedelay) then
  begin
   --menucursor;
   if (menucursor<0) menucursor := menumax[menulevel]-1;
   timedelay := timecount+KBDELAY2;
  end
  else if (keyboard[SC_DOWNARROW]) and (timecount>timedelay) then
  begin
   ++menucursor;
   if (menucursor = menumax[menulevel]) menucursor := 0;
   timedelay := timecount+KBDELAY2;
    end;

  if (keyboard[SC_RIGHTARROW]) and (timecount>timedelay) goright := true;
  else if (keyboard[SC_LEFTARROW]) and (timecount>timedelay) goleft := true;

  if (keyboard[SC_ENTER]) and (timecount>timedelay) then
  begin
   menuexecute := true;
   timedelay := timecount+KBDELAY2;
    end;
  end;
procedure MenuStub;
begin
  end;


procedure MenuShowCursor(int menucursor);
begin
  x, y, w, h, i: integer;

  if (menucursor = -1) or (menucursor = menucurloc) exit;
  MouseHide;
  VI_DrawMaskedPic(20,15,CA_CacheLump(CA_GetNamedNum('menumain')+menulevel));
  menucurloc := menucursor;
  x := cursors[menulevel][menucurloc].x;
  y := cursors[menulevel][menucurloc].y;
  w := cursors[menulevel][menucurloc].w;
  h := cursors[menulevel][menucurloc].h;
  memset(ylookup[y]+x,133,w);
  memset(ylookup[y+h-1]+x,133,w);
  for(i := y;i<y+h;i++)
  begin
   *(ylookup[i]+x) := 133;
   *(ylookup[i]+x+w-1) := 133;
    end;
  MouseShow;
  if (menulevel = 2) or (menulevel = 3) ShowSaveDir;
  if (menulevel = 4) MenuShowOptions;

  end;


procedure ShowMenuLevel(int level);
begin
  if menulevel = 0 then
  menumaincursor := menucursor;
  menulevel := level;
  MouseHide;
  VI_DrawMaskedPic(20,15,CA_CacheLump(CA_GetNamedNum('menumain')+level));
  MouseShow;
  if menulevel = 0 then
  menucursor := menumaincursor;
  else if (menulevel = 1)
  menucursor := 1;
  else if (menulevel = 2) or (menulevel = 3) then
  begin
   if saveposition>0 then
    menucursor := saveposition;
   else
    menucursor := 1;
    end;
  else
  menucursor := 2;
  menucurloc := -1;
  MenuShowCursor(menucursor);
  end;


procedure GetSavedName(int menucursor);
begin
  done: boolean;
  cursor, i: integer;

  MouseHide;
  cursor := 20;
  while (savedir[menucursor][cursor-1] = ' ') and (cursor>0) --cursor;
  if (cursor = 20) cursor := 19;
  savedir[menucursor][cursor] := '_';
  done := false;
  INT_TimerHook(NULL);
  lastascii := 0;
  newascii := false;
  while (not done) do
  begin
   printx := 148;
   printy := 34+menucursor*10;
   for(i := 0;i<6;i++)
    memset(ylookup[printy+i]+printx,0,100);
   FN_Printf(savedir[menucursor]);
   while (not newascii)   // wait for a new key
    MenuShowCursor(menucursor+1);
   case lastascii  of
   begin
     27:
      done := true;
      break;
     13:
      done := true;
      break;
     8:
      if cursor>0 then
      begin
  savedir[menucursor][cursor-1] := '_';
  memset and (savedir[menucursor][cursor],(int)' ',20-cursor);
  --cursor;
   end;
      break;
     default:
      if (isalnum(lastascii)) or (lastascii = ' ') or (lastascii = '.') or (
       lastascii = '-') or (lastascii = '_') or (lastascii = '!') or (lastascii = ',') or (
       lastascii = '?') or (lastascii = ''')
       begin
  savedir[menucursor][cursor] := lastascii;
  if (cursor<19) ++cursor;
  savedir[menucursor][cursor] := '_';
  break;
   end;
      end;
   newascii := false;
    end;
  savedir[menucursor][cursor] := ' ';
  if (lastascii = 27) ShowSaveDir;
  else
  begin
   downlevel := true;
   SaveDirectory;
   SaveGame(menucursor);
    end;
  timedelay := timecount+KBDELAY2;
  INT_TimerHook(MenuCommand);
  MouseShow;
  end;


procedure Execute(int level,int cursor);
begin
  case level  of
  begin
   0: // main menu
    case cursor  of
    begin
      0: // new game
       if (not netmode) ShowMenuLevel(1);
       break;
      1: // quit
       if (ShowQuit(MenuCommand)) then
       begin
   quitgame := true;
   quitmenu := true;
    end;
       break;
      2: // load
       if (not netmode) ShowMenuLevel(2);
       break;
      3: // save
       if (not netmode) and (gameloaded) ShowMenuLevel(3);
       break;
      4: // volume menu
       ShowMenuLevel(4);
       break;
      5: // info
       INT_TimerHook(NULL);
       MouseHide;
       ShowHelp;
       MouseShow;
       INT_TimerHook(MenuCommand);
       break;
      6: // resume
       quitmenu := true;
       break;
       end;
    break;
   1: // char selection
    case cursor  of
    begin
      0: // quit
       if (ShowQuit(MenuCommand)) then
       begin
   quitgame := true;
   quitmenu := true;
    end;
       break;
      1:
      2:
      3:
      4:
      5:
       identity := cursor-1;
       ShowMenuLevel(5);
       break;
      6: // resume
       downlevel := true;
       break;
       end;
    break;
   2: // load menu
    case cursor  of
    begin
      0: // quit
       if (ShowQuit(MenuCommand)) then
       begin
   quitgame := true;
   quitmenu := true;
    end;
       break;
      11: // back
       downlevel := true;
       break;
      default:
       MouseHide;
       LoadGame(menucursor-1);
       quitmenu := true;
       MouseShow;
       saveposition := cursor;
       break;
       end;
    break;
   3: // save menu
    case cursor  of
    begin
      0: // quit
       if (ShowQuit(MenuCommand)) then
       begin
   quitgame := true;
   quitmenu := true;
    end;
       break;
      11: // back
       downlevel := true;
       break;
      default:
       GetSavedName(menucursor-1);
       saveposition := cursor;
       break;
       end;
    break;
   4: // option menu
    case cursor  of
    begin
      0:
       ShowMenuLevel(1);
       break;
      1:
       if (ShowQuit(MenuCommand)) then
       begin
   quitgame := true;
   quitmenu := true;
    end;
       break;
      2: // music vol
      3: // sound vol
      4: // violence
      5: // animations
      6: // ambient light
      7: // screen size
      8: // camera delay
       break;
      9:
       downlevel := true;
       break;
       end;
    break;
   5: // difficulty selection
    case cursor  of
    begin
      0: // quit
       if (ShowQuit(MenuCommand)) then
       begin
   quitgame := true;
   quitmenu := true;
    end;
       break;
      1:
      2:
      3:
      4:
      5:
      6:
       timecount := 0;
       frames := 0;
       MouseHide;
{$IFDEF GAME1}
       newplayer(0,identity,6-cursor);
#elif defined(GAME2)
       newplayer(8,identity,6-cursor);
#elif defined(GAME3)
       newplayer(16,identity,6-cursor);
{$ELSE}
       newplayer(0,identity,6-cursor);
{$ENDIF}
       MouseShow;
       quitmenu := true;
       break;
      7:
       ShowMenuLevel(1);
       break;
       end;
    break;
    end;
  end;


procedure MenuAnimate;
begin
  lump: integer;
  pic_t   *frames[8];
  i, frame: integer;
  waittime: integer;

  if (netmode) exit;
  memcpy(viewbuffer,screen,64000);
  lump := CA_GetNamedNum('menuanim');
  for(i := 0;i<8;i++)
  frames[i] := CA_CacheLump(lump+i);
  frame := -1;
  waittime := timecount;
  while 1 do
  begin
   if timecount >= waittime then
   begin
     ++frame;
     if (frame = 8) break;
     VI_DrawMaskedPic2(20,15,frames[frame]);
     waittime := waittime + 7;
      end;
    end;
  for(i := 0;i<8;i++)
  CA_FreeLump(lump+i);
  end;


procedure CheckMouse;
begin
  i: integer;
  short    x, y;
  cursor_t *c;

  if (not MouseGetClick and (x,) and (y)) exit;

  for(i := 0;i<menumax[menulevel];i++)
  begin
   c := @cursors[menulevel][i];
   if (x<c.x+c.w) and (x>c.x) and (
       y<c.y+c.h) and (y>c.y)
       begin
     menucursor := i;
     MenuShowCursor(menucursor);
     menuexecute := true;
     exit;
      end;
    end;

  if menulevel = 4 then
  begin
   case menucursor  of
   begin
     2:
      if (y >= 49) and (y <= 64) and (x >= 42) and (x <= 90) then
      begin
  SC.musicvol := ((x-40)*256)/49;
  if (SC.musicvol>255) SC.musicvol := 255;
  SetVolumes(SC.musicvol,SC.sfxvol);
  ShowMenuSliders(SC.musicvol,255);
   end;
      break;
     3:
      if (y >= 49) and (y <= 64) and (x >= 42) and (x <= 90) then
      begin
  SC.sfxvol := ((x-40)*256)/49;
  if (SC.sfxvol>255) SC.sfxvol := 255;
  SetVolumes(SC.musicvol,SC.sfxvol);
  ShowMenuSliders(SC.sfxvol,255);
   end;
      break;
     4:
     5:
      if (y >= 62) and (y <= 70) then
      begin
  if (x >= 50) and (x <= 61) goleft := true;
  else if (x >= 72) and (x <= 83) goright := true;
   end;
      break;
     6:
      if (y >= 49) and (y <= 64) and (x >= 42) and (x <= 90) then
      begin
  SC.ambientlight := ((x-40)*4096)/49;
  if (SC.ambientlight>4096) SC.ambientlight := 4096;
  ShowMenuSliders(SC.ambientlight,4096);
  changelight := SC.ambientlight;
  lighting := 1;
   end;
      break;
     7:
      if (y >= 49) and (y <= 64) and (x >= 42) and (x <= 90) then
      begin
  SC.screensize := 9-(((x-40)*10)/49);
  if (SC.screensize>9) SC.screensize := 9;
  else if (SC.screensize<0) SC.screensize := 0;
  ShowMenuSliders(10-SC.screensize,10);
   end;
      break;
     8:
      if (y >= 49) and (y <= 64) and (x >= 42) and (x <= 90) then
      begin
  SC.camdelay := ((x-40)*70)/49;
  if (SC.camdelay>70) SC.camdelay := 70;
  ShowMenuSliders(SC.camdelay,70);
   end;
      break;
      end;
    end;
  end;


procedure ShowMenu(int n);
begin
  byte *scr;

  timedelay := timecount+KBDELAY2;
  INT_TimerHook(MenuCommand);

  scr := (byte *)malloc(64000);
  if (scr = NULL) MS_Error('ShowMenu: Out of Memory!');
  memcpy(scr,screen,64000);
  if (SC.animation) MenuAnimate;
  MouseShow;
  ShowMenuLevel(n);
  quitmenu := false;
  do
  begin
   MenuShowCursor(menucursor);
   CheckMouse;
   if menuexecute then
   begin
     Execute(menulevel,menucursor);
     menuexecute := false;
      end;
   if downlevel then
   begin
     if (menulevel = 0) quitmenu := true;
      else ShowMenuLevel(0);
     downlevel := false;
      end;
   if goright then
   begin
     MenuRight;
     goright := false;
      end;
   if goleft then
   begin
     MenuLeft;
     goleft := false;
      end;
   if (netmode) TimeUpdate;
    end; while (not quitmenu);
  MouseHide;
  memcpy(screen,scr,64000);
  free(scr);
  if gameloaded then
  begin
   if SC.vrhelmet = 0 then
   begin
     while currentViewSize<SC.screensize do
      ChangeViewSize(true);
     while currentViewSize>SC.screensize do
      ChangeViewSize(false);
      end;
    end;
  SaveSetup and (SC,'SETUP.CFG');
  turnrate := 0;
  moverate := 0;
  fallrate := 0;
  strafrate := 0;
  ResetMouse;
  end;

(**************************************************************************)

procedure ShowHelp;
begin
  byte *s;
{$IFDEF ASSASSINATOR}
  FILE *f;
{$ENDIF}

  s := (byte *)malloc(64000);
  if (s = NULL) MS_Error('Error Allocating in ShowHelp');
  memcpy(s,screen,64000);
  VI_FillPalette(0,0,0);
  memset(screen,0,64000);

{$IFDEF ASSASSINATOR}
  f := fopen('help.dat','rb');
  if f = NULL then
  MS_Error('Error Loading Help.Dat file');
  fread(screen,64000,1,f);
  fread(colors,768,1,f);
  fclose(f);
{$ELSE}
  loadscreen('INFO1');
{$ENDIF}
  VI_SetPalette(colors);
  newascii := false;
  for(;)
  begin
   Wait(10);
   if (netmode) TimeUpdate;
   if (newascii) break;
    end;
  VI_FillPalette(0,0,0);
  memset(screen,0,64000);

{$IFDEF DEMO}
  loadscreen('INFO2');
  VI_SetPalette(colors);
  newascii := false;
  for(;)
  begin
   Wait(10);
   if (netmode) TimeUpdate;
   if (newascii) break;
    end;
  VI_FillPalette(0,0,0);
  memset(screen,0,64000);

  loadscreen('INFO3');
  VI_SetPalette(colors);
  newascii := false;
  for(;)
  begin
   Wait(10);
   if (netmode) TimeUpdate;
   if (newascii) break;
    end;
  memset(screen,0,64000);
  VI_FillPalette(0,0,0);
{$ENDIF}

  VI_SetPalette(CA_CacheLump(CA_GetNamedNum('palette')));
  memcpy(screen,s,64000);
  free(s);
  end;

(**************************************************************************)

bool CheckPause
begin
  if netmode then
  begin
   NetGetData;
   if (not gamepause) return  not netpaused;
    else return newascii;
    end;
  return newascii;
  end;


procedure ShowPause;
begin
  animtime, droptime: integer;
  anim, y, i: integer;
  lump: integer;
  pic_t   *pics[4];

  INT_TimerHook(NULL);
  memcpy(viewbuffer,screen,64000);
  lump := CA_GetNamedNum('pause');
  for(i := 0;i<4;i++) pics[i] := CA_CacheLump(lump+i);
  timedelay := timecount+KBDELAY2;
  Wait(KBDELAY2);
  anim := 0;
  if (not SC.animation) y := 72;
  else y := -56;
  droptime := timecount;
  animtime := timecount;
  newascii := false;
  while not CheckPause do
  begin
   if (timecount >= droptime) and (y<72) then
   begin
     if (y >= 0) memcpy(ylookup[y],viewbuffer+320*y,640);
     y := y + 2;
     droptime := timecount+1;
      end;
   if timecount >= animtime then
   begin
     anim++;
     anim) and (:= 3;
     animtime := animtime + 10;
      end;
   VI_DrawMaskedPic2(106,y,pics[anim]);
    end;
  if (not SC.animation) y := 200;
  droptime := timecount;
  animtime := timecount;
  while y<199 do
  begin
   if timecount >= droptime then
   begin
     if (y >= 0) memcpy(ylookup[y],viewbuffer+320*y,640);
     y := y + 2;
     droptime := timecount+1;
      end;
   if timecount >= animtime then
   begin
     anim++;
     anim) and (:= 3;
     animtime := animtime + 10;
      end;
   VI_DrawMaskedPic2(106,y,pics[anim]);
    end;
  memcpy(screen,viewbuffer,64000);
  for (i := 0;i<4;i++)
  CA_FreeLump(lump+i);
  end;

(*****************************************************************************)

procedure StartWait;
begin
  i, lump: integer;

  memcpy(viewbuffer,screen,64000);
  lump := CA_GetNamedNum('wait');
  for(i := 0;i<4;i++) waitpics[i] := CA_CacheLump(lump+i);
  waitanim := 0;
  VI_DrawMaskedPic2(106,72,waitpics[0]);
  timedelay := timecount+10;
  waiting := true;
  end;


procedure UpdateWait;
begin
  if timecount>timedelay then
  begin
   ++waitanim;
   waitanim) and (:= 3;
   VI_DrawMaskedPic2(106,72,waitpics[waitanim]);
   timedelay := timecount+10;
    end;
  end;


procedure EndWait;
begin
  lump, i: integer;

  lump := CA_GetNamedNum('wait');
  for(i := 0;i<4;i++) CA_FreeLump(lump+i);
  memcpy(screen,viewbuffer,64000);
  waiting := false;
  end;

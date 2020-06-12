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
#include <STRING.H>
#include <CONIO.H>
#include <STDIO.H>
#include <IO.H>
#include <STDLIB.H>
#include 'd_global.h'
#include 'd_video.h'
#include 'd_ints.h'
#include 'd_misc.h'
#include 'timer.h'
#include 'protos.h'
#include 'r_refdef.h'
#include 'd_disk.h'

(**** CONSTANTS ****)

#define TIMERINT       8
#define KEYBOARDINT    9
#define VBLCOUNTER     16000
#define MOUSEINT       $33
#define MOUSESENSE     SC.mousesensitivity
#define JOYPORT        $201
#define MOUSESIZE      16


(**** VARIABLES ****)

procedure (*oldkeyboardisr);
procedure (*timerhook);                 // called every other frame (player);
  timeractive: boolean;
longint timecount;                     // current time index
bool keyboard[NUMCODES];             // keyboard flags
  pause, capslock, newascii: boolean;
  mouseinstalled, joyinstalled: boolean;
int     in_button[NUMBUTTONS];          // frames the button has been down
byte    lastscan;
char    lastascii;

(* mouse data *)
short mdx, mdy, b1, b2;
int   hiding := 1, busy := 1;           (* internal flags *)
  mousex := 160, mousey := 100: integer;
byte  back[MOUSESIZE*MOUSESIZE];  (* background for mouse *)
byte  fore[MOUSESIZE*MOUSESIZE];  (* mouse foreground *)


(* joystick data *)
  jx, jy, jdx, jdy, j1, j2: integer;
word  jcenx, jceny, xsense, ysense;

(* config data *)
//extern SoundCard SC;


byte ASCIINames[] :=  // Unshifted ASCII for scan codes
begin
  0  ,27 ,'1','2','3','4','5','6','7','8','9','0','-',' := ',8  ,9  ,
  'q','w','e','r','t','y','u','i','o','p','[',']',13 ,0  ,'a','s',
  'd','f','g','h','j','k','l',';',39 ,'`',0  ,92 ,'z','x','c','v',
  'b','n','m',',','.','/',0  ,'*',0  ,' ',0  ,0  ,0  ,0  ,0  ,0  ,
  0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,'-',0  ,0  ,0  ,'+',0  ,
  0  ,0  ,0  ,127,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,
  0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,
  0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0
   end;

byte ShiftNames[] :=  // Shifted ASCII for scan codes
begin
  0  ,27 ,'!','@','#','$','%',') xor (',') and (','*','(',')','_','+',8  ,9  ,
  'Q','W','E','R','T','Y','U','I','O','P',' begin ',' end;',13 ,0  ,'A','S',
  'D','F','G','H','J','K','L',':',34 ,'~',0  ,') or (','Z','X','C','V',
  'B','N','M','<','>','?',0  ,'*',0  ,' ',0  ,0  ,0  ,0  ,0  ,0  ,
  0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,'-',0  ,0  ,0  ,'+',0  ,
  0  ,0  ,0  ,127,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,
  0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,
  0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0
   end;

byte SpecialNames[] :=  // ASCII for $e0 prefixed codes
begin
  0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,
  0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,13 ,0  ,0  ,0  ,
  0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,
  0  ,0  ,0  ,0  ,0  ,'/',0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,
  0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,
  0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,
  0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,
  0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0  ,0
   end;

int scanbuttons[NUMBUTTONS] := 
begin
  SC_UPARROW,       // bt_north
  SC_RIGHTARROW,    // bt_east
  SC_DOWNARROW,     // bt_south
  SC_LEFTARROW,     // bt_west
  SC_CONTROL,       // bt_fire
  SC_ALT,           // bt_straf
  SC_SPACE,         // bt_use
  SC_LSHIFT,        // bt_run
  SC_Z,             // bt_jump
  SC_X,             // bt_useitem
  SC_A,             // bt_asscam
  SC_PGUP,          // bt_lookup
  SC_PGDN,          // bt_lookdown
  SC_HOME,          // bt_centerview
  SC_COMMA,         // bt_slideleft
  SC_PERIOD,        // bt_slideright
  SC_INSERT,        // bt_invleft
  SC_DELETE,        // bt_invright
  end;


(**** FUNCTIONS ****)


void INT_KeyboardISR
(* keyboard interrupt
    processes make/break codes
    sets key flags accordingly *)
    begin
  (*static bool special;
  byte           k, c, al;

// Get the scan code
  k := inbyte(0x60);

  if (k = $E0) special := true;
  else if (k = $E1) pause) xor (:= true;
  else
  begin
   if (special) and ((k = $2A) or (k = $AA) or (k = $AA) or (k = $36)) then
   begin
     special := false;
     goto end;
      end;
   if (k) and (0x80) // Break code
   begin
     k) and (:= $7F;
     keyboard[k] := false;
      end;
   else // Make code
   begin
     lastscan := k;
     keyboard[k] := true;
     if (special) c := SpecialNames[k];
     else
     begin
       if (k = SC_CAPSLOCK) capslock) xor (:= true;
       if (keyboard[SC_LSHIFT]) or (keyboard[SC_RSHIFT]) then
       begin
   c := ShiftNames[k];
   if (capslock) and (c >= 'A') and (c <= 'Z') c+:= 'a'-'A';
    end;
       else
       begin
   c := ASCIINames[k];
   if (capslock) and (c >= 'a') and (c <= 'z') c-:= 'a'-'A';
    end;
        end;
     if (c)         // return a new ascii character
     begin
       lastascii := c;
       newascii := true;
        end;
      end;
   special := false;
    end;
end:
// acknowledge the interrupt
  al := inbyte(0x61);
  al) or (:= $80;
  outbyte(0x61,al);
  al) and (:= $7F;
  outbyte(0x61,al);
  outbyte(0x20,0x20);*)
  end;


procedure INT_ReadControls;
(* read in input controls *)
begin
  i: integer;
  BYTE keybkeys[256];

  i :=  MapVirtualKey(SC_A,1);

  GetKeyboardState(keybkeys);
  for (i :=  0 ; i < 128 ; i++)
   keyboard[i] :=  GetAsyncKeyState(MapVirtualKey(i,1));
  for (i :=  0 ; i < 128 ; i++)
   keyboard[i] :=  keybkeys[i];
  for (i :=  0 ; i < 128 ; i++)
   keyboard[i] :=  GetKeyState(MapVirtualKey(i,1));

  memset(in_button,0,sizeof(in_button));
  for(i := 0;i<NUMBUTTONS;i++)
  if (keyboard[scanbuttons[i]]) and (0x80) then
   in_button[i] := 1;

  if mouseinstalled then
  begin
    end;
  end;

(* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = *)

procedure INT_TimerISR;
(* process each timer tick *)
begin
  timecount := timecount + 2;
  if timerhook then
    timerhook;
  end;


procedure INT_TimerHook(void(* hook););
begin
  timerhook := hook;
  end;


(* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = *)

procedure UpdateMouse;
begin
  end;


int MouseGetClick(short *x,short *y)
begin
  return 0;
  end;

procedure ResetMouse;
begin
  end;


procedure M_Init;
begin
   mouseinstalled := false;
   printf('Mouse Not Found\n');
   exit;
  end;


procedure M_Shutdown;
begin
  end;


(***************************************************************************)

procedure INT_Setup;
begin
  memset(keyboard,0,sizeof(keyboard));
  M_Init;
  dStartTimer(INT_TimerISR,1000/35);
  timeractive :=  true;
  end;


procedure INT_ShutdownKeyboard;
begin
  INT_TimerHook(NULL);
  end;


procedure INT_Shutdown;
begin
  if timeractive then
   dStopTimer;
  if mouseinstalled then
   M_Shutdown;
  end;


void MouseHide
begin
  end;

void MouseShow
begin
  end;

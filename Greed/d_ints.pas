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

unit d_ints;

interface

uses
  g_delphi,
  d_ints_h;

const
  MOUSESIZE = 16;

var
  timerhook: PProcedure;  // called every other frame (player);
  timeractive: boolean;
  timecount: integer; // current time index
  keyboard: array[0..NUMCODES - 1] of boolean;  // keyboard flags
  pause, capslock, newascii: boolean;
  mouseinstalled, joyinstalled: boolean;
  in_button: array[0..NUMBUTTONS - 1] of integer; // frames the button has been down
  lastscan: byte;
  lastascii: char;

(* mouse data *)
  mdx, mdy, b1, b2: smallint;
  hiding: integer = 1;
  busy: integer = 1;  // internal flags
  mousex: integer = 160;
  mousey: integer = 100;
  back: array[0..MOUSESIZE * MOUSESIZE - 1] of byte;  // background for mouse
  fore: array[0..MOUSESIZE * MOUSESIZE - 1] of byte;  // mouse foreground


(* joystick data *)
  jx, jy, jdx, jdy, j1, j2: integer;
  jcenx, jceny, xsense, ysense: word;

(* config data *)
//extern SoundCard SC;

const
  ASCIINames: array[0..127] of char = ( // Unshifted ASCII for scan codes
    #0, #27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', #8, #9,
    'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', #13, #0, 'a', 's',
    'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', #39, '`', #0, #92, 'z', 'x', 'c', 'v',
    'b', 'n', 'm', ',', '.', '/', #0, '*', #0, ' ', #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, '-', #0, #0, #0, '+', #0,
    #0, #0, #0, #127, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0
  );

const
  ShiftNames: array[0..127] of char = ( // Shifted ASCII for scan codes
    #0, #27, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', #8, #9,
    'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', #13, #0, 'A', 'S',
    'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', #34, '~', #0, '|', 'Z', 'X', 'C', 'V',
    'B', 'N', 'M', '<', '>', '?', #0, '*', #0, ' ', #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, '-', #0, #0, #0, '+', #0,
    #0, #0, #0, #127, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0
  );

const
  SpecialNames: array[0..127] of char = ( // ASCII for $e0 prefixed codes
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, 
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #13, #0, #0, #0, 
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, 
    #0, #0, #0, #0, #0, '/', #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, 
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, 
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, 
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, 
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0
  );

const
  scanbuttons: array[0..NUMBUTTONS - 1] of integer = (
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
    SC_DELETE         // bt_invright
  );


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


procedure INT_TimerHook(const hook: PProcedure);
begin
  timerhook := hook;
end;


(* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = *)

procedure UpdateMouse;
begin
end;


function MouseGetClick(short *x,short *y): boolean;
begin
  return 0;
end;

procedure ResetMouse;
begin
end;


procedure M_Init;
begin
  mouseinstalled := false;
  printf('Mouse Not Found'#13#10);
end;


procedure M_Shutdown;
begin
end;


(***************************************************************************)

procedure INT_Setup;
begin
  memset(keyboard, 0, SizeOf(keyboard));
  M_Init;
  dStartTimer(INT_TimerISR, 1000/35);
  timeractive := true;
end;


procedure INT_ShutdownKeyboard;
begin
  INT_TimerHook(nil);
end;


procedure INT_Shutdown;
begin
  if timeractive then
    dStopTimer;
  if mouseinstalled then
    M_Shutdown;
end;


procedure MouseHide;
begin
end;

procedure MouseShow;
begin
end;

end;

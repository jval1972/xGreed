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
  gametic: integer = 0;
  keyboard: array[0..NUMCODES - 1] of smallint;  // keyboard flags
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

const
  TICRATE = 70;

procedure INT_ReadControls;

procedure INT_TimerISR;

procedure INT_TimerHook(const hook: PProcedure);

procedure INT_Shutdown;

function MouseGetClick(var x, y: smallint): boolean;

procedure ResetMouse;

procedure MouseHide;

procedure MouseShow;

procedure UpdateMouse;

procedure INT_Setup;

implementation

uses
  i_windows,
  windows,
  timer;

var
  oldkeyboard: array[0..NUMCODES - 1] of smallint;  // keyboard flags

// read in input controls
procedure INT_ReadControls;
var
  i: integer;
  c: char;
  key: integer;
begin
  lastascii := #0;
  for i := 0 to NUMCODES - 1 do
  begin
    key := I_MapVirtualKey(i, 1);
    keyboard[i] := I_GetKeyState(key);
    if keyboard[i] and $80 <> 0 then
      if oldkeyboard[i] and $80 = 0 then
      begin
        c := toupper(ASCIINames[i]);
        if c <> #0 then
        begin
          lastascii := c;
          newascii := true;
        end;
      end;
  end;

  memset(@in_button, 0, SizeOf(in_button));
  for i := 0 to NUMBUTTONS - 1 do
    if keyboard[scanbuttons[i]] and $80 <> 0 then
      in_button[i] := 1;

  for i := 0 to NUMCODES - 1 do
  begin
    oldkeyboard[i] := keyboard[i];
    if keyboard[i] and $80 <> 0 then
      keyboard[i] := 1
    else
      keyboard[i] := 0;
  end;

  if mouseinstalled then
  begin
  end;
end;

// process each timer tick
procedure INT_TimerISR;
begin
//  if timecount and 1 <> 0 then
  inc(timecount);
  inc(gametic);
  if timecount and 1 <> 0 then
  begin
    INT_ReadControls;
    if Assigned(timerhook) then
      timerhook;
  end;
end;


procedure INT_TimerHook(const hook: PProcedure);
begin
  timerhook := hook;
end;


procedure UpdateMouse;
begin
end;

function MouseGetClick(var x, y: smallint): boolean;
begin
  result := false;
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

procedure INT_Setup;
begin
  memset(@keyboard, 0, SizeOf(keyboard));
  M_Init;
  dStartTimer(INT_TimerISR, TICRATE);
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

end.


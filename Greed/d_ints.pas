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
  invertmouseturn, invertmouselook: boolean;
  in_button: array[0..NUMBUTTONS - 1] of integer; // frames the button has been down
  lastscan: byte;
  lastascii: char;

(* mouse data *)
  mdx, mdy, b1, b2: smallint;
  hiding: integer = 1;
  busy: integer = 1;  // internal flags
  // For hud
  mousehx: float = 160.0;
  mousehy: float = 100.0;
  mousevisible: boolean = false;
  mcursor: array[0..MOUSESIZE * MOUSESIZE - 1] of byte;  // mouse foreground
  // For gameplay
  mousedx: integer = 0;
  mousedy: integer = 0;
  mousebuttons: array[0..NUMMBUTTONS - 1] of boolean;
  mousesensitivityx: integer = 10;
  mousesensitivityy: integer = 5;
  lbuttondown: boolean = false;
  mbuttondown: boolean = false;
  rbuttondown: boolean = false;

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
    SC_DELETE,        // bt_invright
    SC_S              // bt_motionmode
  );

const
  TICRATE = 70;

procedure INT_ReadControls;

procedure INT_ReadMouse;

procedure eat_key(const k: integer);

procedure INT_TimerISR;

procedure INT_TimerHook(const hook: PProcedure);

procedure INT_Shutdown;

function MouseGetClick(var x, y: smallint): boolean;

procedure ResetMouse;

procedure MouseHide;

procedure MouseShow;

procedure UpdateMouse;

procedure INT_Setup;

type
  mouse_t = record
    oldflags: integer;
    flags: integer;
    dx, dy: integer;
  end;

var
  mouse: mouse_t;

procedure I_SynchronizeInput(active: boolean);

var
  menuusemouse: boolean = true;
  waitISR: boolean = false;

implementation

uses
  windows,
  d_disk,
  i_main,
  i_windows,
  i_video,
  modplay,
  timer;

var
  ignoretics: integer = 0;

const
  I_IGNORETICKS = TICRATE div 2;

procedure I_SynchronizeInput(active: boolean);
begin
  if active then
    ignoretics := I_IGNORETICKS; // Wait ~ half second when get the focus again
  lbuttondown := false;
  mbuttondown := false;
  rbuttondown := false;
end;

var
  oldkeyboard: array[0..NUMCODES - 1] of smallint;  // keyboard flags

// read in input controls
procedure INT_ReadControls;
var
  i: integer;
  c: char;
  key: integer;
  kstate: integer;
begin
  if GameFinished or InBackground or
     IsIconic(hMainWnd) or (GetForegroundWindow <> hMainWnd) then
    exit;

  if ignoretics > 0 then
  begin
    Dec(ignoretics);
    exit;
  end;

  lastascii := #0;
  for i := 0 to NUMCODES - 1 do
  begin
    key := I_MapVirtualKey(i, 1);
    kstate := I_GetKeyState(key);
    if kstate and $80 <> 0 then
    begin
      if keyboard[i] = 0 then
        keyboard[i] := 1;
      if oldkeyboard[i] = 0 then
      begin
        c := toupper(ASCIINames[i]);
        if c <> #0 then
        begin
          lastascii := c;
          newascii := true;
        end;
      end;
    end
    else
      keyboard[i] := 0;
  end;

  memset(@in_button, 0, SizeOf(in_button));
  for i := 0 to NUMBUTTONS - 1 do
    if keyboard[scanbuttons[i]] <> 0 then
      in_button[i] := 1;

  for i := 0 to NUMCODES - 1 do
    oldkeyboard[i] := keyboard[i];

  if mouseinstalled then
    INT_ReadMouse
  else
    FillChar(mouse, SizeOf(mouse), #0);
end;

procedure eat_key(const k: integer);
begin
  if keyboard[k] = 1 then
    keyboard[k] := 2;
end;

// process each timer tick
procedure INT_TimerISR;
begin
  while waitISR do
    I_Sleep(0);
  inc(timecount);
  inc(gametic);
  if timecount and 1 <> 0 then
    INT_ReadControls;
  if Assigned(timerhook) then
    timerhook;
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
  if not menuusemouse then
  begin
    result := false;
    exit;
  end;

  result := (mouse.flags and 1 <> 0) and (mouse.oldflags and 1 = 0);
  if result then
  begin
    mouse.oldflags := mouse.oldflags or 1;
    x := round(mousehx);
    y := round(mousehy);
  end;
end;

type
  setcursorposfunc_t = function(x, y:Integer): BOOL; stdcall;
  getcursorposfunc_t = function(var lpPoint: TPoint): BOOL; stdcall;

var
  getcursorposfunc: getcursorposfunc_t;
  setcursorposfunc: setcursorposfunc_t;
  user32inst: THandle;

var
// Mouse support
  mlastx,
  mlasty: integer;
  mflags: byte;

procedure ResetMouse;
begin
  mlastx := I_WindowWidth div 2;
  mlasty := I_WindowHeight div 2;
  setcursorposfunc(mlastx, mlasty);
  mflags := 0;
end;

procedure M_InitMouse;
var
  lump: integer;
begin
  printf('M_InitMouse: Initializing Mouse'#13#10);
  user32inst := LoadLibrary(user32);
  getcursorposfunc := GetProcAddress(user32inst, 'GetPhysicalCursorPos');
  if not assigned(getcursorposfunc) then
    getcursorposfunc := GetProcAddress(user32inst, 'GetCursorPos');
  setcursorposfunc := GetProcAddress(user32inst, 'SetPhysicalCursorPos');
  if not assigned(setcursorposfunc) then
    setcursorposfunc := GetProcAddress(user32inst, 'SetCursorPos');
  mouseinstalled := Assigned(getcursorposfunc) and Assigned(setcursorposfunc);
  if mouseinstalled then
    printf(' Mouse installed'#13#10)
  else
    printf(' Mouse not installed'#13#10);
 lump := CA_GetNamedNum('MCURSOR');
 seek(cachehandle, infotable[lump].filepos + 8);
 fread(@mcursor, MOUSESIZE * MOUSESIZE, 1, cachehandle);
end;

procedure M_Shutdown;
begin
  FreeLibrary(user32inst);
end;


procedure INT_ReadMouse;
var
  pt: TPoint;
begin
  mflags := 0;

  if lbuttondown then
    mflags := mflags or 1;
  if rbuttondown then
    mflags := mflags or 2;
  if mbuttondown then
    mflags := mflags or 4;

  getcursorposfunc(pt);

  mouse.oldflags := mouse.flags;
  mouse.flags := mflags;
  mouse.dx := mlastx - pt.x;
  mouse.dy := mlasty - pt.y;

  if mousevisible then
  begin
    mousehx := mousehx - mouse.dx * 320 / I_WindowWidth;
    if mousehx < 0.0 then
      mousehx := 0.0
    else if mousehx > 319.0 then
      mousehx := 319.0;
    mousehy := mousehy - mouse.dy * 200 / I_WindowHeight;
    if mousehy < 0.0 then
      mousehy := 0.0
    else if mousehy > 199.0 then
      mousehy := 199.0;
  end;

  ResetMouse;
end;

procedure INT_Setup;
begin
  memset(@keyboard, 0, SizeOf(keyboard));
  M_InitMouse;
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
  M_Shutdown;
end;


procedure MouseHide;
begin
  mousevisible := false;
end;


procedure MouseShow;
begin
  mousevisible := menuusemouse;
end;

end.


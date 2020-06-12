
unit d_ints_h;
interface

{
  Automatically converted by H2Pas 1.0.0 from D_ints.h
  The following command line parameters were used:
    -o
    d_ints_h.pas
    D_ints.h
}

    Type
    Psmallint  = ^smallint;
{$IFDEF FPC}
{$PACKRECORDS C}
{$ENDIF}


  {************************************************************************* }
  {                                                                          }
  {                                                                          }
  { Raven 3D Engine                                                          }
  { Copyright (C) 1995 by Softdisk Publishing                                }
  {                                                                          }
  { Original Design:                                                         }
  {  John Carmack of id Software                                             }
  {                                                                          }
  { Enhancements by:                                                         }
  {  Robert Morgan of Channel 7............................Main Engine Code  }
  {  Todd Lewis of Softdisk Publishing......Tools,Utilities,Special Effects  }
  {  John Bianca of Softdisk Publishing..............Low-level Optimization  }
  {  Carlos Hasan..........................................Music/Sound Code  }
  {                                                                          }
  {                                                                          }
  {************************************************************************* }
{$ifndef D_INTS_H}
{$define D_INTS_H}  
  {*** CONSTANTS *** }

  const
    NUMCODES = 128;    
    SC_NONE = 0;    
    SC_BAD = $ff;    
(* error 
#define SC_ENTER                0X1c
in define line 27 *)
      SC_ESCAPE = $01;      
      SC_SPACE = $39;      
      SC_BACKSPACE = $0e;      
      SC_TAB = $0f;      
      SC_ALT = $38;      
      SC_CONTROL = $1d;      
      SC_CAPSLOCK = $3a;      
      SC_NUMLOCK = $45;      
      SC_SCROLLLOCK = $46;      
      SC_LSHIFT = $2a;      
      SC_RSHIFT = $36;      
      SC_UPARROW = $48;      
      SC_DOWNARROW = $50;      
      SC_LEFTARROW = $4b;      
      SC_RIGHTARROW = $4d;      
      SC_INSERT = $52;      
      SC_DELETE = $53;      
      SC_HOME = $47;      
      SC_END = $4f;      
      SC_PGUP = $49;      
      SC_PGDN = $51;      
      SC_TILDA = $29;      
      SC_COMMA = $33;      
      SC_PERIOD = $34;      
      SC_F1 = $3b;      
      SC_F2 = $3c;      
      SC_F3 = $3d;      
      SC_F4 = $3e;      
      SC_F5 = $3f;      
      SC_F6 = $40;      
      SC_F7 = $41;      
      SC_F8 = $42;      
      SC_F9 = $43;      
      SC_F10 = $44;      
      SC_F11 = $D9;      
      SC_F12 = $DA;      
      SC_1 = $02;      
      SC_2 = $03;      
      SC_3 = $04;      
      SC_4 = $05;      
      SC_5 = $06;      
      SC_6 = $07;      
      SC_7 = $08;      
      SC_8 = $09;      
      SC_9 = $0a;      
      SC_0 = $0b;      
      SC_A = $1e;      
      SC_B = $30;      
      SC_C = $2e;      
      SC_D = $20;      
      SC_E = $12;      
      SC_F = $21;      
      SC_G = $22;      
      SC_H = $23;      
      SC_I = $17;      
      SC_J = $24;      
      SC_K = $25;      
      SC_L = $26;      
      SC_M = $32;      
      SC_N = $31;      
      SC_O = $18;      
      SC_P = $19;      
      SC_Q = $10;      
      SC_R = $13;      
      SC_S = $1f;      
      SC_T = $14;      
      SC_U = $16;      
      SC_V = $2f;      
      SC_W = $11;      
      SC_X = $2d;      
      SC_Y = $15;      
      SC_Z = $2c;      
      SC_MINUS = $0c;      
      SC_PLUS = $0d;      
      NUMBUTTONS = 18;      
      bt_north = 0;      
      bt_east = 1;      
      bt_south = 2;      
      bt_west = 3;      
      bt_fire = 4;      
      bt_straf = 5;      
      bt_use = 6;      
      bt_run = 7;      
      bt_jump = 8;      
      bt_useitem = 9;      
      bt_asscam = 10;      
      bt_lookup = 11;      
      bt_lookdown = 12;      
      bt_centerview = 13;      
      bt_slideleft = 14;      
      bt_slideright = 15;      
      bt_invleft = 16;      
      bt_invright = 17;      
    {*** VARIABLES *** }

      var
        keyboard : array[0..(NUMCODES)-1] of bool;cvar;external;
        pause : bool;cvar;external;
        lastscan : byte;cvar;external;
        timeractive : bool;cvar;external;
        timecount : longint;cvar;external;
        scanbuttons : array[0..(NUMBUTTONS)-1] of longint;cvar;external;
        in_button : array[0..(NUMBUTTONS)-1] of longint;cvar;external;
        lastascii : char;cvar;external;
    {*** FUNCTIONS *** }

    procedure INT_Setup;

    procedure INT_Shutdown;

    procedure INT_TimerHook(hook:procedure );

    procedure INT_ReadControls;

    procedure INT_ShutdownKeyboard;

    procedure UpdateMouse;

    procedure MouseShow;

    procedure MouseHide;

    function MouseGetClick(x:Psmallint; y:Psmallint):longint;

    procedure ResetMouse;

{$endif}

implementation

    procedure INT_Setup;
    begin
      { You must implement this function }
    end;
    procedure INT_Shutdown;
    begin
      { You must implement this function }
    end;
    procedure INT_TimerHook(hook:procedure );
    begin
      { You must implement this function }
    end;
    procedure INT_ReadControls;
    begin
      { You must implement this function }
    end;
    procedure INT_ShutdownKeyboard;
    begin
      { You must implement this function }
    end;
    procedure UpdateMouse;
    begin
      { You must implement this function }
    end;
    procedure MouseShow;
    begin
      { You must implement this function }
    end;
    procedure MouseHide;
    begin
      { You must implement this function }
    end;
    function MouseGetClick(x:Psmallint; y:Psmallint):longint;
    begin
      { You must implement this function }
    end;
    procedure ResetMouse;
    begin
      { You must implement this function }
    end;

end.
(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020 by Jim Valavanis                                     *)
(*                                                                         *)
(*                   Digital Sound Interface Kit (DSIK)                    *)
(*                            Version 2.00                                 *)
(*                                                                         *)
(*                           by Carlos Hasan                               *)
(*                                                                         *)
(* Filename:     timer.c                                                   *)
(* Version:      Revision 1.1                                              *)
(*                                                                         *)
(* Language:     WATCOM C                                                  *)
(* Environment:  IBM PC (DOS/4GW)                                          *)
(*                                                                         *)
(* Description:  Timer interrupt services.                                 *)
(*                                                                         *)
(* Revision History:                                                       *)
(* ----------------                                                        *)
(*                                                                         *)
(* Revision 1.1  94/11/16  10:48:42  chv                                   *)
(* Added VGA vertical retrace synchronization code                         *)
(*                                                                         *)
(* Revision 1.0  94/10/28  22:45:47  chv                                   *)
(* Initial revision                                                        *)
(*                                                                         *)
(***************************************************************************)

unit timer;

interface

uses
  g_delphi;

procedure dStopTimer;

procedure dStartTimer(const atimer: PProcedure; const rate: integer);

implementation

uses
  i_windows;

var
  User_Timer: PProcedure;
  Timer_Event: LongWord;

procedure TimerHandler(uTimerID, uMsg: LongWord; dwUser, dw1, dw2: LongWord); stdcall;
begin
  User_Timer;
end;

procedure dStopTimer;
begin
  I_timeKillEvent(Timer_Event);
end;

procedure dStartTimer(const atimer: PProcedure; const rate: integer);
begin
  User_Timer := atimer;
  Timer_Event := I_timeSetEvent(1000 div rate, 10, TimerHandler, 0, TSE_TIME_PERIODIC);
end;

end.

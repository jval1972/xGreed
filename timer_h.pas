
unit timer_h;
interface

{
  Automatically converted by H2Pas 1.0.0 from Timer.h
  The following command line parameters were used:
    -o
    timer_h.pas
    Timer.h
}

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
{$ifndef __TIMER_H}
{$define __TIMER_H}  
  { Timer services API prototypes  }

  type

    TimerProc = procedure (_para1:pointer);cdecl;

  procedure dStartTimer(Timer:TimerProc; Speed:longint);

  procedure dStopTimer;

{$endif}

implementation

  procedure dStartTimer(Timer:TimerProc; Speed:longint);
  begin
    { You must implement this function }
  end;
  procedure dStopTimer;
  begin
    { You must implement this function }
  end;

end.


unit d_global_h;
interface

{
  Automatically converted by H2Pas 1.0.0 from D_global.h
  The following command line parameters were used:
    -o
    d_global_h.pas
    D_global.h
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
{$ifndef GLOBAl_H}
{$define GLOBAL_H}  
{$include <Windows.h>}
  {#define PARMCHECK }
  {#define VALIDATE }

  type
    byte = byte;

    word = word;

    longint = dword;

    bool = (false,true);
{$endif}

implementation


end.

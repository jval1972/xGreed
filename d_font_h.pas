
unit d_font_h;
interface

{
  Automatically converted by H2Pas 1.0.0 from D_font.h
  The following command line parameters were used:
    -o
    d_font_h.pas
    D_font.h
}

  Type
  Pchar  = ^char;
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
{$ifndef __FONT__}
{$define __FONT__}  
  {*** CONSTANTS *** }

  const
    MAXPRINTF = 256;    
    MSGTIME = 350;    
  {*** TYPES *** }
(** unsupported pragma#pragma pack(push,packing,1)*)

  type
    font_t = record
        height : smallint;
        width : array[0..255] of char;
        charofs : array[0..255] of smallint;
      end;
(** unsupported pragma#pragma pack(pop,packing)*)
  {*** VARIABLES *** }

    var
      font : ^font_t;cvar;external;
      fontbasecolor : longint;cvar;external;
      fontspacing : longint;cvar;external;
      printx : longint;cvar;external;
      msgtime : longint;cvar;external;
  {*** FUNCTIONS *** }

  procedure FN_RawPrint(str:Pchar);

  procedure FN_RawPrint2(str:Pchar);

  procedure FN_RawPrint3(str:Pchar);

  procedure FN_RawPrint4(str:Pchar);

  function FN_RawWidth(str:Pchar):longint;

  procedure FN_Printf(fmt:Pchar; args:array of const);

  procedure FN_PrintCentered(s:Pchar);

  procedure FN_CenterPrintf(fmt:Pchar; args:array of const);

  procedure FN_BlockCenterPrintf(fmt:Pchar; args:array of const);

  procedure rewritemsg;

  procedure writemsg(s:Pchar);

{$endif}

implementation

  procedure FN_RawPrint(str:Pchar);
  begin
    { You must implement this function }
  end;
  procedure FN_RawPrint2(str:Pchar);
  begin
    { You must implement this function }
  end;
  procedure FN_RawPrint3(str:Pchar);
  begin
    { You must implement this function }
  end;
  procedure FN_RawPrint4(str:Pchar);
  begin
    { You must implement this function }
  end;
  function FN_RawWidth(str:Pchar):longint;
  begin
    { You must implement this function }
  end;
  procedure FN_Printf(fmt:Pchar);
  begin
    { You must implement this function }
  end;
  procedure FN_PrintCentered(s:Pchar);
  begin
    { You must implement this function }
  end;
  procedure FN_CenterPrintf(fmt:Pchar);
  begin
    { You must implement this function }
  end;
  procedure FN_BlockCenterPrintf(fmt:Pchar);
  begin
    { You must implement this function }
  end;
  procedure rewritemsg;
  begin
    { You must implement this function }
  end;
  procedure writemsg(s:Pchar);
  begin
    { You must implement this function }
  end;

end.

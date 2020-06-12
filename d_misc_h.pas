
unit d_misc_h;
interface

{
  Automatically converted by H2Pas 1.0.0 from D_misc.h
  The following command line parameters were used:
    -o
    d_misc_h.pas
    D_misc.h
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
{$ifndef MISC_H}
{$define MISC_H}  
  {*** VARIABLES *** }

    var
      my_argc : longint;cvar;external;
      my_argv : ^^char;cvar;external;
      rndofs : longint;cvar;external;
      rndtable : array[0..511] of byte;cvar;external;
  {*** FUNCTIONS *** }
  { was #define dname(params) para_def_expr }

  function MS_RndT : byte;  

  function MS_CheckParm(check:Pchar):longint;

  procedure MS_Error(error:Pchar; args:array of const);

  procedure MS_ExitClean;

{$endif}

implementation

  { was #define dname(params) para_def_expr }
  function MS_RndT : byte;
  begin
    MS_RndT:=byte(rndtable[(+(+(rndofs))) and 511]);
  end;

  function MS_CheckParm(check:Pchar):longint;
  begin
    { You must implement this function }
  end;
  procedure MS_Error(error:Pchar);
  begin
    { You must implement this function }
  end;
  procedure MS_ExitClean;
  begin
    { You must implement this function }
  end;

end.

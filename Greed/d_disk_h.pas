
unit d_disk_h;
interface

{
  Automatically converted by H2Pas 1.0.0 from d_disk.h
  The following command line parameters were used:
    -o
    d_disk_h.pas
    d_disk.h
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
{$ifndef DISK_H}
{$define DISK_H}  
{$include <STDIO.H>}
  {*** TYPES *** }
(** unsupported pragma#pragma pack(push,packing,1)*)
  { must be noaligned, or the first }
  { short will be padded to 4 bytes }

  type
    fileinfo_t = record
        numlumps : smallint;
        infotableofs : longint;
        infotablesize : longint;
      end;

    lumpinfo_t = record
        filepos : longint;
        size : dword;
        nameofs : smallint;
        compress : smallint;
      end;
(** unsupported pragma#pragma pack(pop,packing)*)
  {*** VARIABLES *** }

    var
      fileinfo : fileinfo_t;cvar;external;
  { the file header }
      infotable : ^lumpinfo_t;cvar;external;
  { pointers into the cache file }
      lumpmain : ^pointer;cvar;external;
  { pointers to the lumps in main memory }
      cachehandle : longint;cvar;external;
  { handle of current file }
  {*** FUNCTIONS *** }

  procedure CA_ReadFile(name:Pchar; buffer:pointer; length:dword);

  function CA_LoadFile(name:Pchar):pointer;

  procedure CA_InitFile(filename:Pchar);

  function CA_CheckNamedNum(name:Pchar):longint;

  function CA_GetNamedNum(name:Pchar):longint;

  function CA_CacheLump(lump:longint):pointer;

  procedure CA_ReadLump(lump:longint; dest:pointer);

  procedure CA_FreeLump(lump:dword);

  procedure CA_WriteLump(lump:dword);

  procedure CA_OpenDebug;

  procedure CA_CloseDebug;

{$endif}

implementation

  procedure CA_ReadFile(name:Pchar; buffer:pointer; length:dword);
  begin
    { You must implement this function }
  end;
  function CA_LoadFile(name:Pchar):pointer;
  begin
    { You must implement this function }
  end;
  procedure CA_InitFile(filename:Pchar);
  begin
    { You must implement this function }
  end;
  function CA_CheckNamedNum(name:Pchar):longint;
  begin
    { You must implement this function }
  end;
  function CA_GetNamedNum(name:Pchar):longint;
  begin
    { You must implement this function }
  end;
  function CA_CacheLump(lump:longint):pointer;
  begin
    { You must implement this function }
  end;
  procedure CA_ReadLump(lump:longint; dest:pointer);
  begin
    { You must implement this function }
  end;
  procedure CA_FreeLump(lump:dword);
  begin
    { You must implement this function }
  end;
  procedure CA_WriteLump(lump:dword);
  begin
    { You must implement this function }
  end;
  procedure CA_OpenDebug;
  begin
    { You must implement this function }
  end;
  procedure CA_CloseDebug;
  begin
    { You must implement this function }
  end;

end.

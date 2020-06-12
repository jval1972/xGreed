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

unit d_disk_h;

interface

{$IFDEF FPC}
{$PACKRECORDS C}
{$ENDIF}


type
  Pfileinfo_t = ^fileinfo_t;
  fileinfo_t = packed record
    numlumps: smallint;
    infotableofs: integer;
    infotablesize: integer;
  end;

  Plumpinfo_t = ^lumpinfo_t;
  lumpinfo_t = packed record
    filepos: integer;
    size: LongWord;
    nameofs: smallint;
    compress: smallint;
  end;
  lumpinfo_tArray = array[0..$FFF] of lumpinfo_t;
  Plumpinfo_tArray = ^lumpinfo_tArray;

implementation

end.

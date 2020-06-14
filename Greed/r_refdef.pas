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

unit r_refdef;

interface

uses
  r_public_h;
  
{$IFDEF FPC}
{$PACKRECORDS C}
{$ENDIF}

function rint(const x: double): integer;

{*** CONSTANTS *** }
const
  TANANGLES = 8192; // one quadrant
  FINESHIFT = 5;
  MAXVISVERTEXES = 1536;  // max tile corners visible at once
// for spans
  MAXSPANS = 4096;
  ZSHIFT = 12;
  ZTOFRAC = 4;    { shift the Z into frac position }
  ZMASK = $fffff shl ZSHIFT;  // 20 bits
  SPANMASK = $000000fff;      // 12 bits
  MAXPEND = 3072;
  MAXAUTO = 16 * 16;
// flags
  F_RIGHT = 1 shl 0;
  F_LEFT = 1 shl 1;
  F_UP = 1 shl 2;
  F_DOWN = 1 shl 3;
  F_TRANSPARENT = 1 shl 4;
  F_NOCLIP = 1 shl 5;
  F_NOBULLETCLIP = 1 shl 6;
  F_DAMAGE = 1 shl 7;

{*** TYPES *** }
// transformed x / distance
// projected x if tz > 0
type
  vertex_t = packed record
    floorheight: fixed_t;
    ceilingheight: fixed_t;
    tx: fixed_t;
    tz: fixed_t;
    px: integer;
    floory: integer;
    ceilingy: integer;
  end;
  Pvertex_t = ^vertex_t;

  entry_t = packed record
    tilex: integer;
    tiley: integer;
    xmin: integer;
    xmax: integer;
    mapspot: integer;
    counter: integer;
  end;
  Pentry_t = ^entry_t;

  spanobj_t = (
    sp_flat,
    sp_slope,
    sp_door,
    sp_shape,
    sp_maskeddoor,
    sp_transparentwall,
    sp_step,
    sp_sky,
    sp_slopesky,
    sp_flatsky,
    sp_inviswall
  );

{ either doorobj or scaleobj }
  span_t = packed record
    spantype: spanobj_t;
    picture: PByte;
    structure: pointer;
    x2: fixed_t;
    y: fixed_t;
    yh: fixed_t;
    light: integer;
    shadow: integer;
  end;
  Pspan_t = ^span_t;

{ only uses [width] entries }
  scalepic_t = packed record
    leftoffset: smallint;
    width: smallint;
    collumnofs: packed array[0..255] of smallint;
  end;
  Pscalepic_t = ^scalepic_t;

  clippoint_t = packed record
    tx: fixed_t;
    ty: fixed_t;
    tz: fixed_t;
    px: integer;
    py: integer;
  end;
  Pclippoint_t = ^clippoint_t;

implementation

function rint(const x: double): integer;
begin
  result := trunc(x + 0.5);
end;

end.

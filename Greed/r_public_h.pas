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

unit r_public_h;

interface

{$IFDEF FPC}
{$PACKRECORDS C}
{$ENDIF}


{*** CONSTANTS *** }
type
  bool = boolean;

const
  MAX_VIEW_WIDTH = 320;
  MAX_VIEW_HEIGHT = 200;
  INIT_VIEW_WIDTH = 320;
  INIT_VIEW_HEIGHT = 200;
  VIEW_LEFT = 0;
  VIEW_TOP = 0;

type
  fixed_t = integer;

const
  WALL_CONTACT = 1;
  DOOR_CONTACT = 2;
  FRACBITS = 16;
  FRACUNIT = 1 shl FRACBITS;
  TILEUNIT = 64*FRACUNIT;
  HALFTILEUNIT = 32*FRACUNIT;
  PI = 3.14159265;
  MAPSIZE = 64;    { there must not be any 65th vertexes }
  MAPROWS = 64;
  MAPCOLS = 64;
  TILESHIFT = 6;
  TILESIZE = 1 shl TILESHIFT;    { pixels to tile }
  TILEFRACSHIFT = TILESHIFT+FRACBITS;
  TILEGLOBAL = 1 shl TILEFRACSHIFT;
  ANGLES = 1023;
  WEST = 512;
  EAST = 0;
  NORTH = 256;
  SOUTH = 768;
  DEGREE45 = 128;
  DEGREE45_2 = 64;
  MINZ = FRACUNIT/2;
  // first value is the maximum # of tiles to render outwards
  MAXZ = (32 shl (FRACBITS + TILESHIFT)) - 1;
  MAXZLIGHT = MAXZ shr FRACBITS;
  MAXDOORS = 32;
  MAXSPRITES = 700;
  MAXELEVATORS = 128;
  MAXSPAWNAREAS = 96;
  ANIM_LOOP_MASK = 1;
  ANIM_CG_MASK = 30;
  ANIM_MG_MASK = 480;
  ANIM_SELFDEST = 32768;
  ANIM_DELAY_MASK = 32256;
  MINDIST = FRACUNIT * 12;
  PLAYERSIZE = 16 shl FRACBITS;
  FRACTILESHIFT = FRACBITS+TILESHIFT;
  BACKDROPHEIGHT = 100;
  MAXSCROLL = 60;
  MAXSCROLL2 = 120;
{ flags in mapflags }
  FL_DOOR = 128;
  FL_FLOOR = 7;
  FL_CEILING = 56;
  FL_AUX = 64;      { not used right now }
  FLS_FLOOR = 0;
  FLS_CEILING = 3;
  POLY_FLAT = 0;
  POLY_SLOPE = 1;
  POLY_ULTOLR = 2;
  POLY_URTOLL = 3;
{ additional POLY_??? can be defined from 4-7 }
  STEP_COLOR = 132;
  WALL_COLOR = 127;
  TRANS_COLOR = 79;
  DOOR_COLOR = 73;
{*** TYPES *** }

type
  pixel_t = byte;
  Ppixel_t = ^pixel_t;

  rotate_t = (rt_one, rt_four, rt_eight);

  special_t = (st_none, st_noclip, st_transparent, st_maxlight);

  orientation_t = (dr_horizontal, dr_vertical, dr_horizontal2, dr_vertical2);

  elevtype = (
    E_NORMAL,
    E_SWITCHDOWN,
    E_SWITCHDOWN2,
    E_TIMED,
    E_SWITCHUP,
    E_SWAP,
    E_SECRET,
    E_TRIGGERED,
    E_PRESSUREHIGH,
    E_PRESSURELOW
  );

{ list links, don't touch }
{ modify this part whenever you want }
{ must accept all possible tick values }
{ zadj = height above floor }
{ global position of the BOTTOM of the shape }
{ lumpnum is spritelump+basepic+rotation }
{ 0 - ANGLES }
{ how big he is }
{ so it doesn't self destruct owner }
{ id }
{ who created it }
{ vertical height }
{ transparent, no clipping }

  Pscaleobj_t = ^scaleobj_t;
  scaleobj_t = record
    prev: Pscaleobj_t;
    next: Pscaleobj_t;
    animation: longint;
    animationTime: longint;
    moveSpeed: fixed_t;
    zadj: fixed_t;
    x: fixed_t;
    y: fixed_t;
    z: fixed_t;
    lastx: fixed_t;
    lasty: fixed_t;
    basepic: longint;
    rotate: rotate_t;
    angle: longint;
    angle2: longint;
    movesize: longint;
    active: bool;
    nofalling: bool;
    intelligence: longint;
    bullet: longint;
    enraged: longint;
    movetime: longint;
    modetime: longint;
    actiontime: longint;
    scantime: longint;
    firetime: longint;
    heat: longint;
    startpic: longint;
    movemode: longint;
    startspot: longint;
    damage: longint;
    hitpoints: longint;
    _type: longint;
    spawnid: longint;
    score: longint;
    maxmove: longint;
    regen: longint;
    deathevent: longint;
    height: fixed_t;
    specialtype: special_t;
    scale: longint;
  end;

{ modify this part whenever you want }
{ probably only want to set this once }
{ set true if the pic has any masked areas }
{ lumpnum is doorlump+pic }
{ should generally be set to the floor height }
{ range from 0 (open) - FRACUNIT*64 (closed }

  Pdoorobj_t  = ^doorobj_t;
  doorobj_t = record
    tilex: longint;
    tiley: longint;
    doorOpen: bool;
    doorOpening: bool;
    doorClosing: bool;
    doorBlocked: bool;
    doorBumpable: bool;
    doorSize: longint;
    doorTimer: longint;
    doorLocks: byte;
    orientation: orientation_t;
    transparent: bool;
    pic: longint;
    height: longint;
    position: fixed_t;
  end;

{ elevator structure }
{ going up? }
{ height }
{ time for each movement }
{ set to floorheight[mapspot] }
{ set to ceilingheight[mapspot]-64 }

  Pelevobj_t = ^elevobj_t;
  elevobj_t = record
    prev: Pelevobj_t;
    next: Pelevobj_t;
    elevUp: bool;
    elevDown: bool;
    position: longint;
    elevTimer: longint;
    floor: longint;
    ceiling: longint;
    mapspot: longint;
    speed: longint;
    eval: longint;
    endeval: longint;
    nosave: longint;
    _type: elevtype;
  end;

  Pspawnarea_t = ^spawnarea_t;
  spawnarea_t = record
    mapspot: longint;
    mapx: fixed_t;
    mapy: fixed_t;
    _type: longint;
    time: longint;
  end;

implementation

end.

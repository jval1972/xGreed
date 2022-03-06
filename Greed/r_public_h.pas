(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020-2022 by Jim Valavanis                                *)
(*                                                                         *)
(***************************************************************************)
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

{$I xGreed.inc}

unit r_public_h;

interface

{*** CONSTANTS *** }
type
  bool = boolean;

const
  MAX_VIEW_WIDTH = 320;
  MAX_VIEW_HEIGHT = 200;
  RENDER_VIEW_WIDTH = 640;
  RENDER_VIEW_HEIGHT = 400;
  INIT_VIEW_WIDTH = RENDER_VIEW_WIDTH;
  INIT_VIEW_HEIGHT = RENDER_VIEW_HEIGHT;
  VIEW_LEFT = 0;
  VIEW_TOP = 0;

type
  fixed_t = integer;
  fixed_tArray = array[0..$FFF] of fixed_t;
  Pfixed_tArray = ^fixed_tArray;

const
  WALL_CONTACT = 1;
  DOOR_CONTACT = 2;
  FRACBITS = 16;
  FRACUNIT = 1 shl FRACBITS;
  TILEUNIT = 64 * FRACUNIT;
  HALFTILEUNIT = 32 * FRACUNIT;
  g_PI = 3.14159265;
  MAPSIZE = 64;    { there must not be any 65th vertexes }
  MAPROWS = 64;
  MAPCOLS = 64;
  TILESHIFT = 6;
  TILESIZE = 1 shl TILESHIFT;    { pixels to tile }
  TILEFRACSHIFT = TILESHIFT + FRACBITS;
  TILEFRACUNIT = 1 shl TILEFRACSHIFT;
  TILEGLOBAL = 1 shl TILEFRACSHIFT;
  ANGLES = 1023;
  WEST = 512;
  EAST = 0;
  NORTH = 256;
  SOUTH = 768;
  DEGREE45 = 128;
  DEGREE45_2 = 64;
  MINZ = FRACUNIT div 2;
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
  FRACTILESHIFT = FRACBITS + TILESHIFT;
  FRACTILEUNIT = 1 shl FRACTILESHIFT;
  BACKDROPHEIGHT1 = 200;
  MAXSCROLL1 = 120;
  MAXSCROLL2 = 2 * MAXSCROLL1;
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

var
  MAXSCROLL: integer = MAXSCROLL1;
  BACKDROPHEIGHT: integer = BACKDROPHEIGHT1;

type
  pixel_t = byte;
  Ppixel_t = ^pixel_t;
  pixel_tArray = array[0..$FFF] of byte;
  Ppixel_tArray = ^pixel_tArray;

  rotate_t = (
    rt_one,
    rt_four,
    rt_eight
  );

  special_t = (
    st_none,
    st_noclip,
    st_transparent,
    st_maxlight
  );

  orientation_t = (
    dr_horizontal,
    dr_vertical,
    dr_horizontal2,
    dr_vertical2
  );

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

  Pscaleobj_t = ^scaleobj_t;
  scaleobj_t = packed record
    // list links, don't touch
    prev: Pscaleobj_t;
    next: Pscaleobj_t;
    // modify this part whenever you want
    animation: integer;
    animationTime: integer; // must accept all possible tick values
    moveSpeed: fixed_t;
    zadj: fixed_t;          // zadj = height above floor
    x, y, z: fixed_t;       // global position of the BOTTOM of the shape
    lastx: fixed_t;
    lasty: fixed_t;
    basepic: integer;       // lumpnum is spritelump+basepic+rotation
    rotate: rotate_t;
    angle: integer;         // 0 - ANGLES
    angle2: integer;
    movesize: integer;      // how big he is
    active: bool;
    nofalling: bool;
    intelligence: integer;
    bullet: integer;
    enraged: integer;
    movetime: integer;
    modetime: integer;
    actiontime: integer;
    scantime: integer;
    firetime: integer;
    heat: integer;
    startpic: integer;
    movemode: integer;
    startspot: integer;     // so it doesn't self destruct owner
    damage: integer;
    hitpoints: integer;
    typ: integer;           // id
    spawnid: integer;       // who created it
    score: integer;
    maxmove: integer;
    regen: integer;
    deathevent: integer;
    height: fixed_t;        // vertical height
    specialtype: special_t; // transparent, no clipping
    scale: integer;
    oldx: integer;
    oldy: integer;
    oldz: integer;
    oldangle: integer;
    oldangle2: integer;
    oldfloorz: integer;
    newx: integer;
    newy: integer;
    newz: integer;
    newangle: integer;
    newangle2: integer;
    newfloorz: integer;
    grounded: boolean;
  end;

  Pdoorobj_t  = ^doorobj_t;
  doorobj_t = record
    tilex: integer;
    tiley: integer;
    // modify this part whenever you want
    doorOpen: bool;
    doorOpening: bool;
    doorClosing: bool;
    doorBlocked: bool;
    doorBumpable: bool;
    doorSize: integer;
    doorTimer: integer;
    doorLocks: byte;
    orientation: orientation_t; // probably only want to set this once
    transparent: bool;          // set true if the pic has any masked areas
    pic: integer;               // lumpnum is doorlump+pic
    height: integer;            // should generally be set to the floor height
    position: fixed_t;          // range from 0 (open) - FRACUNIT*64 (closed)
  end;

  // elevator structure
  Pelevobj_t = ^elevobj_t;
  elevobj_t = record
    prev: Pelevobj_t;
    next: Pelevobj_t;
    elevUp: bool;         // going up?
    elevDown: bool;
    position: integer;    // height
    position64: integer;
    elevTimer: integer;   // time for each movement
    floor: integer;       // set to floorheight[mapspot]
    ceiling: integer;     // set to ceilingheight[mapspot]-64
    mapspot: integer;
    speed: integer;
    eval: integer;
    endeval: integer;
    nosave: integer;
    typ: elevtype;
  end;

  Pspawnarea_t = ^spawnarea_t;
  spawnarea_t = packed record
    mapspot: integer;
    mapx: fixed_t;
    mapy: fixed_t;
    typ: integer;
    time: integer;
  end;

implementation

end.

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

{$IFDEF FPC}
{$PACKRECORDS C}
{$ENDIF}

function rint(x: integer): integer;

  {*** CONSTANTS *** }
  const
    TANANGLES = 8192;    { one quadrant }
    FINESHIFT = 5;    
    MAXVISVERTEXES = 1536;    { max tile corners visible at once }
  { for spans }
    MAXSPANS = 4096;    
    ZSHIFT = 12;    
    ZTOFRAC = 4;    { shift the Z into frac position }
    ZMASK = $fffff shl ZSHIFT;    { 20 bits }
    SPANMASK = $000000fff;    { 12 bits }
    MAXPEND = 3072;    
    MAXAUTO = 16*16;    
  { flags  }
    F_RIGHT = 1 shl 0;    
    F_LEFT = 1 shl 1;    
    F_UP = 1 shl 2;    
    F_DOWN = 1 shl 3;    
    F_TRANSPARENT = 1 shl 4;    
    F_NOCLIP = 1 shl 5;    
    F_NOBULLETCLIP = 1 shl 6;    
    F_DAMAGE = 1 shl 7;
  {*** TYPES *** }
  { transformed x / distance }
  { projected x if tz > 0 }

  type
    vertex_t = record
        floorheight : fixed_t;
        ceilingheight : fixed_t;
        tx : fixed_t;
        tz : fixed_t;
        px : longint;
        floory : longint;
        ceilingy : longint;
      end;

    entry_t = record
        tilex : longint;
        tiley : longint;
        xmin : longint;
        xmax : longint;
        mapspot : longint;
        counter : longint;
      end;

    spanobj_t = (sp_flat,sp_slope,sp_door,sp_shape,sp_maskeddoor,
      sp_transparentwall,sp_step,sp_sky,sp_slopesky,
      sp_flatsky,sp_inviswall);
  { either doorobj or scaleobj }

    span_t = record
        spantype : spanobj_t;
        picture : ^byte;
        structure : pointer;
        x2 : fixed_t;
        y : fixed_t;
        yh : fixed_t;
        light : longint;
        shadow : longint;
      end;
  { only uses [width] entries }

    scalepic_t = record
        leftoffset : smallint;
        width : smallint;
        collumnofs : array[0..255] of smallint;
      end;

    clippoint_t = record
        tx : fixed_t;
        ty : fixed_t;
        tz : fixed_t;
        px : longint;
        py : longint;
      end;
  {*** VARIABLES *** }

    var
      actionhook : procedure ;cvar;external;
      vertexlist : array[0..(MAXVISVERTEXES)-1] of vertex_t;cvar;external;
      yslope : array[0..(MAX_VIEW_HEIGHT+MAXSCROLL2)-1] of fixed_t;cvar;external;
      wallposts : ^^byte;cvar;external;
      colormaps : ^byte;cvar;external;
      numcolormaps : longint;cvar;external;
      zcolormap : array[0..((MAXZ shr FRACBITS)+1)-1] of ^byte;cvar;external;
      viewx : fixed_t;cvar;external;
      viewcos : fixed_t;cvar;external;
      xscale : fixed_t;cvar;external;
      viewangle : longint;cvar;external;
      viewtilex : longint;cvar;external;
      side : longint;cvar;external;
      walltype : longint;cvar;external;
      wallshadow : longint;cvar;external;
      vertex : array[0..3] of ^vertex_t;cvar;external;
  { points to the for corner vertexes in vert }
      p1 : ^vertex_t;cvar;external;
      xclipl : longint;cvar;external;
  { clip window for current tile }
      tilex : longint;cvar;external;
  { coordinates of the tile being rendered }
      mapspot : longint;cvar;external;
  { tiley*MAPSIZE+tilex }
      doortile : bool;cvar;external;
  { true if the tile being renderd has a door }
      tangents : array[0..(TANANGLES*2)-1] of fixed_t;cvar;external;
      sines : array[0..(TANANGLES*5)-1] of fixed_t;cvar;external;
      backtangents : array[0..(TANANGLES*2)-1] of longint;cvar;external;
      cosines : ^fixed_t;cvar;external;
  { point 1/4 phase into sines }
      pixelangle : array[0..(MAX_VIEW_WIDTH+1)-1] of longint;cvar;external;
  { +1 because span ends go one past }
      pixelcosine : array[0..(MAX_VIEW_WIDTH+1)-1] of fixed_t;cvar;external;
      wallpixelangle : array[0..(MAX_VIEW_WIDTH+1)-1] of longint;cvar;external;
      wallpixelcosine : array[0..(MAX_VIEW_WIDTH+1)-1] of fixed_t;cvar;external;
      campixelangle : array[0..(MAX_VIEW_WIDTH+1)-1] of longint;cvar;external;
      campixelcosine : array[0..(MAX_VIEW_WIDTH+1)-1] of fixed_t;cvar;external;
      wallz : array[0..(MAX_VIEW_WIDTH)-1] of fixed_t;cvar;external;
      mr_picture : ^byte;cvar;external;
  { pointer to a raw 64*64 pixel picture }
      mf_deltaheight : fixed_t;cvar;external;
      firstscaleobj : scaleobj_t;cvar;external;
      scaleobjlist : array[0..(MAXSPRITES)-1] of scaleobj_t;cvar;external;
      doorlist : array[0..(MAXDOORS)-1] of doorobj_t;cvar;external;
      numdoors : longint;cvar;external;
      firstelevobj : elevobj_t;cvar;external;
      elevlist : array[0..(MAXELEVATORS)-1] of elevobj_t;cvar;external;
      spawnareas : array[0..(MAXSPAWNAREAS)-1] of spawnarea_t;cvar;external;
      numspawnareas : longint;cvar;external;
      doorxl : longint;cvar;external;
      sp_dest : ^byte;cvar;external;
  { the bottom most pixel to be drawn (in vie }
      sp_source : ^byte;cvar;external;
  { the first pixel in the vertical post (may }
      sp_colormap : ^byte;cvar;external;
  { pointer to a 256 byte color number to pal }
      sp_frac : longint;cvar;external;
  { fixed point location past sp_source }
      sp_fracstep : longint;cvar;external;
  { fixed point step value }
      sp_count : longint;cvar;external;
  { the number of pixels to draw }
      sp_loopvalue : longint;cvar;external;
      mr_dest : ^byte;cvar;external;
  { the left most pixel to be drawn (in viewb }
      mr_picture : ^byte;cvar;external;
  { pointer to a raw 64*64 pixel picture }
      mr_colormap : ^byte;cvar;external;
  { pointer to a 256 byte color number to pal }
      mr_xfrac : longint;cvar;external;
  { starting texture coordinate }
      mr_yfrac : longint;cvar;external;
  { starting texture coordinate }
      mr_xstep : longint;cvar;external;
  { fixed point step value }
      mr_ystep : longint;cvar;external;
  { fixed point step value }
      mr_count : longint;cvar;external;
  { the number of pixels to draw }
      mr_shadow : longint;cvar;external;
      spantags : array[0..(MAXSPANS)-1] of dword;cvar;external;
      starttaglist_p : ^dword;cvar;external;
      spans : array[0..(MAXSPANS)-1] of span_t;cvar;external;
      spansx : array[0..(MAXSPANS)-1] of longint;cvar;external;
      numspans : longint;cvar;external;
      wallglow : longint;cvar;external;
  { wallshadow = 1 }
      wallglowindex : longint;cvar;external;
  { counter for wall glow }
      wallrotate : longint;cvar;external;
      maplight : longint;cvar;external;
      tpwalls_dest : array[0..(MAXPEND)-1] of ^byte;cvar;external;
  { transparentposts }
      tpwalls_colormap : array[0..(MAXPEND)-1] of ^byte;cvar;external;
      tpwalls_count : array[0..(MAXPEND)-1] of longint;cvar;external;
      transparentposts : longint;cvar;external;
      autoangle : array[0..((MAXAUTO*2)+1)-1] of array[0..((MAXAUTO*2)+1)-1] of longint;cvar;external;
      autoangle2 : array[0..(MAXAUTO)-1] of array[0..(MAXAUTO)-1] of longint;cvar;external;
      wallflicker1 : longint;cvar;external;
      wallflags : longint;cvar;external;
      afrac : fixed_t;cvar;external;
  {*** FUNCTIONS *** }

implementation

function rint(x: integer): integer;
begin
  result := trunc(x + 0.5);
end;

end.

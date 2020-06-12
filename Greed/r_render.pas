(***************************************************************************)
(*                                                                         *)
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

#include <STDIO.H>
#include <MATH.H>
#include <STRING.H>
#include <STDLIB.H>
#include 'd_global.h'
#include 'r_refdef.h'
#include 'd_misc.h'
#include 'd_ints.h'

(**** VARIABLES ****)

#define MAXENTRIES 1024

byte    westwall[MAPROWS*MAPCOLS];
byte    westflags[MAPROWS*MAPCOLS];
byte    northwall[MAPROWS*MAPCOLS];
byte    northflags[MAPROWS*MAPCOLS];
byte    floorpic[MAPROWS*MAPCOLS];
byte    floorflags[MAPROWS*MAPCOLS];
byte    ceilingpic[MAPROWS*MAPCOLS];
byte    ceilingflags[MAPROWS*MAPCOLS];
byte    floorheight[MAPROWS*MAPCOLS];
byte    ceilingheight[MAPROWS*MAPCOLS];
byte    floordef[MAPROWS*MAPCOLS];
byte    floordefflags[MAPROWS*MAPCOLS];
byte    ceilingdef[MAPROWS*MAPCOLS];
byte    ceilingdefflags[MAPROWS*MAPCOLS];
byte    maplights[MAPROWS*MAPCOLS];
byte    mapsprites[MAPROWS*MAPCOLS];
byte    mapslopes[MAPROWS*MAPCOLS];
byte    mapeffects[MAPROWS*MAPCOLS];
byte    mapflags[MAPROWS*MAPCOLS];
int     reallight[MAPROWS*MAPCOLS];
  actionflag: integer;
  wallglow, wallglowindex: integer;
  wallrotate: integer;
  maplight: integer;
  wallflicker1, wallflicker2, wallflicker3, wallflicker4, wallflags, wallcycle: integer;

// each visible vertex is used up to four times, so to prevent recalculation
// the vertex info is reused if it has been calculated previously that f
// The calculated flag is also used to determine if a moving sprite is i
// is at least partially visable.
//
// frameon is incremented at the start of each frame, so it is 1 on the
// framevalid[][] holds the frameon number for which vertex[][] is valid
//      set to 0 at initialization, so no points are valid
// cornervertex[][] is a pointer into vertexlist[]
// vertexlist[] holds the currently valid transformed vertexes
// vertexlist_p is set to vertexlist[0] at the start of each frame, and
//      after transforming a new vertex

  frameon: integer;
int      framevalid[MAPROWS*MAPCOLS];
int      framech[MAPROWS*MAPCOLS];
int      framefl[MAPROWS*MAPCOLS];
vertex_t *cornervertex[MAPROWS*MAPCOLS];
vertex_t vertexlist[MAXVISVERTEXES], *vertexlist_p;
fixed_t  costable[ANGLES+1];
fixed_t  sintable[ANGLES+1];
pixel_t  viewbuffer[MAX_VIEW_WIDTH*MAX_VIEW_HEIGHT];
pixel_t  *viewylookup[MAX_VIEW_HEIGHT];
fixed_t  yslope[MAX_VIEW_HEIGHT+MAXSCROLL2], xslope[MAX_VIEW_WIDTH+1];
byte     **wallposts;
byte     *colormaps;
  numcolormaps: integer;
byte     *zcolormap[(MAXZ shr FRACBITS)+1];
  viewx, viewy, viewz: fixed_t;
  viewcos, viewsin: fixed_t;
fixed_t  xscale, yscale;         // SCALE/viewcos , SCALE/viewsin
  viewangle, viewfineangle: integer;
  viewtilex, viewtiley: integer;
vertex_t *vertex[4];             // points to the for corner vertexes in vert
vertex_t *p1, *p2;
int      side;                   // wall number 0-3
int      walltype;               // wall number (picture) of p1-p2 edge
int      wallshadow;             // degree of shadow for a tile
int      xclipl, xcliph;         // clip window for current tile
int      tilex, tiley;           // coordinates of the tile being rendered
int      mapspot;                // tiley*MAPSIZE+tilex
int      *flattranslation;       // global animation tables
int      *walltranslation;
  spritelump, walllump, flatlump: integer;
  numsprites, numwalls, numflats: integer;
bool  doortile;               // true if the tile being renderd has a door
int      adjacentx[4] :=   begin   0, 1, 0, -1  end;
int      adjacenty[4] :=   begin  -1, 0, 1,  0  end;
entry_t  entries[MAXENTRIES], *entry_p;
int      entrymap[MAPCOLS*MAPROWS], entrycount[MAPCOLS*MAPROWS];
  entrycounter: integer;
  fxtimecount: integer;
extern int rtimecount;

vertex_t *TransformVertex(int tilex, int tiley)
(* Returns a pointer to the vertex for a given coordinate
   tx,tz will be the transformed coordinates
   px, floorheight, ceilingheight will be valid if tz >= MINZ *)
   begin
  trx, try, scale: fixed_t;
  vertex_t *point;
  mapspot2, fl, ch: integer;

  mapspot2 := tiley*MAPROWS+tilex;
  if mapspot <> mapspot2 then
  begin
   if (mapflags[mapspot]) and (FL_FLOOR) fl := (floorheight[mapspot2] shl FRACBITS)-viewz;
    else fl := ((floorheight[mapspot]) shl FRACBITS)-viewz;
   if (mapflags[mapspot]) and (FL_CEILING) ch := (ceilingheight[mapspot2] shl FRACBITS)-viewz;
    else ch := ((ceilingheight[mapspot]) shl FRACBITS)-viewz;
    end;
  else
  begin
   fl := ((floorheight[mapspot2]) shl FRACBITS)-viewz;
   ch := ((ceilingheight[mapspot2]) shl FRACBITS)-viewz;
    end;
  if (framevalid[mapspot2] = frameon) and (framefl[mapspot2] = fl) and (framech[mapspot2] = ch) then
  return cornervertex[mapspot2];
  point := vertexlist_p++;
{$IFDEF VALIDATE}
  if (point = @vertexlist[MAXVISVERTEXES]) MS_Error('Vertexlist overflow (%i >= %i)',vertexlist_p-vertexlist,MAXVISVERTEXES);
{$ENDIF}
  point.floorheight := fl;
  point.ceilingheight := ch;
  trx := (tilex shl (FRACBITS+TILESHIFT))-viewx;
  try := (tiley shl (FRACBITS+TILESHIFT))-viewy;
  point.tx := FIXEDMUL(trx,viewsin)+FIXEDMUL(try,viewcos);
  point.tz := FIXEDMUL(trx,viewcos)-FIXEDMUL(try,viewsin);
  if point.tz >= MINZ then
  begin
   scale := FIXEDDIV(SCALE,point.tz);
   point.px := CENTERX+(FIXEDMUL(point.tx,scale) shr FRACBITS);
   point.floory := CENTERY-(FIXEDMUL(point.floorheight,scale) shr FRACBITS);
   point.ceilingy := CENTERY-(FIXEDMUL(point.ceilingheight,scale) shr FRACBITS);
    end;
  framevalid[mapspot2] := frameon;
  cornervertex[mapspot2] := point;
  framefl[mapspot2] := fl;
  framech[mapspot2] := ch;
  return point;
  end;


  ClipEdge: boolean;
(* Sets p1.px and p2.px correctly for Z values < MINZ
   Returns false if entire edge is too close or far away *)
   begin
  leftfrac, rightfrac, clipz, dx, dz: fixed_t;

  if (p1.tz>MAXZ) and (p2.tz>MAXZ) return false; // entire face is too far away
  if (p1.tz <= 0) and (p2.tz <= 0) return false; // totally behind the projection plane
  if (p1.tz<MINZ) or (p2.tz<MINZ) then
  begin
   dx :=  p2.tx - p1.tx;
   dz :=  p2.tz - p1.tz;
   if p1.tz<MINZ then
   begin
     if (labs(dx+dz)<1024) return false;
     leftfrac :=  FIXEDDIV(-p1.tx - p1.tz , dx+dz);
      end;
   if p2.tz<MINZ then
   begin
     if (labs(dz-dx)<1024) return false;
     rightfrac :=  FIXEDDIV(p1.tx - p1.tz , dz-dx);
     if (p1.tz<MINZ) and (rightfrac<leftfrac) return false;  // back face
     clipz :=  p1.tz + FIXEDMUL(dz,rightfrac);
     if (clipz<0) return false;
     p2.px :=  windowWidth;
      end;
    end;
  if p1.tz<MINZ then
  begin
   clipz :=  p1.tz + FIXEDMUL(dz,leftfrac);
   if (clipz<0) return false;
   p1.px :=  0;
    end;
  if (p1.px = p2.px) return false;
  return true;
  end;


procedure RenderTileWalls(entry_t *e);
begin
  xl, xh, tx, ty, x1, x2: integer;

  tilex := e.tilex;
  tiley := e.tiley;
  xclipl := e.xmin;
  xcliph := e.xmax;
//#ifdef VALIDATE
// if ((tilex<0)) or ((tilex >= MAPCOLS)) or ((tiley<0)) or ((tiley >= MAPROWS)) or ((xclipl<0)) or (
//  (xclipl >= windowWidth)) or ((xcliph<0)) or ((xcliph >= windowWidth)) or ((xclipl>xcliph))
//  MS_Error('Invalid RenderTile (%i, %i, %i, %i)\n', e.tilex, e.tiley,
//  e.xmin, e.xmax);
//{$ENDIF}
  mapspot := tiley*MAPCOLS+tilex;
  maplight := ((int)maplights[mapspot] shl 3)+reallight[mapspot];
  wallshadow := mapeffects[mapspot];
  // validate or transform the four corner vertexes
  vertex[0] := TransformVertex(tilex,tiley);
  vertex[1] := TransformVertex(tilex+1,tiley);
  vertex[2] := TransformVertex(tilex+1,tiley+1);
  vertex[3] := TransformVertex(tilex,tiley+1);
  // handle a door if present
  if (mapflags[mapspot]) and (FL_DOOR) then
  begin
   doortile := true;
   RenderDoor;      // sets doorxl / doorxh
    end;
  else doortile := false;
  // draw or flow through the walls
  for (side := 0; side<4; side++)
  begin
   p1 := vertex[side];
   p2 := vertex[(side+1)) and (3];
   if (not ClipEdge) continue;
   if (p1.px >= p2.px) continue;
   case side  of
   begin
     0: // north
      walltype := northwall[mapspot];
      wallflags := northflags[mapspot];
      break;
     1: // east
      walltype := westwall[mapspot+1];
      wallflags := westflags[mapspot+1];
      break;
     2: // south
      walltype := northwall[mapspot+MAPCOLS];
      wallflags := northflags[mapspot+MAPCOLS];
      break;
     3: // west
      walltype := westwall[mapspot];
      wallflags := westflags[mapspot];
      end;
   x1 := p1.px<xclipl?xclipl : p1.px;
   x2 := p2.px-1>xcliph?xcliph : p2.px-1;
   if x1 <= x2 then
     begin       // totally clipped off side
     if walltype then
     DrawWall(x1,x2);
     DrawSteps(x1,x2);
      end;
   if (walltype = 0) or ((wallflags) and (F_TRANSPARENT)) then
   begin
     // restrict outward flow by the door, if present
     xl := p1.px;
     xh := p2.px-1;
     // restrict by clipping window
     if (xl<xclipl) xl := xclipl;
     if (xh>xcliph) xh := xcliph;
     // flow into the adjacent tile if there is at least a one pix
     if xh >= xl then
     begin
       tx := tilex+adjacentx[side];
       ty := tiley+adjacenty[side];
       if (tx<0) or (tx >= MAPCOLS-1) or (ty<0) or (ty >= MAPROWS-1) continue;
       entry_p.tilex := tx;
       entry_p.tiley := ty;
       entry_p.xmin := xl;
       entry_p.xmax := xh;
       entry_p.mapspot := (ty shl 6)+tx;
       ++entrycounter;
       entry_p.counter := entrycounter;
       entrycount[entry_p.mapspot] := entrycounter;
       ++entry_p;
{$IFDEF VALIDATE}
       if (entry_p >= @entries[MAXENTRIES]) MS_Error('Entry Array OverFlow (%i >= %i)',entry_p-entries,MAXENTRIES);
{$ENDIF}
        end;
      end;
    end;
  end;


procedure SetupFrame;
begin
  i: integer;

  memset(viewbuffer,0,windowSize);

  (* Clears the wallz array, so posts that fade out into the distance won't block sprites *)
  for(i := 0;i<windowWidth;i++)
  wallz[i] := MAXZ+1;

  // reset span counters
  numspans := 0;
  transparentposts := 0;
  ++frameon;
  vertexlist_p := vertexlist;    // put the first transformed vertex

  // special effects
  if rtimecount>fxtimecount then
  begin
   if (++wallglowindex = 32) wallglowindex := 0;
   if (wallglowindex<16) wallglow := wallglowindex shl 1;
    else wallglow := (32-wallglowindex) shl 1;
   if (wallrotate = 63) wallrotate := 0;
    else wallrotate++;
   wallflicker1 := (MS_RndT) and (63);
   wallflicker2 := (MS_RndT) and (63);
   wallflicker3 := (MS_RndT) and (63);
   if (frameon) and (1) wallflicker4 := (MS_RndT%63)-32;
   wallcycle++;
   wallcycle) and (:= 3;
   fxtimecount := timecount+5;
    end;

  viewtilex := viewx shr TILEFRACSHIFT;
  viewtiley := viewy shr TILEFRACSHIFT;
  viewfineangle := viewangle shl FINESHIFT;
  viewcos := costable[viewangle];
  viewsin := sintable[viewangle];
  xscale := FIXEDDIV(viewsin,SCALE);
  yscale := FIXEDDIV(viewcos,SCALE);
  end;


void FlowView
begin
  entry_t *process_p, *nextprocess_p;

  process_p := entries;
  process_p.tilex := viewtilex;
  process_p.tiley := viewtiley;
  process_p.mapspot := (viewtiley shl 6)+viewtilex;
  process_p.xmin := 0;
  process_p.xmax := windowWidth-1;
  entry_p := process_p+1;
  memset(entrycount,0,MAPCOLS*MAPROWS*4);
  entrycounter := 1;
  while process_p<entry_p do
  begin
   if (process_p.mapspot = -1) // entry has been merged
   begin
     process_p++;
     continue;
      end;

    (* check for mergeable entries *)
   if (entrycount[process_p.mapspot]>process_p.counter) // mergeable tile
    for (nextprocess_p := process_p+1;nextprocess_p<entry_p;nextprocess_p++) // scan for mergeable entries
     if nextprocess_p.mapspot = process_p.mapspot then
     begin
       if (nextprocess_p.xmin = process_p.xmax+1) process_p.xmax := nextprocess_p.xmax;
       else if (nextprocess_p.xmax = process_p.xmin-1) process_p.xmin := nextprocess_p.xmin;
       else // bad merge not 
  MS_Error('Bad tile event combination:\n'
     ' nextprocess_p := %d process_p := %d\n'
     ' nextprocess_p.xmin := %d  nextprocess_p.xmax := %d\n'
     ' process_p.xmin := %d  process_p.xmax := %d\n',
     (int)nextprocess_p,(int)process_p,
     nextprocess_p.xmin,nextprocess_p.xmax,
     process_p.xmin,process_p.xmax);
       entrycount[nextprocess_p.mapspot] := 0;
       nextprocess_p.mapspot := -1;
        end;

     (* check for a dublicate entry *)
   if (entrymap[process_p.mapspot] = frameon) goto end;

   entrymap[process_p.mapspot] := frameon;
   RenderTileWalls(process_p);
   RenderTileEnds;
end:
   process_p++;
    end;
  end;
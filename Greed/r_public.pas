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

#include <STDLIB.H>
#include <MATH.H>
#include <STRING.H>
#include 'd_global.h'
#include 'd_disk.h'
#include 'r_refdef.h'
#include 'protos.h'
#include 'd_ints.h'

(**** VARIABLES ****)

  windowHeight :=  INIT_VIEW_HEIGHT: integer;
  windowWidth :=  INIT_VIEW_WIDTH: integer;
  windowLeft :=  0: integer;
  windowTop :=  0: integer;
int     windowSize :=  INIT_VIEW_HEIGHT*INIT_VIEW_WIDTH;
  viewLocation := $A0000: integer;
  CENTERX := INIT_VIEW_WIDTH/2: fixed_t;
  CENTERY := INIT_VIEW_HEIGHT/2: fixed_t;
  SCALE: fixed_t;
  ISCALE: fixed_t;
int     backtangents[TANANGLES*2];
int     autoangle2[MAXAUTO][MAXAUTO];
  scrollmin, scrollmax, bloodcount, metalcount: integer;
procedure (*actionhook);

extern SoundCard SC;

(**** FUNCTIONS ****)

fixed_t FIXEDMUL(fixed_t num1,fixed_t num2)
begin
  return_value: integer;

  _asm mov eax, [num1]
  _asm mov ebx, [num2]
  _asm imul ebx     
    _asm shrd eax, edx, FRACBITS
  _asm mov [return_value], eax

  return return_value;
  end;


fixed_t FIXEDDIV(fixed_t num1,fixed_t num2)
begin
  return_value: integer;

  _asm mov eax, [num1]
  _asm mov ebx, [num2]
  _asm cdq 
  _asm shld edx, eax, FRACBITS 
  _asm sal eax, FRACBITS      
    _asm idiv ebx
  _asm mov [return_value], eax

  return return_value;
  end;


procedure RF_PreloadGraphics;
begin
  i: integer;
  doorlump: integer;

  // find the number of lumps of each type
  spritelump := CA_GetNamedNum('startsprites');
  numsprites := CA_GetNamedNum('endsprites')-spritelump;
  walllump := CA_GetNamedNum('startwalls');
  numwalls := CA_GetNamedNum('endwalls')-walllump;
  flatlump := CA_GetNamedNum('startflats');
  numflats := CA_GetNamedNum('endflats')-flatlump;
  doorlump := CA_GetNamedNum('door_1');
  printf('.');
  // load the lumps
  for (i := 1; i<numsprites; i++)
  begin
   DemandLoadMonster(spritelump+i,1);
//   CA_CacheLump(spritelump+i);
   if i%50 = 0 then
   begin
     printf('.');
     if (newascii) and (lastascii = 27) exit;
      end;

    end;
  printf('.');
  if not debugmode then
  for(i := doorlump;i<numwalls+walllump;i++) CA_CacheLump(i);
  else
  begin
   CA_CacheLump(walllump+1);
   CA_CacheLump(flatlump+1);
    end;
  printf('.');
  end;


procedure RF_InitTargets;
begin
  double  at, atf;
  j, angle, x1, y1, i: integer;
  x, y: fixed_t;

  memset(autoangle2,-1,sizeof(autoangle2));
  i := 0;
  do
  begin
   at := atan((double)i/(double)MAXAUTO);
   atf := at*(double)ANGLES/(2*PI);
   angle := rint(atf);
   for(j := 0;j<MAXAUTO*2;j++)
   begin
     y := FIXEDMUL(sintable[angle],j shl FRACBITS);
     x := FIXEDMUL(costable[angle],j shl FRACBITS);
     x1 := x shr FRACBITS;
     y1 := y shr FRACBITS;
     if (x1 >= MAXAUTO) or (y1 >= MAXAUTO) or (autoangle2[x1][y1] <> -1) continue;
     autoangle2[x1][y1] := angle;
      end;
   i++;
    end; while (angle<DEGREE45+DEGREE45_2);

  for(i := MAXAUTO-1;i>0;i--)
  for(j := 0;j<MAXAUTO;j++)
   if (autoangle2[j][i] = -1) autoangle2[j][i] := autoangle2[j][i-1];
  for(i := MAXAUTO-1;i>0;i--)
  for(j := 0;j<MAXAUTO;j++)
   if (autoangle2[j][i] = -1) autoangle2[j][i] := autoangle2[j][i-1];
  end;


procedure InitTables;
(* Builds tangent tables for -90 degrees to +90 degrees
   and pixel angle table *)
   begin
  double  tang, value, ivalue;
  intval, i: integer;

  // tangent values for wall tracing
  for (i := 0; i<TANANGLES/2; i++)
  begin
   tang := (i+0.5)*PI/(TANANGLES*2);
//   tang := i*PI/(TANANGLES*2);
   value := tan(tang);
   ivalue := 1/value;
   value := rint(value*FRACUNIT);
   ivalue := rint(ivalue*FRACUNIT);
   tangents[TANANGLES + i] := (int)(-value);
   tangents[TANANGLES + TANANGLES - 1 - i] := (int)(-ivalue);
   tangents[i] := (int)(ivalue);
   tangents[TANANGLES - 1 - i] := (int)(value);
    end;
  // high precision sin / cos for distance calculations
  for (i := 0; i<TANANGLES; i++)
  begin
   tang := (i+0.5)*PI/(TANANGLES*2);
//   tang := i*PI/(TANANGLES*2);
   value := sin(tang);
   intval := rint(value*FRACUNIT);
   sines[i] := intval;
   sines[TANANGLES*4 + i] := intval;
   sines[TANANGLES*2 - 1 - i] := intval;
   sines[TANANGLES*2 + i] := -intval;
   sines[TANANGLES*4 - 1 - i] := -intval;
    end;
  cosines := @sines[TANANGLES];
  for(i := 0;i<TANANGLES*2;i++)
  backtangents[i] := ((windowWidth/2)*tangents[i]) shr FRACBITS;
  end;


procedure InitReverseCam;
begin
  i, intval: integer;

  for (i := 0;i<65; i++)
  begin
   intval := rint(atan(((double)32-((double)i+1.0))/(double)32)/(double)PI*(double)TANANGLES*(double)2);
   pixelangle[i] := intval;
   pixelcosine[i] := cosines[intval) and ((TANANGLES * 4 - 1)];
    end;
  memcpy(campixelangle,pixelangle,sizeof(pixelangle));
  memcpy(campixelcosine,pixelcosine,sizeof(pixelcosine));
  end;


procedure RF_Startup;
begin
  i: integer;
  double angle;
  lightlump: integer;

  memset(framevalid, 0, sizeof(framevalid));
  printf('.');
  frameon := 0;
  // trig tables
  for (i := 0; i <= ANGLES; i++)
  begin
   angle := (double)(i * PI * 2)/(double)(ANGLES + 1);
   sintable[i] := rint(sin(angle)*FRACUNIT);
   costable[i] := rint(cos(angle)*FRACUNIT);
    end;
  printf('.');
  SetViewSize(windowWidth,windowHeight);
  // set up lights
  // Allocates a page aligned buffer and load in the light tables
  lightlump := CA_GetNamedNum('lights');
  numcolormaps := infotable[lightlump].size/256;
  colormaps := malloc((size_t)256*(numcolormaps+1));
  colormaps := (byte *)(((int)colormaps+255)) and (~0xff);
  CA_ReadLump(lightlump, colormaps);
  RF_SetLights((fixed_t)MAXZ);
  RF_ClearWorld;
  printf('.');
  // initialize the translation to no animation
  flattranslation := malloc((size_t)(numflats+1)*4);
  walltranslation := malloc((size_t)(numwalls+1)*4);
  if not debugmode then
  begin
   for(i := 0;i <= numflats;i++) flattranslation[i] := i;
   for(i := 0;i <= numwalls;i++) walltranslation[i] := i;
    end;
  else
  begin
   for(i := 1;i <= numflats;i++) flattranslation[i] := 1;
   for(i := 1;i <= numwalls;i++) walltranslation[i] := 1;
   flattranslation[0] := 0;
   walltranslation[0] := 0;
    end;
  actionhook := NULL;
  actionflag := 0;
  RF_InitTargets;
  InitTables;
  printf('.');
  InitReverseCam;
  InitWalls;
  printf('.');
  end;


procedure RF_ClearWorld;
begin
  i: integer;

  firstscaleobj.prev := NULL;
  firstscaleobj.next := @lastscaleobj;
  lastscaleobj.prev := @firstscaleobj;
  lastscaleobj.next := NULL;
  freescaleobj_p := scaleobjlist;
  memset(scaleobjlist,0,sizeof(scaleobjlist));
  for(i := 0;i<MAXSPRITES-1;i++) scaleobjlist[i].next := @scaleobjlist[i+1];
  firstelevobj.prev := NULL;
  firstelevobj.next := @lastelevobj;
  lastelevobj.prev := @firstelevobj;
  lastelevobj.next := NULL;
  freeelevobj_p := elevlist;
  memset(elevlist,0,sizeof(elevlist));
  for(i := 0;i<MAXELEVATORS-1;i++) elevlist[i].next := @elevlist[i+1];
  numdoors := 0;
  numspawnareas := 0;
  bloodcount := 0;
  metalcount := 0;
  end;


doorobj_t *RF_GetDoor(int tilex, int tiley)
begin
  doorobj_t *door;

  if (numdoors = MAXDOORS) MS_Error('RF_GetDoor: Too many doors placed not  (%i,%i)',numdoors,MAXDOORS);
  door := @doorlist[numdoors];
  numdoors++;
  door.tilex := tilex;
  door.tiley := tiley;
  mapflags[tiley*MAPROWS+tilex]) or (:=  FL_DOOR;
  return door;
  end;


scaleobj_t *RF_GetSprite;
(* returns a new sprite *)
begin
  scaleobj_t *new;

  if (not freescaleobj_p) MS_Error('RF_GetSprite: Out of spots in scaleobjlist!');
  new := freescaleobj_p;
  freescaleobj_p := freescaleobj_p.next;
  memset(new,0,sizeof(scaleobj_t));
  new.next := (scaleobj_t *)) and (lastscaleobj;
  new.prev := lastscaleobj.prev;
  lastscaleobj.prev := new;
  new.prev.next := new;
  return new;
  end;


elevobj_t *RF_GetElevator;
(* returns a elevator structure *)
begin
  elevobj_t *new;

  if (not freeelevobj_p) MS_Error('RF_GetElevator: Too many elevators placed!');
  new := freeelevobj_p;
  freeelevobj_p := freeelevobj_p.next;
  memset(new,0,sizeof(elevobj_t));
  new.next := (elevobj_t *)) and (lastelevobj;
  new.prev := lastelevobj.prev;
  lastelevobj.prev := new;
  new.prev.next := new;
  return new;
  end;


spawnarea_t *RF_GetSpawnArea;
begin
  if (numspawnareas = MAXSPAWNAREAS) MS_Error('RF_GetSpawnArea: Too many Spawn Areas placed not  (%i,%i)',numspawnareas,MAXSPAWNAREAS);
  ++numspawnareas;
  return) and (spawnareas[numspawnareas-1];
  end;


procedure Event(int e,bool send);


procedure RF_RemoveSprite(scaleobj_t *spr);
(* removes sprite from doublely linked list of sprites *)
begin
  spr.next.prev := spr.prev;
  spr.prev.next := spr.next;
  spr.next := freescaleobj_p;
  freescaleobj_p := spr;
  end;


procedure RF_RemoveElevator(elevobj_t *e);
begin
  e.next.prev := e.prev;
  e.prev.next := e.next;
  e.next := freeelevobj_p;
  freeelevobj_p := e;
  end;


fixed_t RF_GetFloorZ(fixed_t x, fixed_t y)
begin
  h1, h2, h3, h4: fixed_t;
  tilex, tiley, mapspot: integer;
  polytype: integer;
  fx, fy: fixed_t;
  top, bottom, water: fixed_t;

  tilex := x shr (FRACBITS+TILESHIFT);
  tiley := y shr (FRACBITS+TILESHIFT);
  mapspot := tiley *MAPSIZE+tilex;
  polytype := (mapflags[mapspot]) and (FL_FLOOR) shr FLS_FLOOR;
  if (floorpic[mapspot] >= 57) and (floorpic[mapspot] <= 59) then
  water := -(20 shl FRACBITS);
  else
  water := 0;
  if polytype = POLY_FLAT then
  return (floorheight[mapspot] shl FRACBITS) + water;
  h1 := floorheight[mapspot] shl FRACBITS;
  h2 := floorheight[mapspot+1] shl FRACBITS;
  h3 := floorheight[mapspot+MAPSIZE] shl FRACBITS;
  h4 := floorheight[mapspot+MAPSIZE+1] shl FRACBITS;
  fx := (x) and ((TILEUNIT-1)) shr 6; // range from 0 to fracunit-1
  fy := (y) and ((TILEUNIT-1)) shr 6;
  if polytype = POLY_SLOPE then
  begin
   if (h1 = h2) return h1+FIXEDMUL(h3-h1, fy) + water;
    else return h1+FIXEDMUL(h2-h1, fx) + water;
    end;
  // triangulated slopes
  // set the outside corner of the triangle that the point is NOT in s
  // plane with the other three
  if polytype = POLY_ULTOLR then
  begin
   if (fx>fy) h3 := h1-(h2-h1);
    else h2 := h1+(h1-h3);
    end;
  else
  begin
   if (fx<FRACUNIT-fy) h4 := h2+(h2-h1);
    else h1 := h2-(h4-h2);
    end;
  top := h1+FIXEDMUL(h2-h1, fx);
  bottom := h3+FIXEDMUL(h4-h3, fx);
  return top+FIXEDMUL(bottom-top, fy) + water;
  end;


fixed_t RF_GetCeilingZ(fixed_t x, fixed_t y)
(* find how high the ceiling is at x,y *)
begin
  h1, h2, h3, h4: fixed_t;
  tilex, tiley, mapspot: integer;
  polytype: integer;
  fx, fy: fixed_t;
  top, bottom: fixed_t;

  tilex := x shr (FRACBITS+TILESHIFT);
  tiley := y shr (FRACBITS+TILESHIFT);
  mapspot := tiley *MAPSIZE+tilex;
  polytype := (mapflags[mapspot]) and (FL_CEILING) shr FLS_CEILING;
  // flat
  if (polytype = POLY_FLAT) return ceilingheight[mapspot] shl FRACBITS;
  // constant slopes
  if polytype = POLY_SLOPE then
  begin
   h1 := ceilingheight[mapspot] shl FRACBITS;
   h2 := ceilingheight[mapspot+1] shl FRACBITS;
   if h1 = h2 then
   begin
     h3 := ceilingheight[mapspot+MAPSIZE] shl FRACBITS;
     fy := (y) and ((TILEUNIT-1)) shr 6;
     return h1+FIXEDMUL(h3-h1, fy); // north/south slope
      end;
   else
   begin
     fx := (x) and ((TILEUNIT-1)) shr 6;
     return h1+FIXEDMUL(h2-h1, fx); // east/west slope
      end;
    end;
  // triangulated slopes
  // set the outside corner of the triangle that the point is NOT in s
  // plane with the other three
  h1 := ceilingheight[mapspot] shl FRACBITS;
  h2 := ceilingheight[mapspot+1] shl FRACBITS;
  h3 := ceilingheight[mapspot+MAPSIZE] shl FRACBITS;
  h4 := ceilingheight[mapspot+MAPSIZE+1] shl FRACBITS;
  fx := (x) and ((TILEUNIT-1)) shr 6; // range from 0 to fracunit-1
  fy := (y) and ((TILEUNIT-1)) shr 6;
  if polytype = POLY_ULTOLR then
  begin
   if (fx>fy) h3 := h1-(h2-h1);
    else h2 := h1+(h1-h3);
    end;
  else
  begin
   if (fx<FRACUNIT-fy) h4 := h2+(h2-h1);
    else h1 := h2-(h4-h2);
    end;
  top := h1+FIXEDMUL(h2-h1, fx);
  bottom := h3+FIXEDMUL(h4-h3, fx);
  return top+FIXEDMUL(bottom-top, fy);
  end;


procedure RF_SetActionHook(void (*hook););
begin
  actionhook := hook;
  actionflag := 1;
  end;

procedure r_publicstub2;
begin
  end;


procedure RF_SetLights(fixed_t blackz);
(* resets the color maps to new lighting values *)
begin
  // linear diminishing, table is actually logrithmic
  i, table: integer;

  blackz> >= FRACBITS;
  for (i := 0;i <= MAXZ shr FRACBITS;i++)
  begin
   table := numcolormaps * i/blackz;
   if (table >= numcolormaps) table := numcolormaps-1;
   zcolormap[i] := colormaps+table*256;
    end;
  end;


procedure RF_CheckActionFlag;
begin
  if SC.vrhelmet = 0 then
  TimeUpdate;
  if (not actionflag) exit;
  actionhook;
  actionflag := 0;
  end;


procedure RF_RenderView(fixed_t x, fixed_t y, fixed_t z, int angle);
begin
//#ifdef VALIDATE
// if (x <= 0) or (x >= ((MAPSIZE-1) shl (FRACBITS+TILESHIFT))) or (y <= 0) or (
//  y >= ((MAPSIZE-1) shl (FRACBITS+TILESHIFT)))
//  MS_Error('Invalid RF_RenderView (%p, %p, %p, %i)\n', x, y, z, angle);
//{$ENDIF}

// viewx := (x) and (~0xfff) + $800;
// viewy := (y) and (~0xfff) + $800;
// viewz := (z) and (~0xfff) + $800;

  viewx := x;
  viewy := y;
  viewz := z;
  viewangle := angle) and (ANGLES;
  RF_CheckActionFlag;
  SetupFrame;
  RF_CheckActionFlag;
  FlowView;
  RF_CheckActionFlag;
  RenderSprites;
  DrawSpans;
  RF_CheckActionFlag;
  end;


procedure SetViewSize(int width, int height);
begin
  i: integer;

  if (width>MAX_VIEW_WIDTH) width :=  MAX_VIEW_WIDTH;
  if (height>MAX_VIEW_HEIGHT) height :=  MAX_VIEW_HEIGHT;
  windowHeight :=  height;
  windowWidth :=  width;
  windowSize :=  width*height;
  scrollmax := windowHeight+scrollmin;
  CENTERX := width/2;
  CENTERY := height/2;
  SCALE := (width/2) shl FRACBITS;
  ISCALE := FRACUNIT/(width/2);

  for (i := 0;i<height;i++)
  viewylookup[i] :=  viewbuffer + i * width;

// slopes for rows and collumns of screen pixels
// slightly biased to account for the truncation in coordinates
  for(i := 0;i <= width;i++)
  xslope[i] := rint((float)(i+1-CENTERX)/CENTERX*FRACUNIT);
  for(i := -MAXSCROLL;i<height+MAXSCROLL;i++)
  yslope[i+MAXSCROLL] :=  rint(-(float)(i-0.5-CENTERY)/CENTERX*FRACUNIT);
  for(i := 0;i<TANANGLES*2;i++)
  backtangents[i] := ((width/2)*tangents[i]) shr FRACBITS;
  hfrac := FIXEDDIV(BACKDROPHEIGHT shl FRACBITS,(windowHeight/2) shl FRACBITS);
  afrac := FIXEDDIV(TANANGLES shl FRACBITS,width shl FRACBITS);
  end;

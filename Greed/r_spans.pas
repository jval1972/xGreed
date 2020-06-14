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
#include 'd_global.h'
#include 'r_refdef.h'
#include 'd_video.h'
#include 'd_misc.h'
#include 'r_public.h'

(**** VARIABLES ****)

(*a scaled object is just encoded like a span                                                   *)
unsigned spantags[MAXSPANS];
unsigned *starttaglist_p, *endtaglist_p;        // set by SortSpans
span_t   spans[MAXSPANS];
int      spansx[MAXSPANS];
  spanx: integer;
  pointz, afrac, hfrac: fixed_t;
  numspans: integer;
span_t   *span_p;
  sp_count: integer;
  sp_call: integer;
  mr_count: integer;
  mr_xfrac: integer;
  mr_yfrac: integer;
  mr_xstep: integer;
  mr_ystep: integer;
byte     *sp_dest;          // the bottom most pixel to be drawn (in vie
byte     *sp_source;        // the first pixel in the vertical post (may
byte     *sp_colormap;      // pointer to a 256 byte color number to pal
  sp_frac: integer;
  sp_fracstep: integer;
byte   *mr_picture;
  sp_loopvalue: integer;
byte   *mr_dest;
byte   *mr_colormap;

(**** FUNCTIONS ****)

#define QUICKSORT_CUTOFF 16
#define SWAP(a,b)                \
  begin                                \
  temp := a;                        \
  a := b;                           \
  b := temp;                        \
   end;


procedure MedianOfThree(unsigned *data,unsigned count);
begin
  unsigned temp;

  if count >= 3 then
  begin
   unsigned *beg := data;
   unsigned *mid := data + (count/2);
   unsigned *end := data + (count-1);
   if *beg>*mid then
   begin
     if *mid>*end then
      SWAP(*beg,*mid)
     else if (*beg>*end)
      SWAP(*beg,*end)
   end
   else if *mid>*end then
   begin
     if *beg>*end then
      SWAP(*beg,*end)
      end;
   else
    SWAP(*beg,*mid);
    end;
  end;


int Partition(unsigned *data,unsigned count)
begin
  unsigned part := data[0];
  i := -1: integer;
  j := count: integer;
  unsigned temp;

  while i<j do
  begin
   while (part>data[--j]);
   while (data[++i]>part);
   if i >= j then
    break;
   SWAP(data[i],data[j]);
    end;
  return j+1;
  end;


procedure QuickSortHelper(unsigned *data,unsigned count);
begin
  left := 0: integer;
  part: integer;

  if count>QUICKSORT_CUTOFF then
  begin
   while count>1 do
   begin
     MedianOfThree(data+left,count);
     part := Partition(data+left,count);
     QuickSortHelper(data+left,part);
     left := left + part;
     count := count - part;
      end;
    end;
  end;


procedure InsertionSort(unsigned *data,unsigned count);
begin
  i, j: integer;
  unsigned t;

  for (i := 1;i<(int)count;i++)
  begin
   if data[i]>data[i-1] then
   begin
     t := data[i];
     for (j := i;j) and (t>data[j-1];j--)
      data[j] := data[j-1];
     data[j] := t;
      end;
    end;
  end;


(*************************************************************************)

procedure DrawDoorPost;
begin
  fixed_t top, bottom;    // precise y coordinates for post
  int     topy, bottomy;  // pixel y coordinates for post
  fixed_t fracadjust;     // the amount to prestep for the top pixel
  scale: fixed_t;
  light: integer;

  scale := FIXEDMUL(pointz,ISCALE);
  sp_source := span_p.picture;

  if span_p.shadow = 0 then
  begin
   light := (pointz shr FRACBITS)+span_p.light;
   if (light>MAXZLIGHT) exit;
    else if (light<0) light := 0;
   sp_colormap := zcolormap[light];
  end
  else if (span_p.shadow = 1) sp_colormap := colormaps+(wallglow shl 8);
  else if (span_p.shadow = 2) sp_colormap := colormaps+(wallflicker1 shl 8);
  else if (span_p.shadow = 3) sp_colormap := colormaps+(wallflicker2 shl 8);
  else if (span_p.shadow = 4) sp_colormap := colormaps+(wallflicker3 shl 8);
  else if (span_p.shadow >= 5) and (span_p.shadow <= 8) then
  begin
   if (wallcycle = span_p.shadow-5) sp_colormap := colormaps;
   else
   begin
     light := (pointz shr FRACBITS)+span_p.light;
     if (light>MAXZLIGHT) light := MAXZLIGHT;
      else if (light<0) light := 0;
     sp_colormap := zcolormap[light];
      end;
  end
  else if span_p.shadow = 9 then
  begin
   light := (pointz shr FRACBITS)+span_p.light+wallflicker4;
   if (light>MAXZLIGHT) light := MAXZLIGHT;
    else if (light<0) light := 0;
   sp_colormap := zcolormap[light];
    end;

  sp_fracstep := FIXEDMUL(pointz,ISCALE);
  top := FIXEDDIV(span_p.y,scale);
  topy := top shr FRACBITS;
  fracadjust := top) and ((FRACUNIT-1);
  sp_frac := FIXEDMUL(fracadjust,sp_fracstep);
  topy := CENTERY-topy;
  sp_loopvalue := 256 shl FRACBITS;
  if topy<scrollmin then
  begin
   sp_frac+:= (scrollmin-topy)*scale;
   while (sp_frac>sp_loopvalue) sp_frac-:= sp_loopvalue;
   topy := scrollmin;
    end;
  bottom := FIXEDDIV(span_p.yh,scale);
  bottomy :=  bottom >= ((CENTERY+scrollmin) shl FRACBITS) ?
  scrollmax-1 : CENTERY+(bottom shr FRACBITS);
  if (bottomy <= scrollmin) or (topy >= scrollmax) exit;
  sp_count := bottomy-topy+1;
  sp_dest := viewylookup[bottomy-scrollmin]+spanx;

  if (span_p.spantype = sp_maskeddoor) ScaleMaskedPost;
  else ScalePost;
  end;


void ScaleTransPost
begin
  pixel_t color;

  sp_dest-:= windowWidth*(sp_count-1);     // go to the top
  --sp_loopvalue;
  while --sp_count do
  begin
   color := sp_source[sp_frac shr FRACBITS];
   if color then
    *sp_dest := *(translookup[sp_colormap[color]-1]+*sp_dest);
   sp_dest := sp_dest + windowWidth;
   sp_frac := sp_frac + sp_fracstep;
   sp_frac) and (:= sp_loopvalue;
    end;
  end;


void ScalePost
begin
  sp_dest -:=  windowWidth * (sp_count - 1);     // go to the top
  --sp_loopvalue;
  while sp_count > 0 do
  begin
    *sp_dest :=  sp_source[sp_frac shr FRACBITS];
    sp_dest := sp_dest + windowWidth;
    sp_frac := sp_frac + sp_fracstep;
    sp_frac) and (:=  sp_loopvalue;
    sp_count--;
   end;
  end;


void ScaleMaskedPost
begin
  pixel_t color;

  sp_dest -:=  windowWidth * (sp_count - 1);     // go to the top
  --sp_loopvalue;
  while sp_count > 0 do
  begin
    color :=  sp_source[sp_frac shr FRACBITS];
    if color then
      *sp_dest :=  color;
    sp_dest := sp_dest + windowWidth;
    sp_frac := sp_frac + sp_fracstep;
    sp_frac) and (:=  sp_loopvalue;
    sp_count--;
   end;
  end;


void MapRow
begin
  spot: integer;

  while mr_count > 0 do
  begin
    spot :=  ((mr_yfrac  shr  (FRACBITS - 6))) and ((63 * 64)) + ((mr_xfrac  shr  FRACBITS)) and (63);
    *mr_dest++:=  mr_colormap[mr_picture[spot]];
    mr_xfrac := mr_xfrac + mr_xstep;
    mr_yfrac := mr_yfrac + mr_ystep;
    mr_count--;
   end; 
  end;


procedure DrawSprite;
begin
  leftx, scale, xfrac, fracstep: fixed_t;
  shapebottom, topheight, bottomheight: fixed_t;
  post, x, topy, bottomy, light, shadow, height, bitshift: integer;
  special_t  specialtype;
  scalepic_t *pic;
  byte       *collumn;
  scaleobj_t *sp;

  (********* floor shadows ***********)
  specialtype := (special_t)(span_p.shadow shr 8);
  shadow := span_p.shadow) and (255;

  if (specialtype = st_maxlight) sp_colormap := colormaps;
  else if (specialtype = st_transparent) sp_colormap := colormaps;
  else if shadow = 0 then
  begin
   light := (pointz shr FRACBITS)+span_p.light;
   if (light>MAXZLIGHT) exit;
    else if (light<0) light := 0;
   sp_colormap := zcolormap[light];
  end
  else if (span_p.shadow = 1) sp_colormap := colormaps+(wallglow shl 8);
  else if (span_p.shadow = 2) sp_colormap := colormaps+(wallflicker1 shl 8);
  else if (span_p.shadow = 3) sp_colormap := colormaps+(wallflicker2 shl 8);
  else if (span_p.shadow = 4) sp_colormap := colormaps+(wallflicker3 shl 8);
  else if (span_p.shadow >= 5) and (span_p.shadow <= 8) then
  begin
   if (wallcycle = span_p.shadow-5) sp_colormap := colormaps;
   else
   begin
     light := (pointz shr FRACBITS)+span_p.light;
     if (light>MAXZLIGHT) light := MAXZLIGHT;
      else if (light<0) light := 0;
     sp_colormap := zcolormap[light];
      end;
  end
  else if shadow = 9 then
  begin
   light := (pointz shr FRACBITS)+span_p.light+wallflicker4;
   if (light>MAXZLIGHT) light := MAXZLIGHT;
    else if (light<0) light := 0;
   sp_colormap := zcolormap[light];
    end;

  pic := (scalepic_t *)span_p.picture;
  sp := (scaleobj_t *)span_p.structure;

  bitshift := FRACBITS-sp.scale;

  shapebottom := span_p.y;
  // project the x and height
  scale := FIXEDDIV(FSCALE,pointz);
  fracstep := FIXEDMUL(pointz,ISCALE) shl sp.scale;
  sp_fracstep := fracstep;
  leftx := span_p.x2;
  leftx-:= pic.leftoffset shl bitshift;
  x := CENTERX+(FIXEDMUL(leftx,scale) shr FRACBITS);
  // step through the shape, drawing posts where visible
  xfrac := 0;
  if x<0 then
  begin
   xfrac-:= fracstep * x;
   x := 0;
    end;
  sp_loopvalue := (256 shl FRACBITS);
  height := pic.collumnofs[1]-pic.collumnofs[0];

  for (; x<windowWidth; x++)
  begin
   post := xfrac shr FRACBITS;
   if post >= pic.width then
    exit;   // shape finished drawing
   xfrac := xfrac + fracstep;
   if (pointz >= wallz[x]) and ((pointz >= wallz[x]+TILEUNIT) or ((specialtype <> st_noclip) and (specialtype <> st_transparent))) then
    continue;
   // If the offset of the columns is zero then there is no data for the post
   if pic.collumnofs[post] = 0 then
    continue;
   collumn := (byte *)pic+pic.collumnofs[post];
   topheight := shapebottom+(*collumn shl bitshift);
   bottomheight := shapebottom+(*(collumn+1) shl bitshift);
   collumn := collumn + 2;
   // scale a post

   bottomy := CENTERY - (FIXEDMUL(bottomheight,scale) shr FRACBITS);
   if bottomy<scrollmin then
    continue;
   if bottomy >= scrollmax then
    bottomy := scrollmax-1;

   topy := CENTERY-(FIXEDMUL(topheight,scale) shr FRACBITS);
   if topy<scrollmin then
   begin
     sp_frac := (scrollmin-topy)*sp_fracstep;
     topy := scrollmin;
      end;
   else
    sp_frac := 0;

   if topy >= scrollmax then
    continue;

   sp_count := bottomy-topy+1;

   sp_dest := viewylookup[bottomy-scrollmin]+x;
   sp_source := collumn;
   if specialtype = st_transparent then
    ScaleTransPost;
   else
    ScaleMaskedPost;
    end;
  end;


procedure DrawSpans;
(* Spans farther than MAXZ away should NOT have been entered into the list *)
begin
  unsigned *spantag_p, tag;
  spannum: integer;
  x2: integer;
  fixed_t  lastz;                  // the pointz for which xystep is valid
  length: fixed_t;
  zerocosine, zerosine: fixed_t;
  zeroxfrac, zeroyfrac: fixed_t;
  fixed_t  xf2, yf2;               // endpoint texture for sloping spans
  angle: integer;
  light: integer;
  px, py, h1, x1, center, y1, x: integer;
  a, w: fixed_t;
  pixel_t  color;

  // set up backdrop stuff
  w := windowWidth/2;
  center := viewangle) and (255;

  // set up for drawing
  starttaglist_p := spantags;
  if numspans then
  begin
   QuickSortHelper(starttaglist_p,numspans);
   InsertionSort(starttaglist_p,numspans);
    end;
  endtaglist_p := starttaglist_p+numspans;
  spantag_p := starttaglist_p;

  angle := viewfineangle+pixelangle[0];
  angle) and (:= TANANGLES *4-1;
  zerocosine := cosines[angle];
  zerosine := sines[angle];
  // draw from back to front
  x2 := -1;
  lastz := -1;
  // draw everything else
  while spantag_p <> endtaglist_p do
  begin
   tag := *spantag_p++;
   pointz := tag shr ZTOFRAC;
   spannum := tag) and (SPANMASK;
   span_p := @spans[spannum];
   spanx := spansx[spannum];
   case span_p.spantype  of
   begin
     sp_flat:
     sp_flatsky:
     // floor / ceiling span
      if pointz <> lastz then
      begin
  lastz := pointz;
  mr_xstep := FIXEDMUL(pointz, xscale);
  mr_ystep := FIXEDMUL(pointz, yscale);
  // calculate starting texture point
  length := FIXEDDIV(pointz, pixelcosine[0]);
  zeroxfrac := mr_xfrac := viewx+FIXEDMUL(length, zerocosine);
  zeroyfrac := mr_yfrac := viewy-FIXEDMUL(length, zerosine);
  x2 := 0;
   end;
      if spanx <> x2 then
      begin
  mr_xfrac := zeroxfrac+mr_xstep *spanx;
  mr_yfrac := zeroyfrac+mr_ystep *spanx;
   end;

      (* floor shadows *)
      if span_p.shadow = 0 then
      begin
  light := (pointz shr FRACBITS)+span_p.light;
  if (light>MAXZLIGHT) break;
   else if (light<0) light := 0;
  mr_colormap := zcolormap[light];
      end
      else if span_p.shadow = 9 then
      begin
  light := (pointz shr FRACBITS)+span_p.light+wallflicker4;
  if (light>MAXZLIGHT) break;
   else if (light<0) light := 0;
  mr_colormap := zcolormap[light];
   end;
      else mr_colormap := (byte *)span_p.shadow;

      y1 := span_p.y-scrollmin;

      if ((unsigned)y1 >= 200) break;

      mr_dest := viewylookup[y1]+spanx;
      mr_picture := span_p.picture;
      x2 := span_p.x2;

      if ((unsigned)x2>320) break;

      mr_count := x2-spanx;
      MapRow;

      if span_p.spantype = sp_flatsky then
      begin
  py := span_p.y-scrollmin;
  px := spanx;
  mr_count := span_p.x2-spanx;
  mr_dest := viewylookup[py]+px;
  if (windowHeight <> 64) py := span_p.y+64;
  h1 := (hfrac*py) shr FRACBITS;
  if px <= w then
  begin
    a := ((TANANGLES/2) shl FRACBITS) + afrac*(w-px);
    while (px <= w) and (mr_count>0) do
    begin
      x := backtangents[a shr FRACBITS];
      x2 := center - x + windowWidth - 257;
      x2) and (:= 255;
      if (*mr_dest = 255) *mr_dest := *(backdroplookup[h1]+x2);
      a := a - afrac;
      px++;
      mr_count--;
      mr_dest++;
       end;
     end;
  if px>w then
  begin
    a := ((TANANGLES/2) shl FRACBITS) + afrac*(px-w);
    while mr_count>0 do
    begin
      x1 := center + backtangents[a shr FRACBITS];
      x1) and (:= 255;
      if (*mr_dest = 255) *mr_dest := *(backdroplookup[h1]+x1);
      a := a + afrac;
      px++;
      mr_count--;
      mr_dest++;
       end;
     end;
   end;

      break;
     sp_sky:
      py := span_p.y-scrollmin;
      if ((unsigned)py >= 200) break;
      px := spanx;

      if ((unsigned)span_p.x2>320) break;

      mr_count := span_p.x2-spanx;
      mr_dest := viewylookup[py]+px;
      if (windowHeight <> 64) py := span_p.y+64;
      h1 := (hfrac*py) shr FRACBITS;
      if px <= w then
      begin
  a := ((TANANGLES/2) shl FRACBITS) + afrac*(w-px);
  while (px <= w) and (mr_count>0) do
  begin
    x := backtangents[a shr FRACBITS];
    x2 := center - x + windowWidth - 257;
    x2) and (:= 255;
    *mr_dest := *(backdroplookup[h1]+x2);
    a := a - afrac;
    px++;
    mr_count--;
    mr_dest++;
     end;
   end;
      if px>w then
      begin
  a := ((TANANGLES/2) shl FRACBITS) + afrac*(px-w);
  while mr_count>0 do
  begin
    x1 := center + backtangents[a shr FRACBITS];
    x1) and (:= 255;
    *mr_dest := *(backdroplookup[h1]+x1);
    a := a + afrac;
    px++;
    mr_count--;
    mr_dest++;
     end;
   end;
      break;
     sp_step:
      x := span_p.x2;
      sp_dest := tpwalls_dest[x];
      sp_source := span_p.picture;
      sp_colormap := tpwalls_colormap[x];
      sp_frac := span_p.y;
      sp_fracstep := span_p.yh;
      sp_count := tpwalls_count[x];
      sp_loopvalue := (fixed_t)span_p.light shl FRACBITS;
      ScalePost;
      break;
     sp_shape:
      DrawSprite;
      break;
     sp_slope:
     sp_slopesky:
      // sloping floor / ceiling span
      lastz := -1;  // we are going to get out of order here, so

      if span_p.shadow = 0 then
      begin
  light := (pointz shr FRACBITS)+span_p.light;
  if (light>MAXZLIGHT) break;
   else if (light<0) light := 0;
  mr_colormap := zcolormap[light];
      end
      else if span_p.shadow = 9 then
      begin
  light := (pointz shr FRACBITS)+span_p.light+wallflicker4;
  if (light>MAXZLIGHT) break;
   else if (light<0) light := 0;
  mr_colormap := zcolormap[light];
   end;
      else mr_colormap := (byte *)span_p.shadow;

      x2 := span_p.x2;
      y1 := span_p.y-scrollmin;

      if ((unsigned)y1 >= 200) break;
      if ((unsigned)x2>320) break;

      mr_dest := viewylookup[y1]+spanx;
      mr_picture := span_p.picture;
      mr_count := x2-spanx;
      // calculate starting texture point
      length := FIXEDDIV(pointz, pixelcosine[spanx]);
      angle := viewfineangle+pixelangle[spanx];
      angle) and (:= TANANGLES *4-1;
      mr_xfrac := viewx+FIXEDMUL(length, cosines[angle]);
      mr_yfrac := viewy-FIXEDMUL(length, sines[angle]);
      // calculate ending texture point
      //  (yh is pointz2 for ending point)
      length := FIXEDDIV(span_p.yh, pixelcosine[x2]);
      angle := viewfineangle+pixelangle[x2];
      angle) and (:= TANANGLES *4-1;
      xf2 := viewx+FIXEDMUL(length, cosines[angle]);
      yf2 := viewy-FIXEDMUL(length, sines[angle]);
      mr_xstep := (xf2-mr_xfrac)/mr_count;
      mr_ystep := (yf2-mr_yfrac)/mr_count;
      MapRow;

      if span_p.spantype = sp_slopesky then
      begin
  py := span_p.y-scrollmin;
  px := spanx;
  mr_count := span_p.x2-spanx;
  mr_dest := viewylookup[py]+px;
  if (windowHeight <> 64) py := span_p.y+64;
  h1 := (hfrac*py) shr FRACBITS;
  if px <= w then
  begin
    a := ((TANANGLES/2) shl FRACBITS) + afrac*(w-px);
    while (px <= w) and (mr_count>0) do
    begin
      x := backtangents[a shr FRACBITS];
      x2 := center - x + windowWidth - 257;
      x2) and (:= 255;
      if (*mr_dest = 255) *mr_dest := *(backdroplookup[h1]+x2);
      a := a - afrac;
      px++;
      mr_count--;
      mr_dest++;
       end;
     end;
  if px>w then
  begin
    a := ((TANANGLES/2) shl FRACBITS) + afrac*(px-w);
    while mr_count>0 do
    begin
      x1 := center + backtangents[a shr FRACBITS];
      x1) and (:= 255;
      if (*mr_dest = 255) *mr_dest := *(backdroplookup[h1]+x1);
      a := a + afrac;
      px++;
      mr_count--;
      mr_dest++;
       end;
     end;
   end;
      break;
     sp_door:
     sp_maskeddoor:
      DrawDoorPost;
      break;
     sp_transparentwall:
      x := span_p.x2;
      sp_dest := tpwalls_dest[x];
      sp_source := span_p.picture;
      sp_colormap := tpwalls_colormap[x];
      sp_frac := span_p.y;
      sp_fracstep := span_p.yh;
      sp_count := tpwalls_count[x];
      sp_loopvalue := (fixed_t)span_p.light shl FRACBITS;
      ScaleMaskedPost;
      break;
     sp_inviswall:
      x := span_p.x2;
      sp_dest := tpwalls_dest[x];
      sp_source := span_p.picture;
      sp_colormap := tpwalls_colormap[x];
      sp_frac := span_p.y;
      sp_fracstep := span_p.yh;
      sp_count := tpwalls_count[x];
      sp_loopvalue := (fixed_t)span_p.light shl FRACBITS;
      sp_dest-:= windowWidth*(sp_count-1);     // go to the top
      --sp_loopvalue;
      while sp_count-- do
      begin
  color := sp_source[sp_frac shr FRACBITS];
  if color then
   *sp_dest := *(translookup[sp_colormap[color]-1]+*sp_dest);
  sp_dest := sp_dest + windowWidth;
  sp_frac := sp_frac + sp_fracstep;
  sp_frac) and (:= sp_loopvalue;
   end;
      break;
      end;
    end;
  end;

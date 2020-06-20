(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020 by Jim Valavanis                                     *)
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

unit r_spans;

interface

uses
  g_delphi,
  r_public_h,
  r_refdef;

var
(*a scaled object is just encoded like a span                                                   *)
  spantags: array[0..MAXSPANS - 1] of LongWord;
  starttaglist_p: PLongWordArray;        // set by SortSpans
  endtaglist_p: PLongWord;
  spans: array[0..MAXSPANS - 1] of span_t;
  spansx: array[0..MAXSPANS - 1] of integer;
  spanx: integer;
  pointz, afrac, hfrac: fixed_t;
  numspans: integer;
  span_p: Pspan_t;
  sp_count: integer;
  sp_call: integer;
  mr_count: integer;
  mr_xfrac: integer;
  mr_yfrac: integer;
  mr_xstep: integer;
  mr_ystep: integer;
  sp_dest: PByteArray;          // the bottom most pixel to be drawn (in vie
  sp_source: PByteArray;        // the first pixel in the vertical post (may
  sp_colormap: PByteArray;      // pointer to a 256 byte color number to pal
  sp_frac: integer;
  sp_fracstep: integer;
  mr_picture: PByteArray;
  sp_loopvalue: integer;
  mr_dest: PByteArray;
  mr_colormap: PByteArray;

procedure ScalePost;

procedure DrawSpans;

implementation

uses
  d_video,
  raven,
  r_public,
  r_render,
  r_walls;

const
  QUICKSORT_CUTOFF = 16;

procedure SWAPL(const a, b: PLongWord);
var
  tmp: LongWord;
begin
  tmp := a^;
  a^ := b^;
  b^ := tmp;
end;

procedure MedianOfThree(const data: PLongWordArray; const count: integer);
var
  temp: LongWord;
  beg, mid, stop: PLongWord;
begin
  if count >= 3 then
  begin
    beg := @data[0];
    mid := @data[count div 2];
    stop := @data[count - 1];
    if beg^ > mid^ then
    begin
      if mid^ > stop^ then
        SWAPL(beg, mid)
      else if beg^ > stop^ then
       SWAPL(beg, stop)
    end
    else if mid^ > stop^ then
    begin
      if beg^ > stop^ then
        SWAPL(beg, stop);
    end
    else
      SWAPL(beg, mid);
  end;
end;


function Partition(const data: PLongWordArray; const count: LongWord): integer;
var
  part, temp: LongWord;
  i, j: integer;
begin
  part := data[0];
  i := -1;
  j := count;

  while i < j do
  begin
    while part > data[CSubI(j, 1)] do;
    while data[CAddI(i, 1)] > part do;
    if i >= j then
      break;
    SWAPL(@data[i], @data[j]);
  end;
  result := j + 1;
end;


procedure QuickSortHelper(const data: PLongWordArray; count: LongWord);
var
  left, part: integer;
begin
  left := 0;

  if count > QUICKSORT_CUTOFF then
  begin
    while count > 1 do
    begin
      MedianOfThree(@data[left], count);
      part := Partition(@data[left], count);
      QuickSortHelper(@data[left], part);
      left := left + part;
      count := count - part;
    end;
  end;
end;


procedure InsertionSort(const data: PLongWordArray; const count: LongWord);
var
  i, j: integer;
  t: LongWord;
begin
  for i := 1 to count - 1 do
  begin
    if data[i] > data[i - 1] then
    begin
      t := data[i];
      j := i;
      while (j <> 0) and (t > data[j - 1]) do
      begin
        data[j] := data[j - 1];
        dec(j);
      end;
      data[j] := t;
    end;
  end;
end;


procedure ScaleMaskedPost;
var
  color: pixel_t;
begin
  sp_dest := @sp_dest[-windowWidth * (sp_count - 1)];     // go to the top
  while sp_count > 0 do
  begin
    color := sp_source[sp_frac div FRACUNIT];
    if color <> 0 then
      sp_dest[0] :=  color;
    sp_dest := @sp_dest[windowWidth];
    sp_frac := sp_frac + sp_fracstep;
    sp_frac := sp_frac and sp_loopvalue;  // JVAL: SOS
    dec(sp_count);
  end;
end;


procedure ScalePost;
begin
  sp_dest := @sp_dest[-windowWidth * (sp_count - 1)];     // go to the top
  while sp_count > 0 do
  begin
    sp_dest[0] := sp_source[sp_frac div FRACUNIT];
    sp_dest := @sp_dest[windowWidth];
    sp_frac := sp_frac + sp_fracstep;
    sp_frac := sp_frac and sp_loopvalue;  // JVAL: SOS
    dec(sp_count);
  end;
end;


procedure DrawDoorPost;
var
  top, bottom: fixed_t;    // precise y coordinates for post
  topy, bottomy: integer;  // pixel y coordinates for post
  fracadjust: fixed_t;     // the amount to prestep for the top pixel
  scale: fixed_t;
  light: integer;
begin
  scale := FIXEDMUL(pointz, ISCALE);
  sp_source := span_p.picture;

  if span_p.shadow = 0 then
  begin
    light := (pointz div FRACUNIT) + span_p.light;
    if light > MAXZLIGHT then exit;
    if light < 0 then light := 0;
    sp_colormap := zcolormap[light];
  end
  else if span_p.shadow = 1 then
    sp_colormap := @colormaps[wallglow shl 8]
  else if span_p.shadow = 2 then
    sp_colormap := @colormaps[wallflicker1 shl 8]
  else if span_p.shadow = 3 then
    sp_colormap := @colormaps[wallflicker2 shl 8]
  else if span_p.shadow = 4 then
    sp_colormap := @colormaps[wallflicker3 shl 8]
  else if (span_p.shadow >= 5) and (span_p.shadow <= 8) then
  begin
    if wallcycle = span_p.shadow - 5 then
      sp_colormap := colormaps
    else
    begin
      light := (pointz div FRACUNIT) + span_p.light;
      if light > MAXZLIGHT then
        light := MAXZLIGHT
      else if light < 0 then
        light := 0;
      sp_colormap := zcolormap[light];
    end;
  end
  else if span_p.shadow = 9 then
  begin
    light := (pointz div FRACUNIT) + span_p.light + wallflicker4;
    if light > MAXZLIGHT then
      light := MAXZLIGHT
    else if light < 0 then
      light := 0;
    sp_colormap := zcolormap[light];
  end;

  sp_fracstep := FIXEDMUL(pointz, ISCALE);
  top := FIXEDDIV(span_p.y, scale);
  topy := top div FRACUNIT;
  fracadjust := top and (FRACUNIT - 1);
  sp_frac := FIXEDMUL(fracadjust, sp_fracstep);
  topy := CENTERY - topy;
  sp_loopvalue := 256 * FRACUNIT - 1;
  if topy < scrollmin then
  begin
    sp_frac := sp_frac + (scrollmin - topy) * scale;
    while sp_frac > sp_loopvalue do
      sp_frac := sp_frac - sp_loopvalue - 1;
    topy := scrollmin;
  end;
  bottom := FIXEDDIV(span_p.yh, scale);
  if bottom >= (CENTERY + scrollmin) * FRACUNIT then
    bottomy :=  scrollmax - 1
  else
    bottomy := CENTERY + (bottom div FRACUNIT);
  if (bottomy <= scrollmin) or (topy >= scrollmax) then exit;
  sp_count := bottomy - topy + 1;
  sp_dest := @viewylookup[bottomy - scrollmin][spanx];

  if span_p.spantype = sp_maskeddoor then
    ScaleMaskedPost
  else
    ScalePost;
end;


procedure ScaleTransPost;
var
  color: pixel_t;
begin
  sp_dest := @sp_dest[-windowWidth * (sp_count - 1)]; // go to the top
  while sp_count > 0 do
  begin
    dec(sp_count);
    if sp_count = 0 then
      break;
    color := sp_source[sp_frac div FRACUNIT];
    if color <> 0 then
      sp_dest[0] := translookup[sp_colormap[color] - 1][sp_dest[0]];
    sp_dest := @sp_dest[windowWidth];
    sp_frac := sp_frac + sp_fracstep;
    sp_frac := sp_frac and sp_loopvalue;  // JVAL: SOS
  end;
end;


procedure MapRow;
var
  spot: integer;
begin
  while mr_count > 0 do
  begin
    spot := (mr_yfrac shr (FRACBITS - 6)) and (63 * 64) + ((mr_xfrac div FRACUNIT) and 63);
    mr_dest[0] := mr_colormap[mr_picture[spot]];
    mr_dest := @mr_dest[1];
    mr_xfrac := mr_xfrac + mr_xstep;
    mr_yfrac := mr_yfrac + mr_ystep;
    dec(mr_count);
  end;
end;

var
  stubpic: array[0..4095] of integer;
procedure DrawSprite;
var
  leftx, scale, xfrac, fracstep: fixed_t;
  shapebottom, topheight, bottomheight: fixed_t;
  post, x, topy, bottomy, light, shadow, height, bitshift: integer;
  specialtype: special_t;
  pic: Pscalepic_t;
  collumn: PByteArray;
  sp: Pscaleobj_t;
begin
  (********* floor shadows ***********)
  specialtype := special_t(span_p.shadow shr 8);
  shadow := span_p.shadow and 255;

  if specialtype = st_maxlight then sp_colormap := colormaps
  else if specialtype = st_transparent then sp_colormap := colormaps
  else if shadow = 0 then
  begin
    light := (pointz div FRACUNIT) + span_p.light;
    if light > MAXZLIGHT then exit;
    if light < 0 then light := 0;
    sp_colormap := zcolormap[light];
  end
  else if span_p.shadow = 1 then
    sp_colormap := @colormaps[wallglow shl 8]
  else if span_p.shadow = 2 then
    sp_colormap := @colormaps[wallflicker1 shl 8]
  else if span_p.shadow = 3 then
    sp_colormap := @colormaps[wallflicker2 shl 8]
  else if span_p.shadow = 4 then
    sp_colormap := @colormaps[wallflicker3 shl 8]
  else if (span_p.shadow >= 5) and (span_p.shadow <= 8) then
  begin
    if wallcycle = span_p.shadow - 5 then sp_colormap := colormaps
    else
    begin
      light := (pointz div FRACUNIT) + span_p.light;
      if light > MAXZLIGHT then light := MAXZLIGHT
      else if light < 0 then light := 0;
      sp_colormap := zcolormap[light];
    end;
  end
  else if shadow = 9 then
  begin
    light := (pointz div FRACUNIT) + span_p.light + wallflicker4;
    if light > MAXZLIGHT then light := MAXZLIGHT
    else if light < 0 then light := 0;
    sp_colormap := zcolormap[light];
  end;

  pic := Pscalepic_t(span_p.picture);
  if pic = nil then
    pic := @stubpic;
//  if pic = nil then
//    exit; // JVAL: SOS
  sp := Pscaleobj_t(span_p.structure);

  bitshift := FRACBITS - sp.scale;

  shapebottom := span_p.y;
  // project the x and height
  scale := FIXEDDIV(FSCALE, pointz);
  fracstep := FIXEDMUL(pointz, ISCALE) shl sp.scale;
  sp_fracstep := fracstep;
  leftx := span_p.x2;
  leftx := leftx - pic.leftoffset shl bitshift;
  x := CENTERX + (FIXEDMUL(leftx, scale) div FRACUNIT);
  // step through the shape, drawing posts where visible
  xfrac := 0;
  if x < 0 then
  begin
    xfrac := xfrac - fracstep * x;
    x := 0;
  end;
  sp_loopvalue := 256 * FRACUNIT - 1;
  height := pic.collumnofs[1] - pic.collumnofs[0];

  while x < windowWidth do
  begin
    post := xfrac div FRACUNIT;
    if post >= pic.width then
      exit;   // shape finished drawing
    xfrac := xfrac + fracstep;
    if (pointz >= wallz[x]) and ((pointz >= wallz[x] + TILEUNIT) or ((specialtype <> st_noclip) and (specialtype <> st_transparent))) then
    begin
      inc(x);
      continue;
    end;
    // If the offset of the columns is zero then there is no data for the post
    if pic.collumnofs[post] = 0 then
    begin
      inc(x);
      continue;
    end;
    collumn := @PByteArray(pic)[pic.collumnofs[post]];
    topheight := shapebottom + collumn[0] shl bitshift;
    bottomheight := shapebottom + collumn[1] shl bitshift;
    collumn := @collumn[2];

    // scale a post
    bottomy := CENTERY - FIXEDMUL(bottomheight, scale) div FRACUNIT;
    if bottomy < scrollmin then
    begin
      inc(x);
      continue;
    end;
    if bottomy >= scrollmax then
      bottomy := scrollmax - 1;

    topy := CENTERY - FIXEDMUL(topheight, scale) div FRACUNIT;
    if topy < scrollmin then
    begin
      sp_frac := (scrollmin - topy) * sp_fracstep;
      topy := scrollmin;
    end
    else
      sp_frac := 0;

    if topy >= scrollmax then
    begin
      inc(x);
      continue;
    end;

    sp_count := bottomy - topy + 1;

    sp_dest := @viewylookup[bottomy - scrollmin][x];
    sp_source := collumn;
    if specialtype = st_transparent then
      ScaleTransPost
    else
      ScaleMaskedPost;
    inc(x);
  end;
end;

var
xxxx: integer = 0;

// Spans farther than MAXZ away should NOT have been entered into the list
procedure DrawSpans;
var
  spantag_p: PLongWord;
  tag: LongWord;
  spannum: integer;
  x2: integer;
  lastz: fixed_t; // the pointz for which xystep is valid
  len: fixed_t;
  zerocosine, zerosine: fixed_t;
  zeroxfrac, zeroyfrac: fixed_t;
  xf2, yf2: fixed_t;  // endpoint texture for sloping spans
  angle: integer;
  light: integer;
  px, py, h1, x1, center, y1, x: integer;
  a, w: fixed_t;
  color: pixel_t;
label
  abort1;
begin
  // set up backdrop stuff
  w := windowWidth div 2;
  center := viewangle and 255;

  // set up for drawing
  starttaglist_p := @spantags[0];
  if numspans > 0 then
  begin
    QuickSortHelper(starttaglist_p, numspans);
    InsertionSort(starttaglist_p, numspans);
  end;
  endtaglist_p := @starttaglist_p[numspans];
  spantag_p := @starttaglist_p[0];

  angle := viewfineangle + pixelangle[0];
  angle := angle and (TANANGLES * 4 - 1);
  zerocosine := cosines[angle];
  zerosine := sines[angle];
  // draw from back to front
  x2 := -1;
  lastz := -1;
  // draw everything else
  while spantag_p <> endtaglist_p do
  begin
    tag := spantag_p^;
    inc(spantag_p);
    pointz := tag shr ZTOFRAC;
    spannum := tag and SPANMASK;
    span_p := @spans[spannum];
    spanx := spansx[spannum];
    case span_p.spantype of
    sp_flat,
    sp_flatsky:
      begin
        // floor / ceiling span
        if pointz <> lastz then
        begin
          lastz := pointz;
          mr_xstep := FIXEDMUL(pointz, xscale);
          mr_ystep := FIXEDMUL(pointz, yscale);
          // calculate starting texture point
          len := FIXEDDIV(pointz, pixelcosine[0]);
          mr_xfrac := viewx + FIXEDMUL(len, zerocosine);
          zeroxfrac := mr_xfrac;
          mr_yfrac := viewy - FIXEDMUL(len, zerosine);
          zeroyfrac := mr_yfrac;
          x2 := 0;
        end;
        if spanx <> x2 then
        begin
          mr_xfrac := zeroxfrac + mr_xstep * spanx;
          mr_yfrac := zeroyfrac + mr_ystep * spanx;
        end;

        // floor shadows
        if span_p.shadow = 0 then
        begin
          light := (pointz div FRACUNIT) + span_p.light;
          if light > MAXZLIGHT then goto abort1;
          if light < 0 then light := 0;
          mr_colormap := zcolormap[light];
        end
        else if span_p.shadow = 9 then
        begin
          light := (pointz div FRACUNIT) + span_p.light + wallflicker4;
          if light > MAXZLIGHT then goto abort1;
          if light < 0 then light := 0;
          mr_colormap := zcolormap[light];
        end
        else
          mr_colormap := PByteArray(span_p.shadow);

          y1 := span_p.y - scrollmin;

          if (y1 >= 200) or (y1 < 0) then goto abort1; // JVAL SOS

          mr_dest := @viewylookup[y1][spanx];
          mr_picture := span_p.picture;
          x2 := span_p.x2;

          if (x2 > 320) or (x2 < 0) then goto abort1; // JVAL SOS

          mr_count := x2 - spanx;
          MapRow;

          if span_p.spantype = sp_flatsky then
          begin
            py := span_p.y - scrollmin;
            px := spanx;
            mr_count := span_p.x2 - spanx;
            mr_dest := @viewylookup[py][px];
            if windowHeight <> 64 then
              py := span_p.y + 64;
            h1 := (hfrac * py) div FRACUNIT;
            if px <= w then
            begin
              a := ((TANANGLES div 2) * FRACUNIT) + afrac * (w - px);
              while (px <= w) and (mr_count>0) do
              begin
                x := backtangents[a div FRACUNIT];
                x2 := center - x + windowWidth - 257;
                x2 := x2 and 255;
                if mr_dest[0] = 255 then
                  mr_dest[0] := backdroplookup[h1][x2];
                a := a - afrac;
                inc(px);
                dec(mr_count);
                mr_dest := @mr_dest[1];
              end;
            end;
            if px > w then
            begin
              a := ((TANANGLES div 2) * FRACUNIT) + afrac * (px - w);
              while mr_count > 0 do
              begin
                x1 := center + backtangents[a div FRACUNIT];
                x1 := x1 and 255;
                if mr_dest[0] = 255 then
                  mr_dest[0] := backdroplookup[h1][x1];
                a := a + afrac;
                inc(px);
                dec(mr_count);
                mr_dest := @mr_dest[1];
              end;
            end;
          end;

      end;

    sp_sky:
      begin
        py := span_p.y - scrollmin;
        if (py >= 200) or (py < 0) then
          goto abort1;  // JVAL: SOS
        px := spanx;

        if (span_p.x2 > 320) or (span_p.x2 < 0) then
          goto abort1;  // JVAL: SOS

        mr_count := span_p.x2 - spanx;
        mr_dest := @viewylookup[py][px];
        if windowHeight <> 64 then
          py := span_p.y + 64;
        h1 := (hfrac * py) div FRACUNIT;
        if px <= w then
        begin
          a := ((TANANGLES div 2) * FRACUNIT) + afrac * (w - px);
          while (px <= w) and (mr_count > 0) do
          begin
            x := backtangents[a div FRACUNIT];
            x2 := center - x + windowWidth - 257;
            x2 := x2 and 255;
            mr_dest[0] := backdroplookup[h1][x2];
            a := a - afrac;
            inc(px);
            dec(mr_count);
            mr_dest := @mr_dest[1];
          end;
        end;
        if px > w then
        begin
          a := ((TANANGLES div 2) * FRACUNIT) + afrac * (px - w);
          while mr_count > 0 do
          begin
            x1 := center + backtangents[a div FRACUNIT];
            x1 := x1 and 255;
            mr_dest[0] := backdroplookup[h1][x1];
            a := a + afrac;
            inc(px);
            dec(mr_count);
            mr_dest := @mr_dest[1];
          end;
        end;
      end;
      
    sp_step:
      begin
        x := span_p.x2;
        sp_dest := tpwalls_dest[x];
        sp_source := span_p.picture;
        sp_colormap := tpwalls_colormap[x];
        sp_frac := span_p.y;
        sp_fracstep := span_p.yh;
        sp_count := tpwalls_count[x];
        sp_loopvalue := span_p.light * FRACUNIT - 1;
        ScalePost;
      end;

    sp_shape:
    begin
      inc(xxxx);
      if xxxx = 16 then
        DrawSprite
      else
        DrawSprite;
    end;

    sp_slope,
    sp_slopesky:
      begin
        // sloping floor / ceiling span
        lastz := -1;  // we are going to get out of order here, so

        if span_p.shadow = 0 then
        begin
          light := (pointz div FRACUNIT) + span_p.light;
          if light > MAXZLIGHT then goto abort1;
          if light < 0 then light := 0;
          mr_colormap := zcolormap[light];
        end
        else if span_p.shadow = 9 then
        begin
          light := (pointz div FRACUNIT) + span_p.light + wallflicker4;
          if light > MAXZLIGHT then goto abort1;
          if light < 0 then light := 0;
          mr_colormap := zcolormap[light];
        end
        else
          mr_colormap := PByteArray(span_p.shadow);

        x2 := span_p.x2;
        y1 := span_p.y - scrollmin;

        if (y1 >= 200) or (y1 < 0) then goto abort1;  // JVAL: SOS
        if (x2 > 320) or (x2 < 0) then goto abort1;  // JVAL: SOS

        mr_dest := @viewylookup[y1][spanx];
        mr_picture := span_p.picture;
        mr_count := x2 - spanx;
        // calculate starting texture point
        len := FIXEDDIV(pointz, pixelcosine[spanx]);
        angle := viewfineangle + pixelangle[spanx];
        angle := angle and (TANANGLES * 4 - 1);
        mr_xfrac := viewx + FIXEDMUL(len, cosines[angle]);
        mr_yfrac := viewy - FIXEDMUL(len, sines[angle]);
        // calculate ending texture point
        //  (yh is pointz2 for ending point)
        len := FIXEDDIV(span_p.yh, pixelcosine[x2]);
        angle := viewfineangle + pixelangle[x2];
        angle := angle and (TANANGLES * 4 - 1);
        xf2 := viewx + FIXEDMUL(len, cosines[angle]);
        yf2 := viewy - FIXEDMUL(len, sines[angle]);
        mr_xstep := (xf2 - mr_xfrac) div mr_count;
        mr_ystep := (yf2 - mr_yfrac) div mr_count;
        MapRow;

        if span_p.spantype = sp_slopesky then
        begin
          py := span_p.y - scrollmin;
          px := spanx;
          mr_count := span_p.x2 - spanx;
          mr_dest := @viewylookup[py][px];
          if windowHeight <> 64 then
            py := span_p.y + 64;
          h1 := (hfrac * py) div FRACUNIT;
          if px <= w then
          begin
            a := ((TANANGLES div 2) * FRACUNIT) + afrac * (w - px);
            while (px <= w) and (mr_count > 0) do
            begin
              x := backtangents[a div FRACUNIT];
              x2 := center - x + windowWidth - 257;
              x2 := x2 and 255;
              if mr_dest[0] = 255 then
                mr_dest[0] := backdroplookup[h1][x2];
              a := a - afrac;
              inc(px);
              dec(mr_count);
              mr_dest := @mr_dest[1];
            end;
          end;
          if px > w then
          begin
            a := ((TANANGLES div 2) * FRACUNIT) + afrac * (px - w);
            while mr_count > 0 do
            begin
              x1 := center + backtangents[a div FRACUNIT];
              x1 := x1 and 255;
              if mr_dest[0] = 255 then
                mr_dest[0] := backdroplookup[h1][x1];
              a := a + afrac;
              inc(px);
              dec(mr_count);
              mr_dest := @mr_dest[1];
            end;
          end;
        end;
      end;

    sp_door,
    sp_maskeddoor:
      DrawDoorPost;

    sp_transparentwall:
      begin
        x := span_p.x2;
        sp_dest := tpwalls_dest[x];
        sp_source := span_p.picture;
        sp_colormap := tpwalls_colormap[x];
        sp_frac := span_p.y;
        sp_fracstep := span_p.yh;
        sp_count := tpwalls_count[x];
        sp_loopvalue := span_p.light * FRACUNIT - 1;
        ScaleMaskedPost;
      end;

    sp_inviswall:
      begin
        x := span_p.x2;
        sp_dest := tpwalls_dest[x];
        sp_source := span_p.picture;
        sp_colormap := tpwalls_colormap[x];
        sp_frac := span_p.y;
        sp_fracstep := span_p.yh;
        sp_count := tpwalls_count[x];
        sp_loopvalue := span_p.light * FRACUNIT - 1;
        sp_dest := @sp_dest[-windowWidth * (sp_count - 1)]; // go to the top
        while sp_count > 0 do
        begin
          dec(sp_count);
          color := sp_source[sp_frac div FRACUNIT];
          if color <> 0 then
            sp_dest[0] := translookup[sp_colormap[color] - 1][sp_dest[0]];
          sp_dest := @sp_dest[windowWidth];
          sp_frac := sp_frac + sp_fracstep;
          sp_frac := sp_frac and sp_loopvalue; // JVAL: SOS
        end;
      end;
    end;
abort1:
  end;
end;

end.


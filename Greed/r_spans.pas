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

unit r_spans;

interface

uses
  g_delphi,
  r_public_h,
  r_refdef;

var
(*a scaled object is just encoded like a span                                                   *)
  spantags: array[0..MAXSPANS - 1] of tag_t;
  starttaglist_p: Ptag_tArray;        // set by SortSpans
  endtaglist_p: Ptag_t;
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
  {$IFDEF VALIDATEOVERFLOW}
  d_misc,
  {$ENDIF}
  d_video,
  raven,
  r_public,
  r_render,
  r_walls;

const
  QUICKSORT_CUTOFF = 16;


procedure SWAPTAG(const a, b: Ptag_t);
var
  tmp: tag_t;
begin
  tmp := a^;
  a^ := b^;
  b^ := tmp;
end;

function COMPARETAG(const t1, t2: Ptag_t): integer;
begin
  if t1.point > t2.point then
    result := -1
  else if t1.point < t2.point then
    result := 1
  else if t1.span > t2.span then
    result := -1
  else if t2.span < t2.span then
    result := 1
  else
    result := 0;
end;

procedure MedianOfThree(const data: Ptag_tArray; const count: integer);
var
  beg, mid, stop: Ptag_t;
begin
  if count >= 3 then
  begin
    beg := @data[0];
    mid := @data[count div 2];
    stop := @data[count - 1];
    if COMPARETAG(beg, mid) = -1 then
    begin
      if COMPARETAG(mid, stop) = -1 then
        SWAPTAG(beg, mid)
      else if COMPARETAG(beg, stop) = -1 then
       SWAPTAG(beg, stop)
    end
    else if COMPARETAG(mid, stop) = -1 then
    begin
      if COMPARETAG(beg, stop) = -1 then
        SWAPTAG(beg, stop);
    end
    else
      SWAPTAG(beg, mid);
  end;
end;


function Partition(const data: Ptag_tArray; const count: LongWord): integer;
var
  part: tag_t;
  i, j: integer;
begin
  part := data[0];
  i := -1;
  j := count;

  while i < j do
  begin
    while COMPARETAG(@part, @data[CSubI(j, 1)]) = -1 do;
    while COMPARETAG(@data[CAddI(i, 1)], @part) = -1 do;
    if i >= j then
      break;
    SWAPTAG(@data[i], @data[j]);
  end;
  result := j + 1;
end;


procedure QuickSortHelper(const data: Ptag_tArray; count: LongWord);
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


procedure InsertionSort(const data: Ptag_tArray; const count: LongWord);
var
  i, j: integer;
  t: tag_t;
begin
  for i := 1 to count - 1 do
  begin
    if COMPARETAG(@data[i], @data[i - 1]) = -1 then
    begin
      t := data[i];
      j := i;
      while (j <> 0) and (COMPARETAG(@t, @data[j - 1]) = -1) do
      begin
        data[j] := data[j - 1];
        dec(j);
      end;
      data[j] := t;
    end;
  end;
end;

var
  numspanexceptions: integer = 0;

procedure ScaleMaskedPost;
var
  color: pixel_t;
begin
  sp_dest := @sp_dest[-windowWidth * (sp_count - 1)];     // go to the top
  while sp_count > 0 do
  begin
  {$IFDEF VALIDATE}
    try
  {$ENDIF}
    color := sp_source[sp_frac div FRACUNIT];
    if color <> 0 then
      sp_dest[0] := sp_colormap[color];
    sp_dest := @sp_dest[windowWidth];
    sp_frac := sp_frac + sp_fracstep;
    sp_frac := sp_frac and sp_loopvalue;  // JVAL: SOS
    dec(sp_count);
  {$IFDEF VALIDATE}
    except
      inc(numspanexceptions);
      exit;
    end;
  {$ENDIF}
  end;
end;


procedure ScalePost;
begin
  sp_dest := @sp_dest[-windowWidth * (sp_count - 1)];     // go to the top
  while sp_count > 0 do
  begin
  {$IFDEF VALIDATE}
    try
  {$ENDIF}
    sp_dest[0] := sp_colormap[sp_source[sp_frac div FRACUNIT]];
    sp_dest := @sp_dest[windowWidth];
    sp_frac := sp_frac + sp_fracstep;
    sp_frac := sp_frac and sp_loopvalue;  // JVAL: SOS
    dec(sp_count);
  {$IFDEF VALIDATE}
    except
      inc(numspanexceptions);
      exit;
    end;
  {$ENDIF}
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

  sp_colormap := colormaps;
  if span_p.shadow = 0 then
  begin
    light := (pointz div FRACUNIT) + span_p.light;
    if light > MAXZLIGHT then exit;
    if light < 0 then light := 0;
    sp_colormap := zcolormap[light];
  end
  else if span_p.shadow = 1 then
    sp_colormap := @colormaps[wallglow * 256]
  else if span_p.shadow = 2 then
    sp_colormap := @colormaps[wallflicker1 * 256]
  else if span_p.shadow = 3 then
    sp_colormap := @colormaps[wallflicker2 * 256]
  else if span_p.shadow = 4 then
    sp_colormap := @colormaps[wallflicker3 * 256]
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
    {$IFDEF VALIDATE}
    try
    {$ENDIF}
    dec(sp_count);
    if sp_count = 0 then
      break;
    color := sp_source[sp_frac div FRACUNIT];
    if color <> 0 then
      sp_dest[0] := translookup[sp_colormap[color] - 1][sp_dest[0]];
    sp_dest := @sp_dest[windowWidth];
    sp_frac := sp_frac + sp_fracstep;
    sp_frac := sp_frac and sp_loopvalue;  // JVAL: SOS
    {$IFDEF VALIDATE}
    except
      inc(numspanexceptions);
      exit;
    end;
    {$ENDIF}
  end;
end;


procedure MapRow;
var
  spot: integer;
begin
  while mr_count > 0 do
  begin
    {$IFDEF VALIDATE}
    try
    {$ENDIF}
    spot := (mr_yfrac shr (FRACBITS - 6)) and (63 * 64) + ((mr_xfrac div FRACUNIT) and 63);
    mr_dest[0] := mr_colormap[mr_picture[spot]];
    mr_dest := @mr_dest[1];
    mr_xfrac := mr_xfrac + mr_xstep;
    mr_yfrac := mr_yfrac + mr_ystep;
    dec(mr_count);
    {$IFDEF VALIDATE}
    except
      inc(numspanexceptions);
      exit;
    end;
    {$ENDIF}
  end;
end;

procedure DrawSprite;
var
  leftx, scale, xfrac, fracstep: fixed_t;
  shapebottom, topheight, bottomheight: fixed_t;
  post, x, topy, bottomy, light, shadow, bitshift: integer;
  i64: Int64;
  specialtype: special_t;
  pic: Pscalepic_t;
  collumn: PByteArray;
  sp: Pscaleobj_t;
begin
  (********* floor shadows ***********)
  specialtype := special_t(span_p.shadow div 256);
  shadow := span_p.shadow and 255;

  sp_colormap := colormaps; // st_maxlight
  if specialtype = st_transparent then
    sp_colormap := colormaps
  else if shadow = 0 then
  begin
    light := (pointz div FRACUNIT) + span_p.light;
    if light > MAXZLIGHT then
      exit;
    if light < 0 then
      light := 0;
    sp_colormap := zcolormap[light];
  end
  else if span_p.shadow = 1 then
    sp_colormap := @colormaps[wallglow * 256]
  else if span_p.shadow = 2 then
    sp_colormap := @colormaps[wallflicker1 * 256]
  else if span_p.shadow = 3 then
    sp_colormap := @colormaps[wallflicker2 * 256]
  else if span_p.shadow = 4 then
    sp_colormap := @colormaps[wallflicker3 * 256]
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
  else if shadow = 9 then
  begin
    light := (pointz div FRACUNIT) + span_p.light + wallflicker4;
    if light > MAXZLIGHT then
      light := MAXZLIGHT
    else if light < 0 then
      light := 0;
    sp_colormap := zcolormap[light];
  end;

  pic := Pscalepic_t(span_p.picture);
  if pic = nil then
    exit;  // JVAL: SOS
  sp := Pscaleobj_t(span_p.structure);

  bitshift := FRACBITS - sp.scale;

  shapebottom := span_p.y;
  // project the x and height
  scale := FIXEDDIV(FSCALE, pointz);
  fracstep := _SHL(FIXEDMUL(pointz, ISCALE), sp.scale);
  sp_fracstep := fracstep;
  leftx := span_p.x2;
  leftx := leftx - _SHL(pic.leftoffset, bitshift);
  i64 := FIXEDMUL64(leftx, scale);
  i64 := i64 div FRACUNIT;
  x := CENTERX + i64;
  // step through the shape, drawing posts where visible
  xfrac := 0;
  if x < 0 then
  begin
    xfrac := xfrac - fracstep * x;
    x := 0;
  end;
  sp_loopvalue := 256 * FRACUNIT - 1;

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
    topheight := shapebottom + _SHL(collumn[0], bitshift);
    bottomheight := shapebottom + _SHL(collumn[1], bitshift);
    collumn := @collumn[2];

    // scale a post
    i64 := FIXEDMUL64(bottomheight, scale);
    i64 := i64 div FRACUNIT;
    bottomy := CENTERY - i64;
    if bottomy < scrollmin then
    begin
      inc(x);
      continue;
    end;
    if bottomy >= scrollmax then
      bottomy := scrollmax - 1;

    i64 := FIXEDMUL64(topheight, scale);
    i64 := i64 div FRACUNIT;
    topy := CENTERY - i64;
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

    sp_count := bottomy - topy; // + 1; JVAL: 20211212 - Fix sprite glitch

    sp_dest := @viewylookup[bottomy - scrollmin][x];
    sp_source := collumn;
    if specialtype = st_transparent then
      ScaleTransPost
    else
      ScaleMaskedPost;
    inc(x);
  end;
end;

// Spans farther than MAXZ away should NOT have been entered into the list
procedure DrawSpans;
var
  spantag_p: Ptag_t;
  tag: tag_t;
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
  afrac1: fixed_t;
begin
  // set up backdrop stuff
  w := windowWidth div 2;
  center := viewangle and 255;

  // set up for drawing
  sp_colormap := colormaps;
  starttaglist_p := @spantags[0];
  if numspans > 1 then
  begin
    QuickSortHelper(starttaglist_p, numspans);
    InsertionSort(starttaglist_p, numspans);
    {$IFDEF VALIDATE}
    for x1 := 0 to numspans - 2 do
      if COMPARETAG(@starttaglist_p[x1], @starttaglist_p[x1 + 1]) = 1 then
        MS_Error('DrawSpans(): Sorting failed');
    {$ENDIF}
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
  zeroxfrac := 0; // JVAL: avoid compiler warning
  zeroyfrac := 0; // JVAL: avoid compiler warning
  // draw everything else
  while spantag_p <> endtaglist_p do
  begin
    tag := spantag_p^;
    inc(spantag_p);
    pointz := tag.point;
    spannum := tag.span;
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
          if light > MAXZLIGHT then
            Continue;
          if light < 0 then
            light := 0;
          mr_colormap := zcolormap[light];
        end
        else if span_p.shadow = 9 then
        begin
          light := (pointz div FRACUNIT) + span_p.light + wallflicker4;
          if light > MAXZLIGHT then
            Continue;
          if light < 0 then
            light := 0;
          mr_colormap := zcolormap[light];
        end
        else
          mr_colormap := PByteArray(span_p.shadow);

        y1 := span_p.y - scrollmin;

        if (y1 >= RENDER_VIEW_HEIGHT) or (y1 < 0) then
          Continue;

        mr_dest := @viewylookup[y1][spanx];
        mr_picture := span_p.picture;
        x2 := span_p.x2;

        if (x2 > RENDER_VIEW_WIDTH) or (x2 < 0) then
          Continue;

        mr_count := x2 - spanx;
        MapRow;

        if span_p.spantype = sp_flatsky then
        begin
          py := span_p.y - scrollmin;
          px := spanx;
          mr_count := span_p.x2 - spanx;
          mr_dest := @viewylookup[py][px];
          if windowHeight = 400 then
          begin
            py := span_p.y;
            py := py + 128;
          end
          else if windowHeight = 200 then
          begin
            py := span_p.y;
            py := py + 64;
          end;
          h1 := ibetween((hfrac * py) div FRACUNIT, 0, 255);
          if px <= w then
          begin
            afrac1 := afrac;
            a := ((TANANGLES div 2) * FRACUNIT) + afrac * (w - px);
            while (px <= w) and (mr_count > 0) do
            begin
              x := backtangents[a div FRACUNIT] * 320 div windowWidth;
              x2 := (center - x + 320 - 257);
              x2 := x2 and 255;
              if mr_dest[0] = 255 then
                mr_dest[0] := backdroplookup[h1][x2];
              a := a - afrac;
              inc(px);
              dec(mr_count);
              mr_dest := @mr_dest[1];
            end;
            afrac := afrac1;
          end;
          if px > w then
          begin
            afrac1 := afrac;
            a := ((TANANGLES div 2) * FRACUNIT) + afrac * (px - w);
            while mr_count > 0 do
            begin
              x1 := center + backtangents[a div FRACUNIT] * 320 div windowWidth;
              x1 := x1 and 255;
              if mr_dest[0] = 255 then
                mr_dest[0] := backdroplookup[h1][x1];
              a := a + afrac;
              inc(px);
              dec(mr_count);
              mr_dest := @mr_dest[1];
            end;
            afrac := afrac1;
          end;
        end;

      end;

    sp_sky:
      begin
        py := span_p.y - scrollmin;
        if (py >= RENDER_VIEW_HEIGHT) or (py < 0) then
          Continue;
        px := spanx;

        if (span_p.x2 > RENDER_VIEW_WIDTH) or (span_p.x2 < 0) then
          Continue;

        mr_count := span_p.x2 - spanx;
        mr_dest := @viewylookup[py][px];
        if windowHeight = 400 then
        begin
          py := span_p.y;
          py := py + 128;
        end
        else if windowHeight = 200 then
        begin
          py := span_p.y;
          py := py + 64;
        end;
        h1 := ibetween((hfrac * py) div FRACUNIT, 0, 255);
        if px <= w then
        begin
          afrac1 := afrac;
          a := ((TANANGLES div 2) * FRACUNIT) + afrac * (w - px);
          while (px <= w) and (mr_count > 0) do
          begin
            x := backtangents[a div FRACUNIT] * 320 div windowWidth;
            x2 := (center - x + 320 - 257);
            x2 := x2 and 255;
            mr_dest[0] := backdroplookup[h1][x2];
            a := a - afrac;
            inc(px);
            dec(mr_count);
            mr_dest := @mr_dest[1];
          end;
          afrac := afrac1;
        end;
        if px > w then
        begin
          afrac1 := afrac;
          a := ((TANANGLES div 2) * FRACUNIT) + afrac * (px - w);
          while mr_count > 0 do
          begin
            x1 := center + backtangents[a div FRACUNIT] * 320 div windowWidth;
            x1 := x1 and 255;
            mr_dest[0] := backdroplookup[h1][x1];
            a := a + afrac;
            inc(px);
            dec(mr_count);
            mr_dest := @mr_dest[1];
          end;
          afrac := afrac1;
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
          if light > MAXZLIGHT then
            Continue;
          if light < 0 then
            light := 0;
          mr_colormap := zcolormap[light];
        end
        else if span_p.shadow = 9 then
        begin
          light := (pointz div FRACUNIT) + span_p.light + wallflicker4;
          if light > MAXZLIGHT then
            Continue;
          if light < 0 then
            light := 0;
          mr_colormap := zcolormap[light];
        end
        else
          mr_colormap := PByteArray(span_p.shadow);

        x2 := span_p.x2;
        y1 := span_p.y - scrollmin;

        if (y1 >= RENDER_VIEW_HEIGHT) or (y1 < 0) then
          Continue;
        if (x2 > RENDER_VIEW_WIDTH) or (x2 < 0) then
          Continue;

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
          if windowHeight = 400 then
          begin
            py := span_p.y;
            py := py + 128;
          end
          else if windowHeight = 200 then
          begin
            py := span_p.y;
            py := py + 64;
          end;
          h1 := ibetween((hfrac * py) div FRACUNIT, 0, 255);
          if px <= w then
          begin
            afrac1 := afrac;
            a := ((TANANGLES div 2) * FRACUNIT) + afrac * (w - px);
            while (px <= w) and (mr_count > 0) do
            begin
              x := backtangents[a div FRACUNIT] * 320 div windowWidth;
              x2 := (center - x + 320 - 257);
              x2 := x2 and 255;
              if mr_dest[0] = 255 then
                mr_dest[0] := backdroplookup[h1][x2];
              a := a - afrac;
              inc(px);
              dec(mr_count);
              mr_dest := @mr_dest[1];
            end;
            afrac := afrac1;
          end;
          if px > w then
          begin
            afrac1 := afrac;
            a := ((TANANGLES div 2) * FRACUNIT) + afrac * (px - w);
            while mr_count > 0 do
            begin
              x1 := center + backtangents[a div FRACUNIT] * 320 div windowWidth;
              x1 := x1 and 255;
              if mr_dest[0] = 255 then
                mr_dest[0] := backdroplookup[h1][x1];
              a := a + afrac;
              inc(px);
              dec(mr_count);
              mr_dest := @mr_dest[1];
            end;
            afrac := afrac1;
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
  end;
end;

end.


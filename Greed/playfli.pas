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

unit playfli;

interface

(**** TYPES ****)

// FLI file header
type
  fliheader_t = packed record
    size: integer;
    signature: word;
    nframes: word;
    width: word;
    height: word;
    depth: word;
    flags: word;
    speed: word;
    next: integer;
    frit: integer;
    padding: packed array[0..101] of byte;
  end;
  Pfliheader_t = ^fliheader_t;

// individual frame header
type
  frameheader_t = packed record
    size: integer;
    signature: word;
    nchunks: word;
    padding: packed array[0..7] of byte;
  end;
  Pframeheader_t = ^frameheader_t;

  (* frame chunk type *)
type
  chunktype_t = packed record
    size: integer;
    typ: word;
   end;
   Pchunktype_t = ^chunktype_t;

function CheckTime(const n1, n2: integer): boolean;

function DoPlayFLI(const afname: string; const offset: integer): boolean;

implementation

uses
  SysUtils,
  g_delphi,
  d_ints,
  d_misc,
  d_video,
  intro,
  i_video,
  i_windows,
  r_render;

var
  header: fliheader_t;
  currentfliframe, bufptr: integer;
  chunkbuf: PByteArray;
  flipal: packed array[0..255, 0..2] of byte;

function getbyte: byte;
begin
  result := chunkbuf[bufptr];
  inc(bufptr);
end;

function getshortint: shortint;
begin
  result := PShortIntArray(chunkbuf)[bufptr];
  inc(bufptr);
end;

function getword: word;
begin
  result := chunkbuf[bufptr] + (chunkbuf[bufptr + 1] shl 8);
  inc(bufptr, 2);
end;

// read a color chunk
procedure fli_readcolors;
var
  i, j, total: integer;
  packets: word;
  change, skip: byte;
  k: PByte;
begin
  packets := getword;
  for i := 0 to packets - 1 do
  begin
    skip := getbyte;     // colors to skip
    change := getbyte;   // num colors to change
    if change = 0 then
      total := 256;         // hack for 256
    k := @flipal[skip];
    for j := 0 to total - 1 do
    begin
     k^ := getbyte * 4; inc(k); // r
     k^ := getbyte * 4; inc(k); // g
     k^ := getbyte * 4; inc(k); // b
    end;
  end;
  I_SetPalette(@flipal);
end;

// read beginning runlength compressed frame
procedure fli_brun;
var
  i, j, y, y2, p: integer;
  count: shortint;
  data, packets: byte;
  line: PByte;
begin
  line := @viewbuffer[0];
  y2 := header.height;
  for y := 0 to y2 - 1 do
  begin
    packets := getbyte;
    for p := 0 to packets - 1 do
    begin
      count := getshortint;
      if count < 0 then  // uncompressed
      begin
        j := -count;
        for i := 0 to j - 1 do
        begin
          line^ := getbyte;
          inc(line);
        end;
      end
      else  // compressed
      begin
        data := getbyte;  // byte to repeat
        for i := 0 to count - 1 do
        begin
          line^ := data;
          inc(line);
        end;
      end;
    end;
  end;
end;


// normal line runlength compression type chunk
procedure fli_linecompression;
var
  i, j, p: integer;
  y, y2: word;
  count: shortint;
  data, packets: byte;
  line: PByteArray;
begin
  y := getword; // start y
  y2 := getword;  // number of lines to change
  inc(y2, y);
  while y < y2 do
  begin
    line := @viewylookup[y][0];
    packets := getbyte;
    for p := 0 to packets - 1 do
    begin
      line := @line[getbyte];
      count := getshortint;
      if count < 0 then  // uncompressed
      begin
        data := getbyte;
        j := -count;
        for i := 0 to j - 1 do
        begin
          line[0] := data;
          line := @line[1];
        end
      end// compressed
      else
      begin
        for i := 0 to count - 1 do
        begin
          line[0] := getbyte;
          line := @line[1];
        end;
      end;
    end;
    inc(y);
  end;
end;


// process each frame, chunk by chunk
procedure fli_readframe(var f: file);
var
  chunk: chunktype_t;
  frame: frameheader_t;
  i: integer;
begin
  if not fread(@frame, SizeOf(frame), 1, f) then
    MS_Error('FLI_ReadFrame(): Error Reading Frame!');
  if frame.signature <> $F1FA then
    MS_Error('FLI_ReadFrame(): Wrong Frame Magic!');
  if frame.size = 0 then
    exit;
  for i := 0 to frame.nchunks - 1 do
  begin
    if not fread(@chunk, SizeOf(chunk), 1, f) then
      MS_Error('FLI_ReadFrame(): Error Reading Chunk Header!');
    if not fread(chunkbuf, chunk.size - 6, 1, f) then
      MS_Error('FLI_ReadFrame(): Error with Chunk Read!');
    bufptr := 0;
    case chunk.typ of
    12:  // fli line compression
      fli_linecompression;
    15:  // fli line compression first time (only once at beginning)
      fli_brun;
    16:  // copy chunk
      memcpy(@viewbuffer, chunkbuf, 64000);
    11:  //  new palette
      fli_readcolors;
    13:  //  clear (only 1 usually at beginning)
      memset(@viewbuffer, 0, 64000);
    end;
  end;
end;


// check timer update (70/sec)
// this is for loop optimization in watcom c
function CheckTime(const n1, n2: integer): boolean;
begin
  result := n1 >= n2;
end;

procedure FindFLIFile(var fname: string);
var
  stmp: string;
  test: string;
begin
  stmp := ExtractFileName(fname);
  test := basedefault + stmp;
  if fexists(test) then
  begin
    fname := test;
    exit;
  end;

  test := basedefault + 'MOVIES\' + stmp;
  if fexists(test) then
  begin
    fname := test;
    exit;
  end;

  test := Chr(cdr_drivenum + Ord('A')) + ':\GREED\MOVIES\' + stmp;
  if fexists(test) then
  begin
    fname := test;
    exit;
  end;

  if cdr_drivenum >= 0 then
  begin
    test := Chr(cdr_drivenum + Ord('A')) + ':\GREED2\MOVIES\' + stmp;
    if fexists(test) then
    begin
      fname := test;
      exit;
    end;

    test := Chr(cdr_drivenum + Ord('A')) + ':\GREED3\MOVIES\' + stmp;
    if fexists(test) then
    begin
      fname := test;
      exit;
    end;

    test := Chr(cdr_drivenum + Ord('A')) + ':\MOVIES\' + stmp;
    if fexists(test) then
    begin
      fname := test;
      exit;
    end;
  end;
end;

// play FLI out of BLO file
//  load FLI header
//   set timer
//   read frame
//   copy frame to screen
//      reset timer
//      dump out if keypressed or mousereleased
function DoPlayFLI(const afname: string; const offset: integer): boolean;
var
  f: file;
  delay: integer;
  fname: string;
begin
  fname := afname;
  if not fexists(fname) then
    FindFLIFile(fname);
  if not fexists(fname) then
  begin
    printf('FLI file "%s" not found'#13#10, [afname]);
    result := false;
    exit;
  end;

  newascii := false;
  chunkbuf := malloc(64000);
  if chunkbuf = nil then
    MS_Error('DoPlayFLI(): Out of Memory with ChunkBuf!');
  memset(screen, 0, 64000);
  VI_FillPalette(0, 0, 0);
  if not fopen(f, fname, fOpenReadOnly) then
    MS_Error('DoPlayFLI(): File Not Found: %s', [fname]);
  seek(f, offset);
  if not fread(@header, SizeOf(fliheader_t), 1, f) then
    MS_Error('DoPlayFLI(): File Read Error: %s', [fname]);
  currentfliframe := 0;
  delay := timecount;
  while (currentfliframe < header.nframes) and not newascii do  // newascii := user break
  begin
    delay := delay + header.speed;  // set timer
    fli_readframe(f);
    while not CheckTime(timecount, delay) do
    begin
      Wait(1, 1); // wait;
    end;
    memcpy(screen, @viewbuffer, 64000);       // copy
    inc(currentfliframe);
  end;
  close(f);
  memfree(pointer(chunkbuf));
  if currentfliframe < header.nframes then  // user break
  begin
    memset(screen, 0, 64000);
    result := false;
    exit;
  end;
  result := true;
end;

end.


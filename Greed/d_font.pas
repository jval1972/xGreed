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

unit d_font;

interface

const
  MAXPRINTF = 256;
  MSGTIME = 350;

type
  font_t = packed record
    height: smallint;
    width: packed array[0..255] of byte;
    charofs: packed array[0..255] of smallint;
  end;
  Pfont_t = ^font_t;

const
  MSGQUESIZE = 3;

var
  font: Pfont_t;
  font1, font2, font3: Pfont_t; // JVAL: 20200614 - Moved from raven.pas
  fontbasecolor: integer;
  fontspacing: integer = 1;
  printx, printy: integer;  // the printing position (top left corner)
  timemsg: integer;

procedure FN_RawPrint(const str: string);

procedure FN_RawPrint2(const str: string);

procedure FN_RawPrint3(const str: string);

procedure FN_RawPrint4(const str: string);

function FN_RawWidth(const str: string): integer;

procedure FN_Print(const s: string);

procedure FN_Printf(const fmt: string; const Args: array of const);

procedure FN_PrintCentered(const s: string);

procedure FN_CenterPrintf(const fmt: string; const Args: array of const);

procedure FN_BlockCenterPrintf(const fmt: string; const Args: array of const);

procedure rewritemsg;

procedure writemsg(const s: string);

implementation

uses
  Classes,
  g_delphi,
  d_video,
  d_ints,
  r_render,
  r_public;

// Draws a string of characters to the buffer
procedure FN_RawPrint4(const str: string);
var
  b: byte;
  dest: PByteArray;
  source: PByte;
  width, height, y, oldpx, yh: integer;
  ch: char;
  i: integer;
begin
  oldpx := printx;
  dest := @viewylookup[printy][printx];
  height := font.height;
  for i := 1 to Length(str) do
  begin
    ch := str[i];
    width := font.width[Ord(ch)];
    source := @PByteArray(font)[font.charofs[Ord(ch)]];
    while width > 0 do
    begin
      y := 0;
      yh := 0;
      while y < height do
      begin
        b := source^;
        inc(source);
        if b <> 0 then
          dest[yh] := fontbasecolor + b
        else
          dest[yh] := 0;
        inc(y);
        yh := yh + windowWidth;
      end;
      dest := @dest[1];
      inc(printx);
      dec(width);
    end;
    dest := @dest[fontspacing];
    printx := printx + fontspacing;
  end;
end;

// Draws a string of characters to the buffer
procedure FN_RawPrint2(const str: string);
var
  b: byte;
  dest: PByteArray;
  source: PByte;
  width, height, y, oldpx, yh: integer;
  ch: char;
  i: integer;
begin
  oldpx := printx;
  dest := @viewylookup[printy][printx];
  height := font.height;
  for i := 1 to Length(str) do
  begin
    ch := str[i];
    width := font.width[Ord(ch)];
    source := @PByteArray(font)[font.charofs[Ord(ch)]];
    while width > 0 do
    begin
      y := 0;
      yh := 0;
      while y < height do
      begin
        b := source^;
        inc(source);
        if b <> 0 then
          dest[yh] := fontbasecolor + b;
        inc(y);
        yh := yh + windowWidth;
      end;
      dest := @dest[1];
      inc(printx);
      dec(width);
    end;
    dest := @dest[fontspacing];
    printx := printx + fontspacing;
  end;
end;


// Draws a string of characters to the screen
procedure FN_RawPrint(const str: string);
var
  b: byte;
  dest: PByteArray;
  source: PByte;
  width, height, y, oldpx, yh: integer;
  ch: char;
  i: integer;
begin
  oldpx := printx;
  dest := @ylookup[printy][printx];
  height := font.height;
  for i := 1 to Length(str) do
  begin
    ch := str[i];
    width := font.width[Ord(ch)];
    source := @PByteArray(font)[font.charofs[Ord(ch)]];
    while width > 0 do
    begin
      y := 0;
      yh := 0;
      while y < height do
      begin
        b := source^;
        inc(source);
        if b <> 0 then
          dest[yh] := fontbasecolor + b
        else
          dest[yh] := 0;
        inc(y);
        yh := yh + 320;
      end;
      dest := @dest[1];
      inc(printx);
      dec(width);
    end;
    dest := @dest[fontspacing];
    printx := printx + fontspacing;
  end;
end;


// Draws a string of characters to the screen
procedure FN_RawPrint3(const str: string);
var
  b: byte;
  dest: PByteArray;
  source: PByte;
  width, height, y, oldpx, yh: integer;
  ch: char;
  i: integer;
begin
  oldpx := printx;
  dest := @ylookup[printy][printx];
  height := font.height;
  for i := 1 to Length(str) do
  begin
    ch := str[i];
    width := font.width[Ord(ch)];
    source := @PByteArray(font)[font.charofs[Ord(ch)]];
    while width > 0 do
    begin
      y := 0;
      yh := 0;
      while y < height do
      begin
        b := source^;
        inc(source);
        if b <> 0 then
          dest[yh] := fontbasecolor + b;
        inc(y);
        yh := yh + 320;
      end;
      dest := @dest[1];
      inc(printx);
      dec(width);
    end;
    dest := @dest[fontspacing];
    printx := printx + fontspacing;
  end;
end;


// Returns the width of a string
// Does NOT handle newlines
function FN_RawWidth(const str: string): integer;
var
  i: integer;
begin
  result := 0;
  for i := 1 to Length(str) do
  begin
    result := result + font.width[Ord(str[i])];
    result := result + fontspacing;
  end;
end;


// Prints a string in the current window, with newlines
// going down a line and back to 0
procedure FN_Print(const s: string);
var
  sl: TStringList;
  i: integer;
  stmp: string;
  h: integer;
begin
  h := font.height;

  sl := TStringList.Create;
  sl.Text := s;

  for i := 0 to sl.Count - 1 do
  begin
    stmp := sl.Strings[i];
    if stmp <> '' then
      FN_RawPrint(stmp);
    printx := 0;
    printy := printy + h;
  end;
end;

// Prints a multi line string with each line centered
procedure FN_PrintCentered(const s: string);
var
  sl: TStringList;
  i: integer;
  stmp: string;
  w, h: integer;
begin
  h := font.height;

  sl := TStringList.Create;
  sl.Text := s;

  for i := 0 to sl.Count - 1 do
  begin
    stmp := sl.Strings[i];
    if stmp <> '' then
    begin
      w := FN_RawWidth(stmp);
      printx := (320 - w) div 2;
      FN_RawPrint3(stmp);
    end;
    printx := 0;
    printy := printy + h;
  end;
end;

// Prints a printf style formatted string at the current print position
// using the current print routines
procedure FN_Printf(const fmt: string; const Args: array of const);
var
  stmp: string;
begin
  sprintf(stmp, fmt, Args);
  FN_Print(stmp);
end;


// As FN_Printf, but centers each line of text in the window bounds
procedure FN_CenterPrintf(const fmt: string; const Args: array of const);
var
  stmp: string;
begin
  sprintf(stmp, fmt, Args);
  FN_PrintCentered(stmp);
end;


// As FN_CenterPrintf, but also enters the entire set of lines vertically in
// the window bounds
procedure FN_BlockCenterPrintf(const fmt: string; const Args: array of const);
var
  stmp: string;
  i, height: integer;
begin
  sprintf(stmp, fmt, Args);
  height := font.height;
  for i := 1 to Length(stmp) do
    if stmp[i] = #10 then
      inc(height, font.height);
  printy := (200 - height) div 2;
  FN_PrintCentered(stmp);
end;

var
  msgstr: array[0..MSGQUESIZE - 1] of string[255];

// write the current msg to the view buffer
procedure rewritemsg;
var
  i: integer;
begin
  fontbasecolor := 73;
  font := font1;
  for i := 0 to MSGQUESIZE - 1 do
    if msgstr[i] <> '' then
    begin
      printx := 2;
      printy := 1 + i * 6;
      FN_RawPrint2(msgstr[i]);
    end;
  if timecount > timemsg then
  begin
    for i := 1 to MSGQUESIZE - 1 do
      msgstr[i - 1] := msgstr[i];
    msgstr[MSGQUESIZE - 1] := '';
    timemsg := timecount + MSGTIME;
  end;
end;

// update current msg
procedure writemsg(const s: string);
var
  i: integer;
begin
  if msgstr[MSGQUESIZE - 1] <> '' then
    for i := 1 to MSGQUESIZE - 1 do
      msgstr[i - 1] := msgstr[i];
  msgstr[MSGQUESIZE - 1] := s;
  timemsg := timecount + MSGTIME; // 10 secs
  printf(s);
end;

end.

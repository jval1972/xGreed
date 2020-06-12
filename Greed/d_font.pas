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

#include <STDARG.H>
#include <STDIO.H>
#include <STRING.H>
#include 'd_global.h'
#include 'd_video.h'
#include 'd_misc.h'
#include 'd_font.h'
#include 'd_ints.h'
#include 'r_public.h'
#include 'protos.h'


(**** VARIABLES ****)

#define MSGQUESIZE 3

font_t  *font;
  fontbasecolor: integer;
  fontspacing := 1: integer;
char    str[MAXPRINTF];  // general purpose string buffer
char    msgstr[MSGQUESIZE][MAXPRINTF];
int     printx, printy;  // the printing position (top left corner)
  msgtime: integer;


(**** FUNCTIONS ****)

procedure FN_RawPrint4(char *str);
(* Draws a string of characters to the buffer *)
begin
  byte b;
  byte *dest, *source;
  width, height, y, oldpx, yh: integer;
  char ch;

  oldpx := printx;
  dest := viewylookup[printy]+printx;
  height := font.height;
  while ((ch := *str++) <> 0) do
  begin
   width := font.width[ch];
   source := ((byte*)font) + font.charofs[ch];
   while width-- do
   begin
     for (y := 0,yh := 0;y<height;y++,yh+:= windowWidth)
     begin
       b := *source++;
       if (b) dest[yh] := fontbasecolor+b;
       else dest[yh] := 0;
        end;
     dest++;
     printx++;
      end;
   dest := dest + fontspacing;
   printx := printx + fontspacing;
    end;
  end;


procedure FN_RawPrint2(char *str);
(* Draws a string of characters to the buffer *)
begin
  byte b;
  byte *dest, *source;
  width, height, y, oldpx, yh: integer;
  char ch;

  oldpx := printx;
  dest := viewylookup[printy]+printx;
  height := font.height;
  while ((ch := *str++) <> 0) do
  begin
   width := font.width[ch];
   source := ((byte*)font) + font.charofs[ch];
   while width-- do
   begin
     for (y := 0,yh := 0;y<height;y++,yh+:= windowWidth)
     begin
       b := *source++;
       if (b) dest[yh] := fontbasecolor+b;
        end;
     dest++;
     printx++;
      end;
   dest := dest + fontspacing;
   printx := printx + fontspacing;
    end;
  end;


procedure FN_RawPrint(char *str);
(* Draws a string of characters to the screen *)
begin
  byte b;
  byte *dest, *source;
  width, height, y, oldpx, yh: integer;
  char ch;

  oldpx := printx;
  dest := ylookup[printy]+printx;
  height := font.height;
  while ((ch := *str++) <> 0) do
  begin
   width := font.width[ch];
   source := ((byte *)font) + font.charofs[ch];
   while width-- do
   begin
     for (y := 0,yh := 0;y<height;y++,yh+:= 320)
     begin
       b := *source++;
       if (b) dest[yh] := fontbasecolor+b;
       else dest[yh] := 0;
        end;
     dest++;
     printx++;
      end;
   dest := dest + fontspacing;
   printx := printx + fontspacing;
    end;
  end;


procedure FN_RawPrint3(char *str);
(* Draws a string of characters to the screen *)
begin
  byte b;
  byte *dest, *source;
  width, height, y, oldpx, yh: integer;
  char ch;

  oldpx := printx;
  dest := ylookup[printy]+printx;
  height := font.height;
  while ((ch := *str++) <> 0) do
  begin
   width := font.width[ch];
   source := ((byte *)font) + font.charofs[ch];
   while width-- do
   begin
     for (y := 0,yh := 0;y<height;y++,yh+:= 320)
     begin
       b := *source++;
       if (b) dest[yh] := fontbasecolor+b;
        end;
     dest++;
     printx++;
      end;
   dest := dest + fontspacing;
   printx := printx + fontspacing;
    end;
  end;


int FN_RawWidth(char *str)
(* Returns the width of a string
   Does NOT handle newlines     *)
   begin
  width: integer;

  width := 0;
  while *str do
  begin
   width+:= font.width[*str++];
   width := width + fontspacing;
    end;
  return width;
  end;


procedure FN_Print(char  *s);
(* Prints a string in the current window, with newlines
   going down a line and back to 0 *)
   begin
  char     c, *se;
  unsigned h;

  h := font.height;
  while *s do
  begin
   se := s;
   c := *se;
   while (c) and (c <> '\n') c := *++se;
   *se := '\0';
   FN_RawPrint(s);
   s := se;
   if c then
   begin
     *se := c;
     s++;
     printx := 0;
     printy := printy + h;
      end;
    end;
  end;


procedure FN_PrintCentered(char  *s);
(* Prints a multi line string with each line centered *)
begin
  char     c, *se;
  unsigned w, h;

  h := font.height;
  while *s do
  begin
   se := s;
   c := *se;
   while (c) and (c <> '\n') c := *++se;
   *se := '\0';
   w := FN_RawWidth(s);
   printx := (320-w)/2;
   FN_RawPrint3(s);
   s := se;
   if c then
   begin
     *se := c;
     s++;
     printx := 0;
     printy := printy + h;
      end;
    end;
  end;


procedure FN_Printf(char *fmt, ...);
(* Prints a printf style formatted string at the current print position
    using the current print routines  *)
    begin
  va_list argptr;
  cnt: integer;

  va_start(argptr,fmt);
  cnt := vsprintf(str,fmt,argptr);
  va_end(argptr);
{$IFDEF PARMCHECK}
  if (cnt >= MAXPRINTF) MS_Error('FN_Printf: String too long: %s',fmt);
{$ENDIF}
  FN_Print(str);
  end;


procedure FN_CenterPrintf(char *fmt, ...);
(* As FN_Printf, but centers each line of text in the window bounds *)
begin
  va_list argptr;
  cnt: integer;

  va_start(argptr,fmt);
  cnt := vsprintf(str,fmt,argptr);
  va_end(argptr);
{$IFDEF PARMCHECK}
  if (cnt >= MAXPRINTF) MS_Error('FN_CPrintf: String too long: %s',fmt);
{$ENDIF}
  FN_PrintCentered(str);
  end;


procedure FN_BlockCenterPrintf(char *fmt, ...);
(* As FN_CenterPrintf, but also enters the entire set of lines vertically in
   the window bounds *)
   begin
  va_list argptr;
  cnt: integer;
  char    *s;
  height: integer;

  va_start(argptr,fmt);
  cnt := vsprintf(str,fmt,argptr);
  va_end(argptr);
{$IFDEF PARMCHECK}
  if (cnt >= MAXPRINTF) MS_Error('FN_CCPrintf: String too long: %s',fmt);
{$ENDIF}
  height := 1;
  s := str;
  while (*s) if (*s++ = '\n') height++;
  height := height * font.height;
  printy := 0+(200-height)/2;
  FN_PrintCentered(str);
  end;


procedure rewritemsg;
(* write the current msg to the view buffer *)
begin
  i: integer;

  fontbasecolor := 73;
  font := font1;
  for(i := 0;i<MSGQUESIZE;i++)
  if msgstr[i][0] then
  begin
    printx := 2;
    printy := 1+i*6;
    FN_RawPrint2(msgstr[i]);
     end;
  if timecount>msgtime then
  begin
   for(i := 1;i<MSGQUESIZE;i++)
    strcpy(msgstr[i-1],msgstr[i]);
   msgstr[MSGQUESIZE-1][0] := 0;
   msgtime := timecount+MSGTIME;
    end;
  end;


procedure writemsg(char *s);
(* update current msg *)
begin
  i: integer;

  if msgstr[MSGQUESIZE-1][0] <> 0 then
  for(i := 1;i<MSGQUESIZE;i++)
   strcpy(msgstr[i-1],msgstr[i]);
  strcpy(msgstr[MSGQUESIZE-1],s);
  msgtime := timecount+MSGTIME; // 10 secs
  end;


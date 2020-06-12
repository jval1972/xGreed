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

#include <DOS.H>
#include <STDIO.H>
#include <STRING.H>
#include <STDLIB.H>
#include 'd_global.h'
#include 'd_video.h'
#include 'r_public.h'
#include 'd_misc.h'
#include 'd_ints.h'

#define getbyte chunkbuf[bufptr++]
#define getword chunkbuf[bufptr] + (chunkbuf[bufptr+1] shl 8); bufptr+:= 2

(**** TYPES ****)

typedef signed char shortint;

  (* FLI file header *)
#pragma pack(push,packing,1)
typedef struct
begin
  size: integer;
  word    signature;
  word    nframes;
  word    width;
  word    height;
  word    depth;
  word    flags;
  word    speed;
  next: integer;
  frit: integer;
  byte    padding[102];
   end; fliheader;

  (* individual frame header *)
typedef struct
begin
  size: integer;
  word    signature;
  word    nchunks;
  byte    padding[8];
   end; frameheader;

  (* frame chunk type *)
typedef struct
begin
  size: integer;
  word    type;
   end; chunktype;


(**** VARIABLES ****)

#pragma pack(pop,packing)

static fliheader header;
static int       currentfliframe, bufptr;
static byte      *chunkbuf;
static byte      flipal[256][3];


(**** FUNCTIONS ****)

procedure fli_readcolors;
(* read a color chunk *)
begin
  i, j, total: integer;
  word    packets;
  byte    change, skip;
  byte    *k;

  packets := getword;
  for (i := 0;i<packets;i++)
  begin
   skip := getbyte;     // colors to skip
   change := getbyte;   // num colors to change
   if change = 0 then
    total := 256;         // hack for 256
   k := flipal[skip];
   for (j := 0;j<total;j++)
   begin
     *k++:= getbyte;   // r
     *k++:= getbyte;   // g
     *k++:= getbyte;   // b
      end;
    end;
  VI_SetPalette((char*)flipal);
  end;


procedure fli_brun;
(* read beginning runlength compressed frame *)
begin
  i, j, y, y2, p: integer;
  shortint count;
  byte     data, packets;
  byte     *line;

  line := (byte *)viewbuffer;
  for (y := 0,y2 := header.height;y<y2;y++)
  begin
   packets := getbyte;
   for (p := 0;p<packets;p++)
   begin
     count := getbyte;
     if (count<0)               // uncompressed
      for (i := 0,j := -count;i<j;i++,line++) 
       *line := getbyte;
     else                       // compressed
     begin
       data := getbyte;          // byte to repeat
       for (i := 0;i<count;i++)
  *line++:= data;
        end;
      end;
    end;
  end;


procedure fli_linecompression;
(* normal line runlength compression type chunk *)
begin
  i, j, p: integer;
  word     y, y2;
  shortint count;
  byte     data, packets;
  byte     *line;

  y := getword;                // start y
  y2 := getword;               // number of lines to change
  for (y2+:= y;y<y2;y++)
  begin
   line := viewylookup[y];
   packets := getbyte;
   for (p := 0;p<packets;p++)
   begin
     line := line + getbyte;
     count := getbyte;
     if (count<0)            // uncompressed
     begin
       data := getbyte;
       for (i := 0,j := -count;i<j;i++,line++)
  *line := data;
        end;                     // compressed
     else for (i := 0;i<count;i++,line++)
      *line := getbyte;
      end;
    end;
  end;


procedure fli_readframe(FILE *f);
(* process each frame, chunk by chunk *)
begin
  chunktype   chunk;
  frameheader frame;
  i: integer;

  if (not fread and (frame,sizeof(frame),1,f)) or (frame.signature <> $F1FA) then
  MS_Error('FLI_ReadFrame: Error Reading Frame not ');
  if frame.size = 0 then
  exit;
  for(i := 0;i<frame.nchunks;i++)
  begin
   if (not fread and (chunk,sizeof(chunk),1,f)) then
    MS_Error('FLI_ReadFram: Error Reading Chunk Header not ');
   if (not fread(chunkbuf,chunk.size-6,1,f)) then
    MS_Error('FLI_ReadFram: Error with Chunk Read not ');
   bufptr := 0;
   case chunk.type  of
   begin
     12:  // fli line compression
      fli_linecompression;
      break;
     15:  // fli line compression first time (only once at beginning)
      fli_brun;
      break;
     16:  // copy chunk
      memcpy(viewbuffer,chunkbuf,64000);
      break;
     11:  //  new palette
      fli_readcolors;
      break;
     13:  //  clear (only 1 usually at beginning)
      memset(viewbuffer,0,64000);
      break;
      end;
    end;
  end;


bool CheckTime(int n1, int n2)
(* check timer update (70/sec) 
    this is for loop optimization in watcom c *)
    begin
  if n1<n2 then
  return false;
  return true;
  end;


bool playfli(char *fname,longint offset)
(* play FLI out of BLO file
    load FLI header
     set timer
     read frame
     copy frame to screen
     reset timer
     dump out if keypressed or mousereleased *)
     begin
  FILE    *f;
  delay: integer;

  newascii := false;
  chunkbuf := (byte *)malloc(64000);
  if chunkbuf = NULL then
  MS_Error('PlayFLI: Out of Memory with ChunkBuf not ');
  memset(screen,0,64000);
  VI_FillPalette(0,0,0);
  f := fopen(fname,'rb');
  if f = NULL then
  MS_Error('PlayFLI: File Not Found: %s',fname);
  if (fseek(f,offset,0)) or ( not fread and (header,sizeof(fliheader),1,f)) then
  MS_Error('PlayFLI: File Read Error: %s',fname);
  currentfliframe := 0;
  delay := timecount;
  while (currentfliframe++<header.nframes) and ( not newascii) // newascii := user break
  begin
   delay+:= header.speed;                   // set timer
   fli_readframe(f);
   while (not CheckTime(timecount,delay)) ;  // wait
   memcpy(screen,viewbuffer,64000);       // copy
    end;
  fclose(f);
  free(chunkbuf);
  if (currentfliframe<header.nframes) // user break
  begin
   memset(screen,0,64000);
   return false;
    end;
  else return true;
  end;

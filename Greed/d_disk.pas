(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020-2021 by Jim Valavanis                                *)
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

unit d_disk;

interface

uses
  SysUtils,
  g_delphi;

type
  Pfileinfo_t = ^fileinfo_t;
  fileinfo_t = packed record
    numlumps: smallint;
    infotableofs: integer;
    infotablesize: integer;
  end;

  Plumpinfo_t = ^lumpinfo_t;
  lumpinfo_t = packed record
    filepos: integer;
    size: LongWord;
    nameofs: smallint;
    compress: smallint;
  end;
  lumpinfo_tArray = array[0..$FFF] of lumpinfo_t;
  Plumpinfo_tArray = ^lumpinfo_tArray;

  Plumpcache_t = ^lumpcache_t;
  lumpcache_t = record
    data: Pointer;
    usage: Boolean;
  end;
  lumpcache_tArray = array[0..$FFF] of lumpcache_t;
  Plumpcache_tArray = ^lumpcache_tArray;

(**** VARIABLES ****)
var
  fileinfo: fileinfo_t; // the file header
  infotable: Plumpinfo_tArray;  // pointers into the cache file
  lumpcache: Plumpcache_tArray;  // pointers to the lumps in main memory
  cachehandle: file; // handle of current file

procedure CA_ReadFile(const fname: string; const buffer: pointer; const len: LongWord);

function CA_LoadFile(const fname: string): pointer;

procedure CA_InitFile(const afilename: string);

procedure CA_ShutDown;

function CA_CheckNamedNum(const name: string): integer;

function CA_GetNamedNum(const name: string): integer;

function CA_CacheLump(const lump: integer): pointer;

function CA_CachePalette(const lump: integer): pointer;

procedure CA_ReadLump(const lump: integer; const dest: pointer);

procedure CA_FreeLump(const lump: integer);

function CA_LumpName(const lump: integer): string;

function CA_LumpLen(const lump: integer): integer;

function CA_LumpAsText(const lump: integer): string;

function CA_FileAsText(const fname: string): string;

implementation

uses
  i_windows,
  d_misc,
  g_fixlump,
  menu;

procedure CA_ReadFile(const fname: string; const buffer: pointer; const len: LongWord);
var
  handle: file;
begin
  if not fopen(handle, fname, fOpenReadOnly) then
    MS_Error('CA_ReadFile(): Open failed on %s!', [fname]);
  if not fread(buffer, len, 1, handle) then
  begin
    closefile(handle);
    MS_Error('CA_LoadFile(): Read failed on %s!', [fname]);
  end;
  closefile(handle);
end;

function CA_LoadFile(const fname: string): pointer;
var
  handle: file;
  len: integer;
  buffer: pointer;
begin
  if not fopen(handle, fname, fOpenReadOnly) then
    MS_Error('CA_LoadFile(): Open failed on %s!', [fname]);
  len := ftell(handle);
  buffer := malloc(len);
  if buffer = nil then
    MS_Error('CA_LoadFile(): Malloc failed for %s!', [fname]);
  if not fread(buffer, len, 1, handle) then
  begin
    closefile(handle);
    MS_Error('CA_LoadFile(): Read failed on %s!', [fname]);
  end;
  closefile(handle);
  result := buffer;
end;

// initialize link file
var
  ca_initialized: boolean = false;

procedure FindBLOFile(var fname: string);
var
  stmp: string;
  test: string;
  p: integer;
begin
  p := MS_CheckParm('blo');
  if (p > 0) and (p < my_argc) then
    maindatafile := my_argv(p + 1);

  if maindatafile <> '' then
    if fexists(maindatafile) then
    begin
      fname := maindatafile;
      maindatapath := fpath(maindatafile);
      exit;
    end;

  stmp := ExtractFileName(fname);
  test := basedefault + stmp;
  if fexists(test) then
  begin
    fname := test;
    maindatafile := fname;
    maindatapath := fpath(maindatafile);
    exit;
  end;

  test := fpath(maindatafile) + stmp;
  if fexists(test) then
  begin
    fname := test;
    maindatafile := fname;
    maindatapath := fpath(maindatafile);
    exit;
  end;

  test := Chr(cdr_drivenum + Ord('A')) + ':\GREED\' + stmp;
  if fexists(test) then
  begin
    fname := test;
    maindatafile := fname;
    maindatapath := fpath(maindatafile);
    exit;
  end;

  test := Chr(cdr_drivenum + Ord('A')) + ':\GREED2\' + stmp;
  if fexists(test) then
  begin
    fname := test;
    maindatafile := fname;
    maindatapath := fpath(maindatafile);
    exit;
  end;

  test := Chr(cdr_drivenum + Ord('A')) + ':\GREED3\' + stmp;
  if fexists(test) then
  begin
    fname := test;
    maindatafile := fname;
    maindatapath := fpath(maindatafile);
    exit;
  end;
end;

procedure CA_ShutDown;
var
  i: integer;
begin
  if ca_initialized then // already open, must shut down
  begin
    closefile(cachehandle);
    memfree(pointer(infotable));
    for i := 0 to fileinfo.numlumps - 1 do  // dump the lumps
      if lumpcache[i].data <> nil then
        memfree(lumpcache[i].data);
    memfree(pointer(lumpcache));
  end;
end;

procedure CA_InitFile(const afilename: string);
var
  size: integer;
  filename: string;
begin
  CA_ShutDown;
  filename := afilename;
  FindBLOFile(filename);
  // load the header
  if not fopen(cachehandle, filename, fOpenReadOnly) then
    MS_Error('CA_InitFile(): Can''t open %s!', [filename]);
  fread(@fileinfo, SizeOf(fileinfo), 1, cachehandle);
  // load the info list
  size := fileinfo.infotablesize;
  infotable := malloc(size);
  seek(cachehandle, fileinfo.infotableofs);
  fread(infotable, size, 1, cachehandle);
  size := fileinfo.numlumps * SizeOf(lumpcache_t);
  lumpcache := mallocz(size);
  ca_initialized := true;
end;

// returns number of lump if found
// returns -1 if name not found
function CA_CheckNamedNum(const name: string): integer;
var
  i, ofs: integer;
begin
  for i := 0 to fileinfo.numlumps - 1 do
  begin
    ofs := infotable[i].nameofs;
    if ofs = 0 then
      continue;
    if stricmp(pOp(infotable, ofs), name) = 0 then
    begin
      result := i;
      exit;
    end;
  end;
  result := -1;
end;


// searches for lump with name
// returns -1 if not found
function CA_GetNamedNum(const name: string): integer;
begin
  result := CA_CheckNamedNum(name);
  if result >= 0 then
    exit;
  MS_Error('CA_GetNamedNum(): %s not found!', [name]);
end;


// returns pointer to lump
// caches lump in memory
function CA_CacheLump(const lump: integer): pointer;
begin
{$IFDEF PARMCHECK}
  if lump >= fileinfo.numlumps then
    MS_Error('CA_LumpPointer(): %i>%i max lumps!', [lump, fileinfo.numlumps]);
{$ENDIF}
  if lumpcache[lump].data = nil then
  begin
    // load the lump off disk
    lumpcache[lump].data := malloc(infotable[lump].size);
    if lumpcache[lump].data = nil then
      MS_Error('CA_LumpPointer(): malloc failure of lump %d, with size %d',
        [lump, infotable[lump].size]);
    seek(cachehandle, infotable[lump].filepos);
    if waiting then
      UpdateWait;
    fread(lumpcache[lump].data, infotable[lump].size, 1, cachehandle);
    FixLump(lumpcache[lump].data, infotable[lump].size);
    if waiting then
      UpdateWait;
  end;
  lumpcache[lump].usage := True;
  result := lumpcache[lump].data;
end;

var
  DISKPAL: packed array[0..767] of byte;

function CA_CachePalette(const lump: integer): pointer;
var
  p: PByteArray;
  i: integer;
begin
  p := CA_CacheLump(lump);
  for i := 0 to 767 do
    DISKPAL[i] := p[i] * 4;
  result := @DISKPAL;
end;

procedure CA_ReadLump(const lump: integer; const dest: pointer);
(* reads a lump into a buffer *)
begin
{$IFDEF PARMCHECK}
  if lump >= fileinfo.numlumps then
    MS_Error('CA_ReadLump(): %d>%d max lumps!', [lump, fileinfo.numlumps]);
{$ENDIF}
  seek(cachehandle, infotable[lump].filepos);
  fread(dest, infotable[lump].size, 1, cachehandle);
end;


// frees a cached lump
procedure CA_FreeLump(const lump: integer);
begin
{$IFDEF PARMCHECK}
  if lump >= fileinfo.numlumps then
    MS_Error('CA_FreeLump(): %d>%d max lumps!', [lump, fileinfo.numlumps]);
{$ENDIF}
  lumpcache[lump].usage := False;
//  if lumpcache[lump].data = nil then
//    exit;
//  memfree(lumpmain[lump]);
end;

function CA_LumpName(const lump: integer): string;
var
  c: PChar;
  ofs: integer;
begin
  result := '';
  ofs := infotable[lump].nameofs;
  if ofs >= 0 then
  begin
    c := @infotable[ofs];
    while c^ <> #0 do
      result := result + c^;
  end;
end;

function CA_LumpLen(const lump: integer): integer;
begin
  result := infotable[lump].size;
end;

function CA_LumpAsText(const lump: integer): string;
var
  len: integer;
begin
  len := infotable[lump].size;
  SetLength(result, len);
  seek(cachehandle, infotable[lump].filepos);
  fread(@result[1], len, 1, cachehandle);
end;

function CA_FileAsText(const fname: string): string;
var
  f: file;
  len: integer;
begin
  if not fopen(f, fname, fOpenReadOnly) then
  begin
    result := '';
    exit;
  end;
  len := ftell(f);
  SetLength(result, len);
  fread(@result[1], len, 1, f);
  fclose(f);
end;

end.


(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020 by Jim Valavanis                                     *)
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

unit d_disk;

interface

uses
  g_delphi,
  d_disk_h,
  protos_h;

(**** VARIABLES ****)
var
  fileinfo: fileinfo_t; // the file header
  infotable: Plumpinfo_tArray;  // pointers into the cache file
  lumpmain: PPointerArray;  // pointers to the lumps in main memory
  cachehandle: file; // handle of current file

procedure CA_ReadFile(const fname: string; const buffer: pointer; const len: LongWord);

function CA_LoadFile(const fname: string): pointer;

procedure CA_InitFile(const filename: string);

function CA_CheckNamedNum(const name: string): integer;

function CA_GetNamedNum(const name: string): integer;

function CA_CacheLump(const lump: integer): pointer;

procedure CA_ReadLump(const lump: integer; const dest: pointer);

procedure CA_FreeLump(const lump: integer);

implementation

uses
  d_misc,
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

procedure CA_InitFile(const filename: string);
var
  size: integer;
  i: integer;
begin
  if ca_initialized then // already open, must shut down
  begin
    closefile(cachehandle);
    memfree(pointer(infotable));
    for i := 0 to fileinfo.numlumps - 1 do  // dump the lumps
      if lumpmain[i] <> nil then
        memfree(lumpmain[i]);
    memfree(pointer(lumpmain));
  end;
  // load the header
  if not fopen(cachehandle, filename, fOpenReadOnly) then
    MS_Error('CA_InitFile(): Can''t open %s!', [filename]);
  fread(@fileinfo, SizeOf(fileinfo), 1, cachehandle);
  // load the info list
  size := fileinfo.infotablesize;
  infotable := malloc(size);
  seek(cachehandle, fileinfo.infotableofs);
  fread(infotable, size, 1, cachehandle);
  size := fileinfo.numlumps * SizeOf(integer);
  lumpmain := mallocz(size);
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
var
  i: integer;
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
  if lumpmain[lump] = nil then
  begin
    // load the lump off disk
    lumpmain[lump] := malloc(infotable[lump].size);
    if lumpmain[lump] = nil then
      MS_Error('CA_LumpPointer(): malloc failure of lump %d, with size %d',
        [lump, infotable[lump].size]);
   seek(cachehandle, infotable[lump].filepos);
   if (waiting) UpdateWait;
   read(cachehandle,lumpmain[lump],infotable[lump].size);
   if (waiting) UpdateWait;
    end;
  return lumpmain[lump];
  end;


procedure CA_ReadLump(const lump: integer; const dest: pointer);
(* reads a lump into a buffer *)
begin
{$IFDEF PARMCHECK}
  if (lump >= fileinfo.numlumps) MS_Error('CA_ReadLump: %i>%i max lumps!',lump,fileinfo.numlumps);
{$ENDIF}
  lseek(cachehandle, infotable[lump].filepos, SEEK_SET);
  read(cachehandle,dest,infotable[lump].size);
  end;


procedure CA_FreeLump(const lump: integer);
(* frees a cached lump *)
begin
{$IFDEF PARMCHECK}
  if (lump >= fileinfo.numlumps) MS_Error('CA_FreeLump: %i>%i max lumps!',lump,fileinfo.numlumps);
{$ENDIF}
  if (not lumpmain[lump]) exit;
  free(lumpmain[lump]);
  lumpmain[lump] := NULL;
  end;


end.


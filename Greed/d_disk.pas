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
  d_misc;
  
procedure CA_ReadFile(const fname: string; const buffer: pointer; const len: LongWord);
var
  handle: file;
begin
  if not fopen(handle, fname, fOpenReadOnly) then
    MS_Error('CA_ReadFile(): Open failed on %s!', [name]);
  if not fread(handle, buffer, len) then
  begin
    closefile(handle);
    MS_Error('CA_LoadFile(): Read failed on %s!', name);
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
    MS_Error('CA_LoadFile(): Open failed on %s!', [name]);
  len := fsize(handle);
  buffer := malloc(len)
  if buffer = nil then
    MS_Error('CA_LoadFile(): Malloc failed for %s!', [name]);
  if not fread(buffer, len, 1, handle) then
  begin
    closefile(handle);
    MS_Error('CA_LoadFile(): Read failed on %s!', [name]);
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
    memfree(infotable);
    for i := 0 to fileinfo.numlumps - 1 do  // dump the lumps
      if lumpmain[i] <> nil then
        memfree(lumpmain[i]);
    memfree(lumpmain);
  end;
  // load the header
  if not fopen(cachehandle, filename, fOpenReadOnly then
    MS_Error('CA_InitFile: Can't open %s not ',filename);
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

function CA_CheckNamedNum(const name: string): integer;
(* returns number of lump if found
   returns -1 if name not found *)
   begin
  i, ofs: integer;

  for(i := 0;i<fileinfo.numlumps;i++)
  begin
   ofs := infotable[i].nameofs;
   if (not ofs) continue;
   if (stricmp(name,((char *)infotable)+ofs) = 0) return i;
    end;
  return -1;
  end;


function CA_GetNamedNum(const name: string): integer;
(* searches for lump with name
   returns -1 if not found *)
   begin
  i: integer;

  i := CA_CheckNamedNum(name);
  if (i <> -1) return i;
  MS_Error('CA_GetNamedNum: %s not found!',name);
  return -1;
  end;


function CA_CacheLump(const lump: integer): pointer;
(* returns pointer to lump
   caches lump in memory *)
   begin
{$IFDEF PARMCHECK}
  if (lump >= fileinfo.numlumps) MS_Error('CA_LumpPointer: %i>%i max lumps!',lump,fileinfo.numlumps);
{$ENDIF}
  if not lumpmain[lump] then
  begin
   // load the lump off disk
   if (not (lumpmain[lump] := malloc(infotable[lump].size))) then
    MS_Error('CA_LumpPointer: malloc failure of lump %d, with size %d',
        lump,infotable[lump].size);
   lseek(cachehandle,infotable[lump].filepos,SEEK_SET);
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


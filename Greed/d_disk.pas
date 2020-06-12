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
  d_disk_h,
  d_misc_h,
  protos_h;

(**** VARIABLES ****)

fileinfo_t fileinfo;     // the file header
lumpinfo_t *infotable;   // pointers into the cache file
void       **lumpmain;   // pointers to the lumps in main memory
int        cachehandle;  // handle of current file

extern bool waiting;

(**** FUNCTIONS ****)

procedure CA_ReadFile(char *name, void *buffer, unsigned length);
(* generic read file *)
begin
  handle: integer;

  if ((handle := open(name,O_RDONLY) or (O_BINARY)) = -1) MS_Error('CA_ReadFile: Open failed on %s not ',name);
  if (not read(handle,buffer,length)) then
  begin
   close(handle);
   MS_Error('CA_LoadFile: Read failed on %s not ',name);
    end;
  close(handle);
  end;


procedure *CA_LoadFile(char *name);
(* generic load file *)
begin
  handle: integer;
  unsigned length;
procedure *buffer;

  if ((handle := open(name,O_RDONLY) or (O_BINARY)) = -1) MS_Error('CA_LoadFile: Open failed on %s not ',name);
  length := filelength(handle);
  if (not (buffer := malloc(length))) MS_Error('CA_LoadFile: Malloc failed for %s not ',name);
  if (not read(handle,buffer,length)) then
  begin
   close(handle);
   MS_Error('CA_LoadFile: Read failed on %s not ',name);
    end;
  close(handle);
  return buffer;
  end;


procedure CA_InitFile(char *filename);
(* initialize link file *)
begin
  unsigned size;
  i: integer;

  if (cachehandle) // already open, must shut down
  begin
   close(cachehandle);
   free(infotable);
   for(i := 0;i<fileinfo.numlumps;i++)  // dump the lumps
    if (lumpmain[i]) free(lumpmain[i]);
   free(lumpmain);
    end;
  // load the header
  if ((cachehandle := open(filename,O_RDONLY) or (O_BINARY)) = -1) then
  MS_Error('CA_InitFile: Can't open %s not ',filename);
  read(cachehandle,(void *)) and (fileinfo, sizeof(fileinfo));
  // load the info list
  size := fileinfo.infotablesize;
  infotable := malloc(size);
  lseek(cachehandle,fileinfo.infotableofs,SEEK_SET);
  read(cachehandle,(void *)infotable, size);
  size := fileinfo.numlumps*sizeof(int);
  lumpmain := malloc(size);
  memset(lumpmain,0,size);
  end;


int CA_CheckNamedNum(char *name)
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


int CA_GetNamedNum(char *name)
(* searches for lump with name
   returns -1 if not found *)
   begin
  i: integer;

  i := CA_CheckNamedNum(name);
  if (i <> -1) return i;
  MS_Error('CA_GetNamedNum: %s not found not ',name);
  return -1;
  end;


procedure *CA_CacheLump(int lump);
(* returns pointer to lump
   caches lump in memory *)
   begin
{$IFDEF PARMCHECK}
  if (lump >= fileinfo.numlumps) MS_Error('CA_LumpPointer: %i>%i max lumps not ',lump,fileinfo.numlumps);
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


procedure CA_ReadLump(int lump, void *dest);
(* reads a lump into a buffer *)
begin
{$IFDEF PARMCHECK}
  if (lump >= fileinfo.numlumps) MS_Error('CA_ReadLump: %i>%i max lumps not ',lump,fileinfo.numlumps);
{$ENDIF}
  lseek(cachehandle, infotable[lump].filepos, SEEK_SET);
  read(cachehandle,dest,infotable[lump].size);
  end;


procedure CA_FreeLump(unsigned lump);
(* frees a cached lump *)
begin
{$IFDEF PARMCHECK}
  if (lump >= fileinfo.numlumps) MS_Error('CA_FreeLump: %i>%i max lumps not ',lump,fileinfo.numlumps);
{$ENDIF}
  if (not lumpmain[lump]) exit;
  free(lumpmain[lump]);
  lumpmain[lump] := NULL;
  end;


procedure CA_WriteLump(unsigned lump);
(* writes a lump to the link file *)
begin
{$IFDEF PARMCHECK}
  if (lump >= fileinfo.numlumps) MS_Error('CA_WriteLump: %i>%i max lumps not ',lump,fileinfo.numlumps);
  if (not lumpmain[lump]) MS_Error('CA_WriteLump: %i not cached in not ',lump);
{$ENDIF}
  lseek(cachehandle,infotable[lump].filepos, SEEK_SET);
  write(cachehandle,lumpmain[lump],infotable[lump].size);
  end;


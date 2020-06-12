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

unit g_delphi;

interface

type
  PPointer = ^Pointer;

  PString = ^string;

  PBoolean = ^Boolean;

  PInteger = ^Integer;
  
  PLongWord = ^LongWord;

  PShortInt = ^ShortInt;

  TWordArray = packed array[0..$7FFF] of word;
  PWordArray = ^TWordArray;

  TIntegerArray = packed array[0..$7FFF] of integer;
  PIntegerArray = ^TIntegerArray;

  TLongWordArray = packed array[0..$7FFF] of LongWord;
  PLongWordArray = ^TLongWordArray;

  TSmallintArray = packed array[0..$7FFF] of Smallint;
  PSmallintArray = ^TSmallintArray;

  TByteArray = packed array[0..$7FFF] of Byte;
  PByteArray = ^TByteArray;

  TBooleanArray = packed array[0..$7FFF] of boolean;
  PBooleanArray = ^TBooleanArray;

  PProcedure = procedure;
  PPointerParmProcedure = procedure(const p: pointer);
  PIntFunction = function: integer;

  TStringArray = array[0..$7FFF] of string;
  PStringArray = ^TStringArray;

  TPointerArray = packed array[0..$7FFF] of pointer;
  PPointerArray = ^TPointerArray;

  PSmallInt = ^SmallInt;
  TSmallIntPArray = packed array[0..$7FFF] of PSmallIntArray;
  PSmallIntPArray = ^TSmallIntPArray;

  PWord = ^Word;
  TWordPArray = packed array[0..$7FFF] of PWordArray;
  PWordPArray = ^TWordPArray;

  TShortIntArray = packed array[0..$7FFF] of ShortInt;
  PShortIntArray = ^TShortIntArray; 

  TLongWordPArray = packed array[0..$7FFF] of PLongWordArray;
  PLongWordPArray = ^TLongWordPArray;

  TIntegerPArray = packed array[0..$7FFF] of PIntegerArray;
  PIntegerPArray = ^TIntegerPArray;

  PByte = ^Byte;
  TBytePArray = packed array[0..$7FFF] of PByteArray;
  PBytePArray = ^TBytePArray;

  float = single;
  Pfloat = ^float;
  TFloatArray = packed array[0..$7FFF] of float;
  PFloatArray = ^TFloatArray;

  TObjectArray = packed array[0..$7FFF] of TObject;
  PObjectArray = ^TObjectArray;


// Memory handling
function malloc(const size: integer): Pointer;

function mallocz(const size: integer): Pointer;

procedure realloc(var p: pointer; const newsize: integer);

procedure memfree(var p: pointer);

procedure ZeroMemory(const dest: pointer; const count: integer);

function memset(const dest: pointer; const val: integer; const count: integer): pointer;

// File handling
const
  fCreate = 0;
  fOpenReadOnly = 1;
  fOpenReadWrite = 2;

  sFromBeginning = 0;
  sFromCurrent = 1;
  sFromEnd = 2;

function fopen(var f: file; const FileName: string; const mode: integer): boolean;

function fread(const data: pointer; const sz1, sz2: integer; var f: file): boolean;

function fwrite(const data: pointer; const sz1, sz2: integer; var f: file): boolean;

function fsize(const FileName: string): integer;

// String functions
procedure sprintf(var s: string; const Fmt: string; const Args: array of const);

function toupper(ch: Char): Char;

function tolower(ch: Char): Char;

function strupper(const S: string): string;

function strlower(const S: string): string;

function strtrim(const S: string): string;

function stricmp(const s1: string; const s2: string): integer; overload;

function stricmp(const p1: pointer; const s1: string): integer; overload;

implementation

uses
  SysUtils;

function malloc(const size: integer): Pointer;
begin
  if size = 0 then
    result := nil
  else
    GetMem(result, size);
end;

function mallocz(const size: integer): Pointer;
begin
  result := malloc(size);
  if result <> nil then
    ZeroMemory(result, size);
end;

procedure realloc(var p: pointer; const newsize: integer);
begin
  if newsize = 0 then
    memfree(p)
  else
    reallocmem(p, newsize);
end;

procedure memfree(var p: pointer);
begin
  if p <> nil then
  begin
    FreeMem(p);
    p := nil;
  end;
end;

procedure ZeroMemory(const dest: pointer; const count: integer);
begin
  FillChar(dest^, count, 0);
end;

function memset(const dest: pointer; const val: integer; const count: integer): pointer;
begin
  FillChar(dest^, count, val);
end;

function fopen(var f: file; const FileName: string; const mode: integer): boolean;
begin
  assign(f, FileName);
  {$I-}
  if mode = fCreate then
  begin
    FileMode := 2;
    rewrite(f, 1);
  end
  else if mode = fOpenReadOnly then
  begin
    FileMode := 0;
    reset(f, 1);
  end
  else if mode = fOpenReadWrite then
  begin
    FileMode := 2;
    reset(f, 1);
  end
  else
  begin
    result := false;
    exit;
  end;
  {$I+}
  result := IOresult = 0;
end;

function fwrite(const data: pointer; const sz1, sz2: integer; var f: file): boolean;
var
  N1: integer;
  N2: integer;
begin
  N1 := sz1 * sz2;
  {$I-}
  BlockWrite(f, data^, N1, N2);
  {$I+}
  result := N1 = N2;
end;

function fread(const data: pointer; const sz1, sz2: integer; var f: file): boolean;
var
  N1: integer;
  N2: integer;
begin
  N1 := sz1 * sz2;
  {$I-}
  BlockRead(f, data^, N1, N2);
  {$I+}
  result := N1 = N2;
end;

function fsize(const FileName: string): integer;
var
  f: file;
begin
  if fopen(f, FileName, fOpenReadOnly) then
  begin
  {$I-}
    result := FileSize(f);
    close(f);
  {$I+}
  end
  else
    result := 0;
end;

procedure sprintf(var s: string; const Fmt: string; const Args: array of const);
begin
  FmtStr(s, Fmt, Args);
end;

function toupper(ch: Char): Char;
asm
{ ->    AL      Character       }
{ <-    AL      result          }

  cmp al, 'a'
  jb  @@exit
  cmp al, 'z'
  ja  @@exit
  sub al, 'a' - 'A'
@@exit:
end;

function tolower(ch: Char): Char;
asm
{ ->    AL      Character       }
{ <-    AL      result          }

  cmp al, 'A'
  jb  @@exit
  cmp al, 'Z'
  ja  @@exit
  sub al, 'A' - 'a'
@@exit:
end;

function strupper(const S: string): string;
var
  Ch: Char;
  L: Integer;
  Source, Dest: PChar;
begin
  L := Length(S);
  SetLength(result, L);
  Source := Pointer(S);
  Dest := Pointer(result);
  while L <> 0 do
  begin
    Ch := Source^;
    if (Ch >= 'a') and (Ch <= 'z') then dec(Ch, 32);
    Dest^ := Ch;
    inc(Source);
    inc(Dest);
    dec(L);
  end;
end;

function strlower(const S: string): string;
var
  Ch: Char;
  L: Integer;
  Source, Dest: PChar;
begin
  L := Length(S);
  SetLength(result, L);
  Source := Pointer(S);
  Dest := Pointer(result);
  while L <> 0 do
  begin
    Ch := Source^;
    if (Ch >= 'A') and (Ch <= 'Z') then inc(Ch, 32);
    Dest^ := Ch;
    inc(Source);
    inc(Dest);
    dec(L);
  end;
end;

function strtrim(const S: string): string;
var
  I, L: Integer;
  len: integer;
begin
  len := Length(S);
  L := len;
  I := 1;
  while (I <= L) and (S[I] <= ' ') do inc(I);
  if I > L then
    result := ''
  else
  begin
    while S[L] <= ' ' do dec(L);
    if (I = 1) and (L = len) then
      result := S
    else
      result := Copy(S, I, L - I + 1);
  end;
end;

function stricmp(const s1: string; const s2: string): integer; overload;
var
  u1, u2: string;
begin
  u1 := strupper(s1);
  u2 := strupper(s2);
  if u1 > u2 then
    result := 1
  else if u1 < u2 then
    result := -1
  else
    result := 0;
end;

function stricmp(const p1: pointer; const s1: string): integer; overload;
var
  a: PByteArray;
  b1, b2: byte;
  i: integer;
begin
  result := 0;
  a := p1;
  for i := 1 to Length(s1) do
  begin
    b2 := Ord(toupper(s1[i]));
    b1 := Ord(toupper(Chr(a[i - 1])));
    if b1 > b2 then
    begin
      result := 1;
      exit;
    end
    else if b1 < b2 then
    begin
      result := -1;
      exit;
    end;
  end;
end;

end.

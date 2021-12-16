(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020-2021 by Jim Valavanis                                *)
(*                                                                         *)
(***************************************************************************)
(* License applies to this source file                                     *)
(***************************************************************************)
(*                                                                         *)
(*  This program is free software; you can redistribute it and/or          *)
(*  modify it under the terms of the GNU General Public License            *)
(*  as published by the Free Software Foundation; either version 2         *)
(*  of the License, or (at your option) any later version.                 *)
(*                                                                         *)
(*  This program is distributed in the hope that it will be useful,        *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of         *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *)
(*  GNU General Public License for more details.                           *)
(*                                                                         *)
(*  You should have received a copy of the GNU General Public License      *)
(*  along with this program; if not, write to the Free Software            *)
(*  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA              *)
(*  02111-1307, USA.                                                       *)
(*                                                                         *)
(***************************************************************************)

{$I xGreed.inc}

unit g_delphi;

interface

const
  MAXINT = $7fffffff;
  MININT = integer($80000000);

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

  string255_t = string[255];
  Pstring255_t = ^string255_t;

// Memory handling
function malloc(const size: integer): Pointer;

function mallocz(const size: integer): Pointer;

procedure realloc(var p: pointer; const newsize: integer);

procedure memfree(var p: pointer);

procedure ZeroMemory(const dest: pointer; const count: integer);

function memset(const dest: pointer; const val: integer; const count: integer): pointer;

procedure memcpy(const dest0: pointer; const src0: pointer; count0: integer);

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

function ftell(var f: file): integer;

function fexists(const filename: string): boolean;

function fclose(var f: file): boolean;

// String functions
procedure sprintf(var s: string; const Fmt: string; const Args: array of const);

function toupper(ch: Char): Char;

function tolower(ch: Char): Char;

function strupper(const S: string): string;

function strlower(const S: string): string;

function strtrim(const S: string): string;

function stricmp(const s1: string; const s2: string): integer; overload;

function stricmp(const p1: pointer; const s2: string): integer; overload;

// convertion
function itoa(i: integer): string;

function IntToStrZfill(const z: integer; const x: integer): string;

function uitoa(l: longword): string;

function ftoa(f: single): string;

function ftoafmt(const fmt: string; f: single): string;

function atoi(const s: string): integer; overload;

function atoi(const s: string; const default: integer): integer; overload;

function atoui(const s: string): LongWord; overload;

function atoui(const s: string; const default: LongWord): LongWord; overload;

function atof(const s: string): single; overload;

function atof(const s: string; const default: single): single; overload;

function atob(const s: string): boolean;

function btoa(const b: boolean): string;

// standard output
type
  TOutProc = procedure (const s: string);

var
  outproc: TOutProc = nil;

procedure printf(const str: string); overload;

procedure printf(const Fmt: string; const Args: array of const); overload;

// Pointer operations
type
  PCAST = LongWord;

function pOp(const p: pointer; const offs: integer): pointer;

function pDiff(const p1, p2: pointer; const size: integer): integer;

// Math function
function MinI(const x1, x2: integer): integer;

function MaxI(const x1, x2: integer): integer;

function absI(const x: integer): integer;

// Operations
function CAddI(var a: integer; const b: integer): integer;

function CSubI(var a: integer; const b: integer): integer;

// C funcs
function isalnum(const c: char): boolean;

// Shifts
function _SHL(const x: integer; const bits: integer): integer;

function _SHLW(const x: LongWord; const bits: LongWord): LongWord;

function _SHR(const x: integer; const bits: integer): integer;

function _SHRW(const x: LongWord; const bits: LongWord): LongWord;

function ibetween(const x: integer; const x1, x2: integer): integer;

function fpath(const filename: string): string;

function MkDir(const d: string): boolean;

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
  result := dest;
end;

procedure memcpy(const dest0: pointer; const src0: pointer; count0: integer);
begin
  if src0 = dest0 then
    exit;
  Move(src0^, dest0^, count0);
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

function ftell(var f: file): integer;
begin
  {$I-}
  result := FileSize(f);
  {$I+}
  if IOResult <> 0 then
    result := 0;
end;

function fexists(const filename: string): boolean;
begin
  result := FileExists(filename);
end;

function fclose(var f: file): boolean;
begin
  {$I-}
  close(f);
  {$I+}
  result := IOResult = 0;
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
  if u1 = u2 then
    result := 0
  else if s1 > s2 then
    result := 1
  else
    result := -1;
end;

function stricmp(const p1: pointer; const s2: string): integer; overload;
var
  a: PByteArray;
  s1: string;
  i: integer;
begin
  s1 := '';
  a := p1;
  i := 0;
  while a[i] <> 0 do
  begin
    s1 := s1 + Chr(a[i]);
    if i > Length(s2) then
      break;
    inc(i);
  end;
  result := stricmp(s1, s2);
end;

function itoa(i: integer): string;
begin
  sprintf(result, '%d', [i]);
end;

function IntToStrZfill(const z: integer; const x: integer): string;
var
  i: integer;
  len: integer;
begin
  result := itoa(x);
  len := Length(result);
  for i := len + 1 to z do
    result := '0' + result;
end;

function uitoa(l: longword): string;
begin
  sprintf(result, '%d', [l]);
end;

function ftoa(f: single): string;
begin
  ThousandSeparator := #0;
  DecimalSeparator := '.';

  result := FloatToStr(f);
end;

function ftoafmt(const fmt: string; f: single): string;
begin
  ThousandSeparator := #0;
  DecimalSeparator := '.';

  sprintf(result, '%' + fmt + 'f', [f]);
end;

function atoi(const s: string): integer;
var
  code: integer;
  ret2: integer;
begin
  val(s, result, code);
  if code <> 0 then
  begin
    ret2 := 0;
    if Pos('0x', s) = 1 then
      val('$' + Copy(s, 3, Length(s) - 2), ret2, code)
    else if Pos('-0x', s) = 1 then
    begin
      val('$' + Copy(s, 4, Length(s) - 3), ret2, code);
      ret2 := -ret2;
    end
    else if Pos('#', s) = 1 then
      val(Copy(s, 2, Length(s) - 1), ret2, code);
    if code = 0 then
      result := ret2
    else
      result := 0;
  end;
end;

function atoi(const s: string; const default: integer): integer; overload;
var
  code: integer;
  ret2: integer;
begin
  val(s, result, code);
  if code <> 0 then
  begin
    ret2 := default;
    if Pos('0x', s) = 1 then
      val('$' + Copy(s, 3, Length(s) - 2), ret2, code)
    else if Pos('-0x', s) = 1 then
    begin
      val('$' + Copy(s, 4, Length(s) - 3), ret2, code);
      ret2 := -ret2;
    end
    else if Pos('#', s) = 1 then
      val(Copy(s, 2, Length(s) - 1), ret2, code);
    if code = 0 then
      result := ret2
    else
      result := default;
  end;
end;

function atoui(const s: string): LongWord; overload;
var
  code: integer;
  ret2: LongWord;
begin
  val(s, result, code);
  if code <> 0 then
  begin
    ret2 := 0;
    if Pos('0x', s) = 1 then
      val('$' + Copy(s, 3, Length(s) - 2), ret2, code)
    else if Pos('#', s) = 1 then
      val(Copy(s, 2, Length(s) - 1), ret2, code);
    if code = 0 then
      result := ret2
    else
      result := 0;
  end;
end;

function atoui(const s: string; const default: LongWord): LongWord; overload;
var
  code: integer;
  ret2: LongWord;
begin
  val(s, result, code);
  if code <> 0 then
  begin
    ret2 := default;
    if Pos('0x', s) = 1 then
      val('$' + Copy(s, 3, Length(s) - 2), ret2, code)
    else if Pos('#', s) = 1 then
      val(Copy(s, 2, Length(s) - 1), ret2, code);
    if code = 0 then
      result := ret2
    else
      result := default;
  end;
end;

function atof(const s: string): single;
var
  code: integer;
  i: integer;
  str: string;
begin
  ThousandSeparator := #0;
  DecimalSeparator := '.';

  val(s, result, code);
  if code <> 0 then
  begin
    str := s;
    for i := 1 to Length(str) do
      if str[i] in ['.', ','] then
        str[i] := DecimalSeparator;
    val(str, result, code);
    if code = 0 then
      exit;
    for i := 1 to Length(str) do
      if str[i] in ['.', ','] then
        str[i] := '.';
    val(str, result, code);
    if code = 0 then
      exit;
    for i := 1 to Length(str) do
      if str[i] in ['.', ','] then
        str[i] := ',';
    val(str, result, code);
    if code = 0 then
      exit;
    result := 0.0;
  end;
end;

function atof(const s: string; const default: single): single;
var
  code: integer;
  i: integer;
  str: string;
begin
  ThousandSeparator := #0;
  DecimalSeparator := '.';

  val(s, result, code);
  if code <> 0 then
  begin
    str := s;
    for i := 1 to Length(str) do
      if str[i] in ['.', ','] then
        str[i] := DecimalSeparator;
    val(str, result, code);
    if code = 0 then
      exit;
    for i := 1 to Length(str) do
      if str[i] in ['.', ','] then
        str[i] := '.';
    val(str, result, code);
    if code = 0 then
      exit;
    for i := 1 to Length(str) do
      if str[i] in ['.', ','] then
        str[i] := ',';
    val(str, result, code);
    if code = 0 then
      exit;
    result := default;
  end;
end;

function atob(const s: string): boolean;
var
  check: string;
begin
  check := strupper(strtrim(s));
  result := (check = 'TRUE') or (check = 'YES') or (check = '1')
end;

function btoa(const b: boolean): string;
begin
  if b then
    result := 'TRUE'
  else
    result := 'FALSE';
end;

procedure printf(const str: string);
begin
  if Assigned(outproc) then
    outproc(str)
  else if IsConsole then
    write(str);
end;

procedure printf(const Fmt: string; const Args: array of const);
var
  s: string;
begin
  sprintf(s, Fmt, Args);
  printf(s);
end;

function pOp(const p: pointer; const offs: integer): pointer;
begin
  result := pointer(PCAST(p) + offs);
end;

function pDiff(const p1, p2: pointer; const size: integer): integer;
begin
  result := (Integer(p1) - Integer(p2)) div size;
end;

function MinI(const x1, x2: integer): integer;
begin
  if x1 < x2 then
    result := x1
  else
    result := x2;
end;

function MaxI(const x1, x2: integer): integer;
begin
  if x1 > x2 then
    result := x1
  else
    result := x2;
end;

function absI(const x: integer): integer;
begin
  if x < 0 then
    result := -x
  else
    result := x;
end;

function CAddI(var a: integer; const b: integer): integer;
begin
  a := a + b;
  result := a;
end;

function CSubI(var a: integer; const b: integer): integer;
begin
  a := a - b;
  result := a;
end;

function isalnum(const c: char): boolean;
begin
  result := ((c >= 'A') and (c <= 'Z')) or ((c >= 'z') and (c <= 'z')) or ((c >= '0') and (c <= '9'))
end;

function _SHL(const x: integer; const bits: integer): integer; assembler;
asm
  mov ecx, edx
  sal eax, cl
end;

function _SHLW(const x: LongWord; const bits: LongWord): LongWord;
begin
  result := x shl bits;
end;

function _SHR(const x: integer; const bits: integer): integer; assembler;
asm
  mov ecx, edx
  sar eax, cl
end;

function _SHRW(const x: LongWord; const bits: LongWord): LongWord;
begin
  result := x shr bits;
end;

function ibetween(const x: integer; const x1, x2: integer): integer;
begin
  if x <= x1 then
    result := x1
  else if x >= x2 then
    result := x2
  else
    result := x;
end;

function fpath(const filename: string): string;
begin
  result := ExtractFilePath(filename);
end;

function MkDir(const d: string): boolean;
begin
  try
    if DirectoryExists(d) then
    begin
      result := true;
      exit;
    end;

    result := CreateDir(d);
    if not result then
      result := ForceDirectories(d);
  except
    result := false;
  end;
end;

end.

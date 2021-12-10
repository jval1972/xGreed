(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020 - 2021 by Jim Valavanis                              *)
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

program xGreed;

{$R *.res}

{$I xGreed.inc}

uses
  Windows,
  DirectX in 'Base\DirectX.pas',
  g_delphi in 'Base\g_delphi.pas',
  i_windows in 'Base\i_windows.pas',
  BASS in 'Base\bass.pas',
  scriptengine in 'Base\scriptengine.pas',
  i_main in 'Base\i_main.pas',
  i_video in 'Base\i_video.pas',
  constant in 'Greed\constant.pas',
  d_disk in 'Greed\d_disk.pas',
  d_font in 'Greed\d_font.pas',
  d_ints in 'Greed\d_ints.pas',
  d_ints_h in 'Greed\d_ints_h.pas',
  d_misc in 'Greed\d_misc.pas',
  d_video in 'Greed\d_video.pas',
  display in 'Greed\display.pas',
  event in 'Greed\event.pas',
  intro in 'Greed\intro.pas',
  menu in 'Greed\menu.pas',
  modplay in 'Greed\modplay.pas',
  net in 'Greed\net.pas',
  playfli in 'Greed\playfli.pas',
  protos_h in 'Greed\protos_h.pas',
  r_conten in 'Greed\r_conten.pas',
  r_plane in 'Greed\r_plane.pas',
  r_public in 'Greed\r_public.pas',
  r_public_h in 'Greed\r_public_h.pas',
  r_refdef in 'Greed\r_refdef.pas',
  r_render in 'Greed\r_render.pas',
  r_spans in 'Greed\r_spans.pas',
  r_walls in 'Greed\r_walls.pas',
  raven in 'Greed\raven.pas',
  spawn in 'Greed\spawn.pas',
  sprites in 'Greed\sprites.pas',
  timer in 'Greed\timer.pas',
  utils in 'Greed\utils.pas',
  zlibpas in 'zlib\zlibpas.pas',
  pngimage in 'Base\pngimage.pas',
  m_screenshot in 'Base\m_screenshot.pas';

var
  hGreedWnd: HWND = 0;

begin
  //Check if Generic.exe is running. If it's running then focus on the window
  hGreedWnd := FindWindow(APPNAME, APPNAME);
  if hGreedWnd <> 0 then
  begin
    SetForegroundWindow(hGreedWnd);
    Halt(0);
  end;

  if not InitApplication(hInstance) then
    Halt(1);

  if not InitInstance(hInstance, 0) then
    Halt(1);

  I_Init;
  printf('Starting %s version %s'#13#10, [APPNAME, I_VersionBuilt]);

  printf('I_InitGraphics: Initialize directdraw.' + #13#10);
  I_InitGraphics;

  startup;

  printf('I_ShutDownGraphics: Shut down graphics.'#13#10);
  I_ShutDownGraphics;

  printf('DestroyWindow: Closing application window.'#13#10);
  DestroyWindow(hMainWnd);

  printf('I_ShutDown: Shut down I/O.'#13#10);
  I_ShutDown;

  Halt(0);
end.


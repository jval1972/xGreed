
unit d_video_h;
interface

{
  Automatically converted by H2Pas 1.0.0 from D_video.h
  The following command line parameters were used:
    -o
    d_video_h.pas
    D_video.h
}

  Type
  Pbyte  = ^byte;
  Ppic_t  = ^pic_t;
{$IFDEF FPC}
{$PACKRECORDS C}
{$ENDIF}


  {************************************************************************* }
  {                                                                          }
  {                                                                          }
  { Raven 3D Engine                                                          }
  { Copyright (C) 1995 by Softdisk Publishing                                }
  {                                                                          }
  { Original Design:                                                         }
  {  John Carmack of id Software                                             }
  {                                                                          }
  { Enhancements by:                                                         }
  {  Robert Morgan of Channel 7............................Main Engine Code  }
  {  Todd Lewis of Softdisk Publishing......Tools,Utilities,Special Effects  }
  {  John Bianca of Softdisk Publishing..............Low-level Optimization  }
  {  Carlos Hasan..........................................Music/Sound Code  }
  {                                                                          }
  {                                                                          }
  {************************************************************************* }
{$ifndef D_VIDEO_H}
{$define D_VIDEO_H}  
  {*** CONSTANTS *** }

  const
    SCREEN = $a0000;    
    SCREENWIDTH = 320;    
    SCREENHEIGHT = 200;    
  {*** VARIABLES *** }
(** unsupported pragma#pragma pack(push,packing,1)*)

  type
    pic_t = record
        width : smallint;
        height : smallint;
        orgx : smallint;
        orgy : smallint;
        data : byte;
      end;
(** unsupported pragma#pragma pack(pop,packing)*)

    var
      screen : ^byte;cvar;external;
      ylookup : array[0..(SCREENHEIGHT)-1] of ^byte;cvar;external;
      transparency : ^byte;cvar;external;
      translookup : array[0..254] of ^byte;cvar;external;
  {*** FUNCTIONS *** }

  procedure VI_Init;

  procedure VI_SetPalette(palette:Pbyte);

  procedure VI_GetPalette(palette:Pbyte);

  procedure VI_FillPalette(red:longint; green:longint; blue:longint);

  procedure VI_FadeOut(start:longint; end:longint; red:longint; green:longint; blue:longint; 
              steps:longint);

  procedure VI_FadeIn(start:longint; end:longint; pallete:Pbyte; steps:longint);

  procedure VI_DrawPic(x:longint; y:longint; pic:Ppic_t);

  procedure VI_DrawMaskedPic(x:longint; y:longint; pic:Ppic_t);

  procedure VI_DrawMaskedPicToBuffer(x:longint; y:longint; pic:Ppic_t);

  procedure VI_DrawMaskedPicToBuffer2(x:longint; y:longint; pic:Ppic_t);

  procedure VI_DrawTransPicToBuffer(x:longint; y:longint; pic:Ppic_t);

  procedure VI_BlitView;

  procedure VI_ResetPalette;

{$endif}

implementation

  procedure VI_Init;
  begin
    { You must implement this function }
  end;
  procedure VI_SetPalette(palette:Pbyte);
  begin
    { You must implement this function }
  end;
  procedure VI_GetPalette(palette:Pbyte);
  begin
    { You must implement this function }
  end;
  procedure VI_FillPalette(red:longint; green:longint; blue:longint);
  begin
    { You must implement this function }
  end;
  procedure VI_FadeOut(start:longint; end:longint; red:longint; green:longint; blue:longint; 
              steps:longint);
  begin
    { You must implement this function }
  end;
  procedure VI_FadeIn(start:longint; end:longint; pallete:Pbyte; steps:longint);
  begin
    { You must implement this function }
  end;
  procedure VI_DrawPic(x:longint; y:longint; pic:Ppic_t);
  begin
    { You must implement this function }
  end;
  procedure VI_DrawMaskedPic(x:longint; y:longint; pic:Ppic_t);
  begin
    { You must implement this function }
  end;
  procedure VI_DrawMaskedPicToBuffer(x:longint; y:longint; pic:Ppic_t);
  begin
    { You must implement this function }
  end;
  procedure VI_DrawMaskedPicToBuffer2(x:longint; y:longint; pic:Ppic_t);
  begin
    { You must implement this function }
  end;
  procedure VI_DrawTransPicToBuffer(x:longint; y:longint; pic:Ppic_t);
  begin
    { You must implement this function }
  end;
  procedure VI_BlitView;
  begin
    { You must implement this function }
  end;
  procedure VI_ResetPalette;
  begin
    { You must implement this function }
  end;

end.

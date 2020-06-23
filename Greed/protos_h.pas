(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020 by Jim Valavanis                                     *)
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

unit protos_h;

interface

uses
  r_public_h;
  
{ Raven  }
{ generated sprites }

const
  S_START = 513;
  S_BULLET1 = 513;
  S_BULLET2 = 514;
  S_BULLET3 = 515;
  S_BULLET4 = 516;
  S_BULLET7 = 517;
  S_BULLET9 = 518;
  S_BULLET10 = 519;
  S_BULLET11 = 520;
  S_BULLET12 = 521;
  S_BULLET16 = 522;
  S_BULLET17 = 523;
  S_BULLET18 = 524;
  S_EXPLODE = 525;
  S_EXPLODE2 = 526;
  S_MINEBULLET = 527;
  S_MINEPUFF = 528;
  S_HANDBULLET = 529;
  S_SOULBULLET = 530;
  S_WALLPUFF = 531;
  S_BLOODSPLAT = 532;
  S_GREENBLOOD = 533;
  S_PLASMAWALLPUFF = 534;
  S_GREENPUFF = 535;
  S_ARROWPUFF = 536;
  S_GENERATOR = 537;
  S_WARP = 538;
  S_MONSTERBULLET1 = 539;
  S_MONSTERBULLET2 = 540;
  S_MONSTERBULLET3 = 541;
  S_MONSTERBULLET4 = 542;
  S_MONSTERBULLET5 = 543;
  S_MONSTERBULLET6 = 544;
  S_MONSTERBULLET7 = 545;
  S_MONSTERBULLET8 = 546;
  S_MONSTERBULLET9 = 547;
  S_MONSTERBULLET10 = 548;
  S_MONSTERBULLET11 = 549;
  S_MONSTERBULLET12 = 550;
  S_MONSTERBULLET13 = 551;
  S_MONSTERBULLET14 = 552;
  S_MONSTERBULLET15 = 553;
  S_END = 553;
  S_SMALLEXPLODE = 600;
  S_BONUSITEM = 601;
  S_INSTAWALL = 602;
  S_DECOY = 603;
  S_GRENADE = 604;
  S_CLONE = 605;
  S_GRENADEBULLET = 606;
  S_METALPARTS = 607;
{ mapsprites }
  S_PLAYER = 1;
  S_NETPLAYER2 = 2;
  S_NETPLAYER3 = 3;
  S_NETPLAYER4 = 4;
  S_NETPLAYER5 = 5;
  S_NETPLAYER6 = 6;
  S_NETPLAYER7 = 7;
  S_NETPLAYER8 = 8;
  S_SOLID = 10;
  S_WARP1 = 11;
  S_WARP2 = 12;
  S_WARP3 = 13;
  S_ELEVATOR = 15;
  S_PAUSEDELEVATOR = 16;
  S_SWAPSWITCH = 19;
  S_ELEVATORHIGH = 20;
  S_ELEVATORLOW = 21;
  S_ELEVATOR3M = 22;
  S_ELEVATOR6M = 23;
  S_ELEVATOR15M = 24;
  S_TRIGGER1 = 27;
  S_TRIGGERD1 = 28;
  S_TRIGGER2 = 30;
  S_TRIGGERD2 = 31;
  S_MONSTER13 = 34;
  S_MONSTER13_NS = 35;
  S_MONSTER14 = 36;
  S_MONSTER14_NS = 37;
  S_MONSTER15 = 38;
  S_MONSTER15_NS = 39;
  S_STRIGGER = 49;
  S_SDOOR = 50;
  S_PRIMARY1 = 51;
  S_PRIMARY2 = 52;
  S_SECONDARY1 = 53;
  S_SECONDARY2 = 54;
  S_SECONDARY3 = 55;
  S_SECONDARY4 = 56;
  S_SECONDARY5 = 57;
  S_SECONDARY6 = 58;
  S_SECONDARY7 = 59;
  S_VDOOR1 = 60;
  S_HDOOR1 = 61;
  S_VDOOR2 = 62;
  S_HDOOR2 = 63;
  S_VDOOR3 = 64;
  S_HDOOR3 = 65;
  S_VDOOR4 = 66;
  S_HDOOR4 = 67;
  S_VDOOR5 = 68;
  S_HDOOR5 = 69;
  S_VDOOR6 = 70;
  S_HDOOR6 = 71;
  S_VDOOR7 = 72;
  S_HDOOR7 = 73;
  S_MONSTER1 = 75;
  S_MONSTER1_NS = 76;
  S_MONSTER2 = 77;
  S_MONSTER2_NS = 78;
  S_MONSTER3 = 79;
  S_MONSTER3_NS = 80;
  S_MONSTER4 = 81;
  S_MONSTER4_NS = 82;
  S_MONSTER6 = 84;
  S_MONSTER6_NS = 85;
  S_MONSTER7 = 86;
  S_MONSTER7_NS = 87;
  S_MONSTER8 = 88;
  S_MONSTER8_NS = 89;
  S_MONSTER9 = 90;
  S_MONSTER9_NS = 91;
  S_MONSTER10 = 92;
  S_MONSTER10_NS = 93;
  S_MONSTER11 = 94;
  S_MONSTER11_NS = 95;
  S_MONSTER12 = 96;
  S_MONSTER12_NS = 97;
  S_MONSTER5 = 98;
  S_MONSTER5_NS = 99;
  S_GENERATOR1 = 100;
  S_GENERATOR2 = 101;
  S_SPAWN8_NS = 102;
  S_SPAWN9_NS = 103;
  S_WEAPON0 = 105;
  S_WEAPON1 = 106;
  S_WEAPON2 = 107;
  S_WEAPON3 = 108;
  S_WEAPON4 = 109;
  S_WEAPON5 = 110;
  S_WEAPON6 = 111;
  S_WEAPON7 = 112;
  S_WEAPON8 = 113;
  S_WEAPON9 = 114;
  S_WEAPON10 = 115;
  S_WEAPON11 = 116;
  S_WEAPON12 = 117;
  S_WEAPON13 = 118;
  S_WEAPON14 = 119;
  S_WEAPON15 = 120;
  S_WEAPON16 = 121;
  S_WEAPON17 = 122;
  S_WEAPON18 = 123;
  S_GOODIEBOX = 133;
  S_MEDBOX = 134;
  S_AMMOBOX = 135;
  S_PROXMINE = 136;
  S_TIMEMINE = 137;
  S_EXIT = 138;
  S_HOLE = 139;
  S_ITEM1 = 140;
  S_ITEM2 = 141;
  S_ITEM3 = 142;
  S_ITEM4 = 143;
  S_ITEM5 = 144;
  S_ITEM6 = 145;
  S_ITEM7 = 146;
  S_ITEM8 = 147;
  S_ITEM9 = 148;
  S_ITEM10 = 149;
  S_ITEM11 = 150;
  S_ITEM12 = 151;
  S_ITEM13 = 152;
  S_ITEM14 = 153;
  S_ITEM15 = 154;
  S_ITEM16 = 155;
  S_ITEM17 = 156;
  S_ITEM18 = 157;
  S_ITEM19 = 158;
  S_ITEM20 = 159;
  S_ITEM21 = 160;
  S_ITEM22 = 161;
  S_ITEM23 = 162;
  S_ITEM24 = 163;
  S_ITEM25 = 164;
  S_ITEM26 = 165;
  S_ITEM27 = 166;
  S_ITEM28 = 167;
  S_ITEM29 = 168;
  S_ITEM30 = 169;
  S_ITEM31 = 170;
  S_ITEM32 = 171;
  S_ITEM33 = 172;
  S_ITEM34 = 173;
  S_SPAWN1 = 200;
  S_SPAWN2 = 201;
  S_SPAWN3 = 202;
  S_SPAWN4 = 203;
  S_SPAWN5 = 204;
  S_SPAWN6 = 205;
  S_SPAWN7 = 206;
  S_SPAWN8 = 207;
  S_SPAWN9 = 208;
  S_SPAWN10 = 209;
  S_SPAWN11 = 210;
  S_SPAWN12 = 211;
  S_SPAWN13 = 212;
  S_SPAWN14 = 213;
  S_SPAWN15 = 214;
  S_DEADMONSTER15 = 241;
  S_DEADMONSTER14 = 242;
  S_DEADMONSTER13 = 243;
  S_DEADMONSTER12 = 244;
  S_DEADMONSTER11 = 245;
  S_DEADMONSTER10 = 246;
  S_DEADMONSTER9 = 247;
  S_DEADMONSTER8 = 248;
  S_DEADMONSTER7 = 249;
  S_DEADMONSTER6 = 250;
  S_DEADMONSTER5 = 251;
  S_DEADMONSTER4 = 252;
  S_DEADMONSTER3 = 253;
  S_DEADMONSTER2 = 254;
  S_DEADMONSTER1 = 255;
{------------------------------ }
  S_NETPLAYER = 399;
  S_MEDPAK1 = 400;
  S_MEDPAK2 = 401;
  S_MEDPAK3 = 402;
  S_MEDPAK4 = 403;
  S_ENERGY = 404;
  S_BALLISTIC = 405;
  S_PLASMA = 406;
  S_SHIELD1 = 407;
  S_SHIELD2 = 408;
  S_SHIELD3 = 409;
  S_SHIELD4 = 410;
  S_IGRENADE = 411;
  S_IREVERSO = 412;
  S_IPROXMINE = 413;
  S_ITIMEMINE = 414;
  S_IDECOY = 415;
  S_IINSTAWALL = 416;
  S_ICLONE = 417;
  S_IHOLO = 418;
  S_IINVIS = 419;
  S_IJAMMER = 420;
  S_ISTEALER = 421;
  S_GENSTART = 400;
  S_GENEND = 421;
{ stored back in mapsprites }
  SM_ELEVATOR = 127;    { for special elevators (to make solid) }
  SM_WARP1 = 128;    { permanent }
  SM_WARP2 = 129;    { permanent }
  SM_WARP3 = 130;    { permanent }
  SM_MEDPAK1 = 131;
  SM_MEDPAK2 = 132;
  SM_MEDPAK3 = 133;
  SM_MEDPAK4 = 134;
  SM_ENERGY = 135;
  SM_BALLISTIC = 136;
  SM_PLASMA = 137;
  SM_SHIELD1 = 138;
  SM_SHIELD2 = 139;
  SM_SHIELD3 = 140;
  SM_SHIELD4 = 141;
  SM_IGRENADE = 142;
  SM_IREVERSO = 143;
  SM_IPROXMINE = 144;
  SM_ITIMEMINE = 145;
  SM_IDECOY = 146;
  SM_IINSTAWALL = 147;
  SM_ICLONE = 148;
  SM_IHOLO = 149;
  SM_IINVIS = 150;
  SM_IJAMMER = 151;
  SM_ISTEALER = 152;
  SM_SWITCHDOWN = 153;
  SM_SWITCHDOWN2 = 154;
  SM_SWITCHUP = 155;
  SM_SWAPSWITCH = 156;
  SM_BONUSITEM = 158;
  SM_PRIMARY1 = 159;
  SM_PRIMARY2 = 160;
  SM_SECONDARY1 = 161;
  SM_SECONDARY2 = 162;
  SM_SECONDARY3 = 163;
  SM_SECONDARY4 = 164;
  SM_SECONDARY5 = 165;
  SM_SECONDARY6 = 166;
  SM_SECONDARY7 = 167;
  SM_STRIGGER = 168;
  SM_EXIT = 169;
  SM_AMMOBOX = 170;
  SM_MEDBOX = 171;
  SM_GOODIEBOX = 172;
  SM_WEAPON0 = 200;
  SM_WEAPON1 = 201;
  SM_WEAPON2 = 202;
  SM_WEAPON3 = 203;
  SM_WEAPON4 = 204;
  SM_WEAPON5 = 205;
  SM_WEAPON6 = 206;
  SM_WEAPON7 = 207;
  SM_WEAPON8 = 208;
  SM_WEAPON9 = 209;
  SM_WEAPON10 = 210;
  SM_WEAPON11 = 211;
  SM_WEAPON12 = 212;
  SM_WEAPON13 = 213;
  SM_WEAPON14 = 214;
  SM_WEAPON15 = 215;
  SM_WEAPON16 = 216;
  SM_WEAPON17 = 217;
  SM_WEAPON18 = 218;
  SM_NETPLAYER = 100;
  SM_CLONE = 99;
{ sound effects }
  SN_MON8_WAKE = 0;
  SN_MON8_FIRE = 1;
  SN_MON8_DIE = 2;
  SN_MON9_WAKE = 3;
  SN_MON9_FIRE = 4;
  SN_MON9_DIE = 5;
  SN_MON10_WAKE = 6;
  SN_MON10_FIRE = 7;
  SN_MON10_DIE = 8;
  SN_MON11_WAKE = 9;
  SN_MON11_FIRE = 10;
  SN_MON11_DIE = 11;
  SN_DOOR = 12;
  SN_BULLET1 = 13;
  SN_BULLET3 = 14;
  SN_BULLET4 = 15;
  SN_BULLET5 = 16;
  SN_BULLET8 = 17;
  SN_BULLET9 = 18;
  SN_BULLET10 = 19;
  SN_BULLET12 = 20;
  SN_BULLET13 = 21;
  SN_EXPLODE1 = 22;
  SN_EXPLODE2 = 23;
  SN_PICKUP0 = 24;
  SN_PICKUP1 = 25;
  SN_PICKUP2 = 26;
  SN_PICKUP3 = 27;
  SN_PICKUP4 = 28;
  SN_HIT0 = 29;
  SN_HIT1 = 30;
  SN_HIT2 = 31;
  SN_HIT3 = 32;
  SN_HIT4 = 33;
  SN_DEATH0 = 34;
  SN_DEATH1 = 35;
  SN_DEATH2 = 36;
  SN_DEATH3 = 37;
  SN_DEATH4 = 38;
  SN_WEAPPICKUP0 = 39;
  SN_WEAPPICKUP1 = 40;
  SN_WEAPPICKUP2 = 41;
  SN_WEAPPICKUP3 = 42;
  SN_WEAPPICKUP4 = 43;
  SN_GRENADE = 44;
  SN_TRIGGER = 45;
  SN_NEXUS = 46;
  SN_EVENTALARM = 47;
  SN_ELEVATORSTART = 48;
  SN_ELEVATORSTOP = 49;
  SN_WALLSWITCH = 50;
  SN_BULLET18 = 51;
  SN_MON1_WAKE = 52;
  SN_MON1_FIRE = 53;
  SN_MON1_DIE = 54;
  SN_MON2_WAKE = 55;
  SN_MON2_FIRE = 56;
  SN_MON2_DIE = 57;
  SN_MON3_WAKE = 58;
  SN_MON3_FIRE = 59;
  SN_MON3_DIE = 60;
  SN_MON4_WAKE = 61;
  SN_MON4_FIRE = 62;
  SN_MON4_DIE = 63;
  SN_MON5_WAKE = 64;
  SN_MON5_FIRE = 65;
  SN_MON5_DIE = 66;
  SN_MON6_WAKE = 67;
  SN_MON6_FIRE = 68;
  SN_MON6_DIE = 69;
  SN_MON7_WAKE = 70;
  SN_MON7_FIRE = 71;
  SN_MON7_DIE = 72;
  SN_MON12_WAKE = 73;
  SN_MON12_FIRE = 74;
  SN_MON12_DIE = 75;
  SN_MON13_WAKE = 76;
  SN_MON13_FIRE = 77;
  SN_MON13_DIE = 78;
  SN_MON14_WAKE = 79;
  SN_MON14_FIRE = 80;
  SN_MON14_DIE = 81;
  SN_MON15_WAKE = 82;
  SN_MON15_FIRE = 83;
  SN_MON15_DIE = 84;
  SN_WARP = 85;
  SN_SOULSTEALER = 86;
  SN_TEMPLEEGG = 87;
  SN_KAALEGG = 88;
  SN_BULLET17 = 89;
{ player special effects  }
  SE_REVERSOPILL = 1;
  SE_DECOY = 2;
  SE_CLONE = 3;
  SE_INVISIBILITY = 4;
  SE_WARPJAMMER = 5;
  KBDELAY = 20;
  MAXPLAYERS = 8;
  MAXRANDOMITEMS = 48;
  MAXINVENTORY = 13;
{ adjustment to amount of head bobbing  }
  BOBFACTOR = 12;
  RECBUFSIZE = 16000;
  MAXPROBE = 960;
  MOVEDELAY = 7;
  MAXSPAWN = 50;
  AMBIENTLIGHT = 2048;
  MAXBOBS = 30;
  MINDOORSIZE = 8;
  SCROLLRATE = 2;
  HEALTIME = 300;
  MAXSTARTLOCATIONS = 8;
  MAXCHARTYPES = 6;
  MAXVIEWSIZE = 5;

type
  SoundCard_s = packed record
    ID: byte;
    Modes: byte;
    Port: word;
    IrqLine: byte;
    DmaChannel: byte;
    SampleRate: word;
    DriverName: packed array[0..15] of char;
    inversepan: boolean;
    ckeys: packed array[0..13] of byte;
    effecttracks: byte;
    musicvol: integer;
    sfxvol: integer;
    ambientlight: integer;
    camdelay: integer;
    screensize: integer;
    animation: boolean;
    violence: boolean;
    joystick: byte;
    mouse: byte;
    chartype: integer;
    socket: integer;
    numplayers: integer;
    dialnum: string[12];
    com: integer;
    serplayers: integer;
    netname: string[12];
    jcenx: word;
    jceny: word;
    xsense: word;
    ysense: word;
    rightbutton: integer;
    leftbutton: integer;
    joybut1: integer;
    joybut2: integer;
    netmap: integer;
    netdifficulty: integer;
    mousesensitivity: integer;
    turnspeed: integer;
    turnaccel: integer;
    vrhelmet: integer;
    vrangle: integer;
    vrdist: integer;
  end;
  SoundCard = SoundCard_s;
  PSoundCard = ^SoundCard;
{ location }
{ facing angle }
{ height of character (30 units default) }
{ looking up and down }
{ net only: firing or getting hit }

  Pplayer_t = ^player_t;
  player_t = packed record
    x: fixed_t;
    y: fixed_t;
    z: fixed_t;
    mapspot: integer;
    angle: integer;
    height: fixed_t;
    currentweapon: integer;
    shield: integer;
    angst: integer;
    maxshield: integer;
    maxangst: integer;
    map: integer;
    mission: integer;
    chartype: integer;
    levelscore: integer;
    difficulty: integer;
    weapons: array[0..4] of integer;
    ammo: array[0..2] of integer;
    bodycount: integer;
    timecount: integer;
    score: integer;
    northmap: packed array[0..(MAPCOLS * MAPROWS) - 1] of byte;
    westmap: packed array[0..(MAPCOLS * MAPROWS) - 1] of byte;
    northwall: packed array[0..(MAPCOLS * MAPROWS) - 1] of byte;
    westwall: packed array[0..(MAPCOLS * MAPROWS) - 1] of byte;
    savesprites: packed array[0..(MAPCOLS * MAPROWS) - 1] of byte;
    scrollmin: integer;
    scrollmax: integer;
    primaries: array[0..1] of integer;
    secondaries: array[0..6] of integer;
    frags: array[0..MAXPLAYERS - 1] of integer;
    runmod: integer;
    walkmod: integer;
    inventory: array[0..MAXINVENTORY - 1] of integer;
    status: integer;
    holopic: integer;
    holoscale: integer;
    jumpmod: fixed_t;
    events: packed array[0..255] of byte;
  end;

  { how fast it charges }
  { current charge level }
  { timecount + chargetime }

  Pweapon_t = ^weapon_t;
  weapon_t = packed record
    chargerate: integer;
    charge: integer;
    chargetime: integer;
    ammotype: integer;
    ammorate: integer;
  end;

  Pbonus_t = ^bonus_t;
  bonus_t = packed record
    time: integer;
    score: integer;
    name: string[255]; // PChar
    tilex: integer;
    tiley: integer;
    mapspot: integer;
    num: integer;
    sprite: Pscaleobj_t;
  end;


{ Net  }
const
  DATALENGTH = 128;
  { greed executes an int to send commands }
  { communication between greed and the driver }
  { CMD_SEND or CMD_GET }
  { dest for send, set by get (-1 = no packet) }
  { info common to all nodes }
  { console is allways node 0 }
  { info specific to this node }
  { 0-3 = player number }
  { 1-4 }
  { packet data to be sent }

type
  Pgreedcom_t = ^greedcom_t;
  greedcom_t = packed record
    id: integer;
    intnum: smallint;
    maxusage: smallint;
    nettype: smallint;
    command: smallint;
    remotenode: smallint;
    datalength: smallint;
    numnodes: smallint;
    consoleplayer: smallint;
    numplayers: smallint;
    data: packed array[0..DATALENGTH - 1] of char;
  end;

  Ppevent_t = ^pevent_t;
  pevent_t = packed record
    id: integer;
    playerid: integer;
    x: fixed_t;
    y: fixed_t;
    z: fixed_t;
    angle: integer;
    angst: integer;
    chartype: integer;
    status: integer;
    holopic: integer;
    holoscale: integer;
    height: fixed_t;
    specialeffect: integer;
  end;

implementation

end.

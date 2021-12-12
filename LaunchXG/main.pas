unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls;

type
  TForm1 = class(TForm)
    SoundGroupBox: TGroupBox;
    InputGroupBox: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    KeyboardRadioGroup: TRadioGroup;
    ScreenblocksTrackBar: TTrackBar;
    SFXTrackBar: TTrackBar;
    MusicTrackBar: TTrackBar;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    SkipIntroCheckBox: TCheckBox;
    CheckBox_4_3: TCheckBox;
    MouseGroupBox1: TGroupBox;
    UseMouseCheckBox: TCheckBox;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    SensitivityTrackBar: TTrackBar;
    SensitivityXTrackBar: TTrackBar;
    SensitivityYTrackBar: TTrackBar;
    EpisodeRadioGroup: TRadioGroup;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ScreenblocksTrackBarChange(Sender: TObject);
    procedure DetailCheckBoxClick(Sender: TObject);
    procedure SmoothDisplayCheckBoxClick(Sender: TObject);
    procedure SFXTrackBarChange(Sender: TObject);
    procedure MusicTrackBarChange(Sender: TObject);
    procedure ChannelsTrackBarChange(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure AutorunModeCheckBoxClick(Sender: TObject);
  private
    { Private declarations }
    defaults: TStringList;
    in_startup: boolean;
    procedure SetDefault(const defname: string; const defvalue: integer);
    function GetDefault(const defname: string): integer;
    procedure ToControls;
    procedure FromControls;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  i: integer;
begin
  DoubleBuffered := True;
  for i := 0 to ComponentCount - 1 do
    if Components[i].InheritsFrom(TWinControl) then
      (Components[i] as TWinControl).DoubleBuffered := True;
  defaults := TStringList.Create;
  if FileExists('xGreed.ini') then
    defaults.LoadFromFile('xGreed.ini')
  else
    defaults.Text :=
      'ambientlight=2048'#13#10 +
      'violence=1'#13#10 +
      'animation=1'#13#10 +
      'musicvol=100'#13#10 +
      'sfxvol=128'#13#10 +
      'bt_north=72'#13#10 +
      'bt_east=77'#13#10 +
      'bt_south=80'#13#10 +
      'bt_west=75'#13#10 +
      'bt_fire=29'#13#10 +
      'bt_straf=56'#13#10 +
      'bt_use=57'#13#10 +
      'bt_run=42'#13#10 +
      'bt_jump=44'#13#10 +
      'bt_useitem=45'#13#10 +
      'bt_asscam=30'#13#10 +
      'bt_lookup=73'#13#10 +
      'bt_lookdown=81'#13#10 +
      'bt_centerview=71'#13#10 +
      'bt_slideleft=51'#13#10 +
      'bt_slideright=52'#13#10 +
      'bt_invleft=82'#13#10 +
      'bt_invright=83'#13#10 +
      'bt_motionmode=31'#13#10 +
      'gameepisode=1'#13#10 +
      'screensize=4'#13#10 +
      'camdelay=35'#13#10 +
      'vid_pillarbox_pct=17'#13#10 +
      'mouse=1'#13#10 +
      'mousesensitivity=10'#13#10 +
      'mousesensitivityx=10'#13#10 +
      'mousesensitivityy=5'#13#10 +
      'invertmouseturn=0'#13#10 +
      'invertmouselook=0';

  in_startup := True;
  ToControls;
  in_startup := False;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  defaults.Free;
end;

procedure TForm1.SetDefault(const defname: string; const defvalue: integer);
begin
  if defaults.IndexOfName(defname) < 0 then
    defaults.Add(defname + '=' + IntToStr(defvalue))
  else
    defaults.Values[defname] := IntToStr(defvalue);
end;

function TForm1.GetDefault(const defname: string): integer;
begin
  Result := StrToIntDef(defaults.Values[defname], 0);
end;

procedure TForm1.ToControls;
begin
  if (GetDefault('bt_north') = 72) and
     (GetDefault('bt_south') = 80) and
     (GetDefault('bt_slideleft') = 51) and
     (GetDefault('bt_slideright') = 52) and
     (GetDefault('bt_asscam') = 30) and
     (GetDefault('bt_motionmode') = 31) then
    KeyboardRadioGroup.ItemIndex := 0
  else if (GetDefault('bt_north') = $11) and
     (GetDefault('bt_south') = $1f) and
     (GetDefault('bt_slideleft') = $1e) and
     (GetDefault('bt_slideright') = $20) and
     (GetDefault('bt_asscam') = $2e) and
     (GetDefault('bt_motionmode') = $21) then
    KeyboardRadioGroup.ItemIndex := 1
  else
    KeyboardRadioGroup.ItemIndex := 2;
  ScreenblocksTrackBar.Position := GetDefault('screensize');
  SFXTrackBar.Position := GetDefault('sfxvol');
  MusicTrackBar.Position := GetDefault('musicvol');
  CheckBox_4_3.Checked := GetDefault('vid_pillarbox_pct') = 17;
  UseMouseCheckBox.Checked := GetDefault('mouse') <> 0;
  EpisodeRadioGroup.ItemIndex := GetDefault('gameepisode') - 1;
  SensitivityTrackBar.Position := GetDefault('mousesensitivity');
  SensitivityXTrackBar.Position := GetDefault('mousesensitivityx');
  SensitivityYTrackBar.Position := GetDefault('mousesensitivityy');
end;

procedure TForm1.FromControls;
begin
  if in_startup then
    Exit;
  if KeyboardRadioGroup.ItemIndex = 0 then
  begin
    SetDefault('bt_north', 72);
    SetDefault('bt_south', 80);
    SetDefault('bt_slideleft', 51);
    SetDefault('bt_slideright', 52);
    SetDefault('bt_asscam', 30);
    SetDefault('bt_motionmode', 31);
  end
  else if KeyboardRadioGroup.ItemIndex = 1 then
  begin
    SetDefault('bt_north', $11);
    SetDefault('bt_south', $1f);
    SetDefault('bt_slideleft', $1e);
    SetDefault('bt_slideright', $20);
    SetDefault('bt_asscam', $2e);
    SetDefault('bt_motionmode', $21);
  end;

  SetDefault('screenblocks', ScreenblocksTrackBar.Position);
  SetDefault('sfx_volume', SFXTrackBar.Position);
  SetDefault('music_volume', MusicTrackBar.Position);
  if CheckBox_4_3.Checked then
    SetDefault('vid_pillarbox_pct', 17)
  else
    SetDefault('vid_pillarbox_pct', 0);
  if UseMouseCheckBox.Checked then
    SetDefault('mouse', 1)
  else
    SetDefault('mouse', 0);
  SetDefault('gameepisode', EpisodeRadioGroup.ItemIndex + 1);
  SetDefault('mousesensitivity', SensitivityTrackBar.Position);
  SetDefault('mousesensitivityx', SensitivityXTrackBar.Position);
  SetDefault('mousesensitivityy', SensitivityYTrackBar.Position);
end;

procedure TForm1.ScreenblocksTrackBarChange(Sender: TObject);
begin
  FromControls;
end;

procedure TForm1.DetailCheckBoxClick(Sender: TObject);
begin
  FromControls;
end;

procedure TForm1.SmoothDisplayCheckBoxClick(Sender: TObject);
begin
  FromControls;
end;

procedure TForm1.SFXTrackBarChange(Sender: TObject);
begin
  FromControls;
end;

procedure TForm1.MusicTrackBarChange(Sender: TObject);
begin
  FromControls;
end;

procedure TForm1.ChannelsTrackBarChange(Sender: TObject);
begin
  FromControls;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  weret: integer;
  errmsg: string;
  cmdline: string;
begin
  FromControls;
  defaults.SaveToFile('xGreed.ini');
  cmdline := 'xGreed.exe';
  if SkipIntroCheckBox.Checked then
    cmdline := cmdline + ' nointro';
  if EpisodeRadioGroup.ItemIndex = 1 then
    cmdline := cmdline + ' game2'
  else if EpisodeRadioGroup.ItemIndex = 2 then
    cmdline := cmdline + ' game3'
  else
    cmdline := cmdline + ' game1';
  weret := WinExec(PChar(cmdline), SW_SHOWNORMAL);
  if weret > 31 then
    Close
  else
  begin
    if weret = 0 then
      errmsg := 'The system is out of memory or resources.'
    else if weret = ERROR_BAD_FORMAT then
      errmsg := 'The "xGreed.exe" file is invalid (non-Win32 .EXE or error in .EXE image).'
    else if weret = ERROR_FILE_NOT_FOUND then
      errmsg := 'The "xGreed.exe" file was not found.'
    else if weret = ERROR_PATH_NOT_FOUND then
      errmsg := 'Path not found.'
    else
      errmsg := 'Can not run "xGreed.exe".';

    ShowMessage(errmsg);
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  FromControls;
  defaults.SaveToFile('xGreed.ini');
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.AutorunModeCheckBoxClick(Sender: TObject);
begin
  FromControls;
end;

end.

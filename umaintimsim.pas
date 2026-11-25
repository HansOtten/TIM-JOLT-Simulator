unit umaintimsim;
{
  Last update Hans Otten,March 2026

  MIT License

  Copyright (c) 2019, 2023 Hans Otten

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
  }


{ Handle TIM  }

{$mode objfpc}{$H+}                                                

interface

uses
   Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
   ExtCtrls, LCLtype, Menus, FileUtil, LCLIntf, LazSerial,IniFiles ;
  { you can add units after this }

  const
    version = 'TIM Superjolt Simulator V0.10.2 © Hans Otten, 2026' ;
    maxbuf  = 64 ; {maximum number of multiparts in file }

  type
  { TfTIMSIM }
  TfTIMSIM = class(TForm)
    bReset: TButton;
    bNMI: TButton;
    bIRQ: TButton;
    Image1: TImage;
    istop: TImage;
    Irun: TImage;
    ImagePB7on: TImage;
    ImagePA5off: TImage;
    ImagePB0off: TImage;
    ImagePB4SwOn: TImage;
    ImagePB0SwOff: TImage;
    ImagePB1SwOn: TImage;
    ImagePB2SwOff: TImage;
    ImagePB2SwOn: TImage;
    ImagePB1SwOff: TImage;
    ImagePB0SwOn: TImage;
    ImagePB3SwOff: TImage;
    ImagePB4SwOff: TImage;
    ImagePB6SwOff: TImage;
    ImagePB5SwOff: TImage;
    ImagePB7SwOff: TImage;
    ImagePB4off: TImage;
    ImagePB3on: TImage;
    ImagePB5on: TImage;
    ImagePB1off: TImage;
    ImagePB2off: TImage;
    ImagePB6on: TImage;
    ImagePB3off: TImage;
    ImagePB5off: TImage;
    ImagePB6off: TImage;
    ImagePB7off: TImage;
    ImagePB1on: TImage;
    ImagePB0on: TImage;
    ImagePB2on: TImage;
    ImagePB7SwOn: TImage;
    ImagePB5SwOn: TImage;
    ImagePB6SwOn: TImage;
    ImagePB3SwOn: TImage;
    ImagePB4on: TImage;
    ImagePA6SwOn: TImage;
    ImagePA2SwOn: TImage;
    ImagePA7SwOn: TImage;
    ImagePA5SwOn: TImage;
    ImagePA4SwOff: TImage;
    ImagePA7SwOff: TImage;
    ImagePA5SwOff: TImage;
    ImagePA6SwOff: TImage;
    ImagePA5on: TImage;
    ImagePA3SwOff: TImage;
    ImagePA0on: TImage;
    ImagePA3off: TImage;
    ImagePA2on: TImage;
    ImagePA2off: TImage;
    ImagePA6on: TImage;
    ImagePA4off: TImage;
    ImagePA0SwOn: TImage;
    ImagePA7off: TImage;
    ImagePA1off: TImage;
    ImagePA0off: TImage;
    ImagePA6off: TImage;
    ImagePA7on: TImage;
    ImagePA1on: TImage;
    ImagePA3on: TImage;
    ImagePA4on: TImage;
    ImagePA0SwOff: TImage;
    ImagePA1SwOn: TImage;
    ImagePA2SwOff: TImage;
    ImagePA4SwOn: TImage;
    ImagePA1SwOff: TImage;
    ImagePA3SwOn: TImage;
    Serialport: TLazSerial;
    lsuperjolt: TLabel;
    lpabnumbers1: TStaticText;
    LPB: TStaticText;
    MainMenu: TMainMenu;
    MenuAbout: TMenuItem;
    MenuFile: TMenuItem;
    menuHelp: TMenuItem;
    MDebugger: TMenuItem;
    mwf: TMenuItem;
    MStop: TMenuItem;
    MRun: TMenuItem;
    MWsettings: TMenuItem;
    MenuWindows: TMenuItem;
    MCheckforUpdate: TMenuItem;
    mSettings: TMenuItem;
    MTIMmanual: TMenuItem;
    mwconsole: TMenuItem;
    mwfilesave: TMenuItem;
    Mwsymboltable: TMenuItem;
    mprofiler: TMenuItem;
    Mwwatch: TMenuItem;
    Mwdebugger: TMenuItem;
    mHelpfile: TMenuItem;
    mloadtext: TMenuItem;
    msavetext: TMenuItem;
    mstopsavetext: TMenuItem;
    MFileLoad: TMenuItem;
    MFileSave: TMenuItem;
    MenuSimulator: TMenuItem;
    MExit: TMenuItem;
    MReset: TMenuItem;
    DialogOpenTextfile: TOpenDialog;
    OpenDialogBin: TOpenDialog;
    OpenDialogHEX: TOpenDialog;
    OpenDialog3Papertape: TOpenDialog;
    DialogSaveText: TSaveDialog;
    SaveDialogBIN: TSaveDialog;
    SaveDialogHEX: TSaveDialog;
    SaveDialogPapertape: TSaveDialog;
    Mdebug: TMenuItem;
    LPA: TStaticText;
    lpabnumbers: TStaticText;
    SelectDefaultDirectoryDialog: TSelectDirectoryDialog;
    lrunstop: TStaticText;
    tty_switch: TSpeedButton;
    procedure AboutClick(Sender: TObject);
    procedure bIRQClick(Sender: TObject);
    procedure bNMIClick(Sender: TObject);
    procedure bResetClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure ImagePA0SwOffClick(Sender: TObject);
    procedure ImagePA0SwOnClick(Sender: TObject);
    procedure ImagePA1SwOffClick(Sender: TObject);
    procedure ImagePA1SwOnClick(Sender: TObject);
    procedure ImagePA2SwOffClick(Sender: TObject);
    procedure ImagePA2SwOnClick(Sender: TObject);
    procedure ImagePA3SwOffClick(Sender: TObject);
    procedure ImagePA3SwOnClick(Sender: TObject);
    procedure ImagePA4SwOffClick(Sender: TObject);
    procedure ImagePA4SwOnClick(Sender: TObject);
    procedure ImagePA5SwOffClick(Sender: TObject);
    procedure ImagePA5SwOnClick(Sender: TObject);
    procedure ImagePA6SwOffClick(Sender: TObject);
    procedure ImagePA6SwOnClick(Sender: TObject);
    procedure ImagePA7SwOffClick(Sender: TObject);
    procedure ImagePA7SwOnClick(Sender: TObject);
    procedure ImagePB0SwOffClick(Sender: TObject);
    procedure ImagePB0SwOnClick(Sender: TObject);
    procedure ImagePB1SwOffClick(Sender: TObject);
    procedure ImagePB1SwOnClick(Sender: TObject);
    procedure ImagePB2SwOffClick(Sender: TObject);
    procedure ImagePB2SwOnClick(Sender: TObject);
    procedure ImagePB3SwOffClick(Sender: TObject);
    procedure ImagePB3SwOnClick(Sender: TObject);
    procedure ImagePB4SwOffClick(Sender: TObject);
    procedure ImagePB4SwOnClick(Sender: TObject);
    procedure ImagePB5SwOffClick(Sender: TObject);
    procedure ImagePB5SwOnClick(Sender: TObject);
    procedure ImagePB6SwOffClick(Sender: TObject);
    procedure ImagePB6SwOnClick(Sender: TObject);
    procedure ImagePB7SwOffClick(Sender: TObject);
    procedure ImagePB7SwOnClick(Sender: TObject);
    procedure ImgMOSClick(Sender: TObject);
    procedure IrunClick(Sender: TObject);
    procedure istopClick(Sender: TObject);
    procedure lsuperjoltClick(Sender: TObject);
    procedure MCheckforUpdateClick(Sender: TObject);
    procedure MDebuggerClick(Sender: TObject);
    procedure MdefaultworkdirectoryClick(Sender: TObject);
    procedure menuAboutClick(Sender: TObject);
    procedure MExitClick(Sender: TObject);
    procedure MdebugClick(Sender: TObject);
    procedure MFileLoadClick(Sender: TObject);
    procedure MFileSaveClick(Sender: TObject);
    procedure mHelpfileClick(Sender: TObject);
    procedure MTIMmanualClick(Sender: TObject);
    procedure mloadtextClick(Sender: TObject);
    procedure mprofilerClick(Sender: TObject);
    procedure MResetClick(Sender: TObject);
    procedure mrriotClick(Sender: TObject);
    procedure MRunClick(Sender: TObject);
    procedure msavetextClick(Sender: TObject);
    procedure mSettingsClick(Sender: TObject);
    procedure MStopClick(Sender: TObject);
    procedure mstopsavetextClick(Sender: TObject);
    procedure mtapesaveClick(Sender: TObject);
    procedure mwconsoleClick(Sender: TObject);
    procedure MwdebuggerClick(Sender: TObject);
    procedure mwfileloadClick(Sender: TObject);
    procedure mwfilesaveClick(Sender: TObject);
    procedure MwsymboltableClick(Sender: TObject);
    procedure MwwatchClick(Sender: TObject);
    procedure SerialportRxData(Sender: TObject);

  private

  public

  end;


type
  tbreaksetting = (normal,focal) ;

var
  fTIMSIM: TfTIMSIM ;

  SerialOut   : boolean ;   { if false concole used }
  SSTon       : boolean ;
  Addressmode : boolean ;


  SaveTextFile     : file of byte ;
  LoadTextFilename,
  SaveTExtFilename : string ;
  SaveTextOpen     : boolean ;
  TIMkeypressed    : boolean ;
  ResetKeyPressed  : boolean ;
  NMIKeyPressed    : boolean ;
  Stoprunkey       : boolean ;
  breaksetting     : tbreaksetting ;


  procedure ShowPAleds(PAledstatus : integer) ;
  procedure ShowPBleds(PBledstatus : integer) ;
  function GetPAswitches : integer ;
  function GetPBswitches : integer ;
  procedure DoMessages ;

implementation
{$R *.lfm}

uses
   uconsole, u6502CPU, udebugwindow, uwatchbreak,uprofiler,
   usymboltable, utim, ufilesave, ufileload, usettings ;


procedure ShowPAleds(PAledstatus : integer) ;

begin
  with fTIMSIM do
    begin
      if (PAledstatus AND $01) <> 0
        then
          begin
            ImagePA0On.visible  := true ;
            ImagePA0Off.visible := false ;
          end
        else
          begin
            ImagePA0On.visible :=  false;
            ImagePA0Off.visible:=  true ;
          end ;
      if (PAledstatus AND $02) <> 0
        then
          begin
            ImagePA1On.visible  := true ;
            ImagePA1Off.visible := false ;
          end
        else
          begin
            ImagePA1On.visible :=  false;
            ImagePA1Off.visible:=  true ;
          end ;
      if (PAledstatus AND $04) <> 0
        then
          begin
            ImagePA2On.visible  := true ;
            ImagePA2Off.visible := false ;
          end
        else
          begin
            ImagePA2On.visible :=  false;
            ImagePA2Off.visible:=  true ;
          end ;
      if (PAledstatus AND $08) <> 0
        then
          begin
            ImagePA3On.visible  := true ;
            ImagePA3Off.visible := false ;
          end
        else
          begin
            ImagePA3On.visible :=  false;
            ImagePA3Off.visible:=  true ;
          end ;
      if (PAledstatus AND $10) <> 0
        then
          begin
            ImagePA4On.visible  := true ;
            ImagePA4Off.visible := false ;
          end
        else
          begin
            ImagePA4On.visible :=  false;
            ImagePA4Off.visible:=  true ;
          end ;
      if (PAledstatus AND $20) <> 0
        then
          begin
            ImagePA5On.visible  := true ;
            ImagePA5Off.visible := false ;
          end
        else
          begin
            ImagePA5On.visible :=  false;
            ImagePA5Off.visible:=  true ;
          end ;
      if (PAledstatus AND $40) <> 0
        then
          begin
            ImagePA6On.visible  := true ;
            ImagePA6Off.visible := false ;
          end
        else
          begin
            ImagePA6On.visible :=  false;
            ImagePA6Off.visible:=  true ;
          end ;
      if (PAledstatus AND $80) <> 0
        then
          begin
            ImagePA7On.visible  := true ;
            ImagePA7Off.visible := false ;
          end
        else
          begin
            ImagePA7On.visible :=  false;
            ImagePA7Off.visible:=  true ;
          end ;
    end ;
end ;


procedure ShowPBleds(PBledstatus : integer) ;

begin
  with fTIMSIM do
    begin
      if (PBledstatus AND $01) <> 0
        then
          begin
            ImagePB0On.visible  := true ;
            ImagePB0Off.visible := false ;
          end
        else
          begin
            ImagePB0On.visible :=  false;
            ImagePB0Off.visible:=  true ;
          end ;
      if (PBledstatus AND $02) <> 0
        then
          begin
            ImagePB1On.visible  := true ;
            ImagePB1Off.visible := false ;
          end
        else
          begin
            ImagePB1On.visible :=  false;
            ImagePB1Off.visible:=  true ;
          end ;
      if (PBledstatus AND $04) <> 0
        then
          begin
            ImagePB2On.visible  := true ;
            ImagePB2Off.visible := false ;
          end
        else
          begin
            ImagePB2On.visible :=  false;
            ImagePB2Off.visible:=  true ;
          end ;
      if (PBledstatus AND $08) <> 0
        then
          begin
            ImagePB3On.visible  := true ;
            ImagePB3Off.visible := false ;
          end
        else
          begin
            ImagePB3On.visible :=  false;
            ImagePB3Off.visible:=  true ;
          end ;
      if (PBledstatus AND $10) <> 0
        then
          begin
            ImagePB4On.visible  := true ;
            ImagePB4Off.visible := false ;
          end
        else
          begin
            ImagePB4On.visible :=  false;
            ImagePB4Off.visible:=  true ;
          end ;
      if (PBledstatus AND $20) <> 0
        then
          begin
            ImagePB5On.visible  := true ;
            ImagePB5Off.visible := false ;
          end
        else
          begin
            ImagePB5On.visible :=  false;
            ImagePB5Off.visible:=  true ;
          end ;
      if (PBledstatus AND $40) <> 0
        then
          begin
            ImagePB6On.visible  := true ;
            ImagePB6Off.visible := false ;
          end
        else
          begin
            ImagePB6On.visible :=  false;
            ImagePB6Off.visible:=  true ;
          end ;
      if (PBledstatus AND $80) <> 0
        then
          begin
            ImagePB7On.visible  := true ;
            ImagePB7Off.visible := false ;
          end
        else
          begin
            ImagePB7On.visible :=  false;
            ImagePB7Off.visible:=  true ;
          end ;
    end ;
end ;

function GetPAswitches : integer ;
var
  stat : integer ;

begin
  with fTIMSIM do
    begin
      stat := 0 ;
      if ImagePA0SwOn.visible
        then
          stat := stat + $01 ;
      if ImagePA1SwOn.visible
        then
          stat := stat + $02 ;
      if ImagePA2SwOn.visible
        then
          stat := stat + $04 ;
      if ImagePA3SwOn.visible
        then
          stat := stat + $08 ;
      if ImagePA4SwOn.visible
        then
          stat := stat + $10 ;
      if ImagePA5SwOn.visible
        then
          stat := stat + $20 ;
      if ImagePA6SwOn.visible
        then
          stat := stat + $40 ;
      if ImagePA7SwOn.visible
        then
          stat := stat + $80 ;
    end ;
   GetPAswitches := stat ;
end ;

function GetPBswitches : integer ;

var
  stat : integer ;

begin
  with fTIMSIM do
    begin
      stat := 0 ;
      if ImagePB0SwOn.visible
        then
          stat := stat + $01 ;
      if ImagePB1SwOn.visible
        then
          stat := stat + $02 ;
      if ImagePB2SwOn.visible
        then
          stat := stat + $04 ;
      if ImagePB3SwOn.visible
        then
          stat := stat + $08 ;
      if ImagePB4SwOn.visible
        then
          stat := stat + $10 ;
      if ImagePB5SwOn.visible
        then
          stat := stat + $20 ;
      if ImagePB6SwOn.visible
        then
          stat := stat + $40 ;
      if ImagePB7SwOn.visible
        then
          stat := stat + $80 ;
    end ;
  GetPBswitches := stat ;
end;

procedure PAPABledswitchesOff ;

begin
  with fTIMSIM do
    begin
      ImagePA0SwOff.visible := true ;
      ImagePA1SwOff.visible := true ;
      ImagePA2SwOff.visible := true ;
      ImagePA3SwOff.visible := true ;
      ImagePA4SwOff.visible := true ;
      ImagePA5SwOff.visible := true ;
      ImagePA6SwOff.visible := true ;
      ImagePA7SwOff.visible := true ;
      ImagePA0SwOn.visible := false ;
      ImagePA1SwOn.visible := false ;
      ImagePA2SwOn.visible := false ;
      ImagePA3SwOn.visible := false ;
      ImagePA4SwOn.visible := false ;
      ImagePA5SwOn.visible := false ;
      ImagePA6SwOn.visible := false ;
      ImagePA7SwOn.visible := false ;
      ImagePA0off.visible := true ;
      ImagePA1off.visible := true ;
      ImagePA2off.visible := true ;
      ImagePA3off.visible := true ;
      ImagePA4off.visible := true ;
      ImagePA5off.visible := true ;
      ImagePA6off.visible := true ;
      ImagePA7off.visible := true ;
      ImagePA0on.visible := false ;
      ImagePA1on.visible := false ;
      ImagePA2on.visible := false ;
      ImagePA3on.visible := false ;
      ImagePA4on.visible := false ;
      ImagePA5on.visible := false ;
      ImagePA6on.visible := false ;
      ImagePA7on.visible := false ;
      ImagePB0SwOff.visible := true ;
      ImagePB1SwOff.visible := true ;
      ImagePB2SwOff.visible := true ;
      ImagePB3SwOff.visible := true ;
      ImagePB4SwOff.visible := true ;
      ImagePB5SwOff.visible := true ;
      ImagePB6SwOff.visible := true ;
      ImagePB7SwOff.visible := true ;
      ImagePB0SwOn.visible := false ;
      ImagePB1SwOn.visible := false ;
      ImagePB2SwOn.visible := false ;
      ImagePB3SwOn.visible := false ;
      ImagePB4SwOn.visible := false ;
      ImagePB5SwOn.visible := false ;
      ImagePB6SwOn.visible := false ;
      ImagePB7SwOn.visible := false ;
      ImagePB0off.visible := true ;
      ImagePB0off.visible := true ;
      ImagePB2off.visible := true ;
      ImagePB3off.visible := true ;
      ImagePB4off.visible := true ;
      ImagePB5off.visible := true ;
      ImagePB6off.visible := true ;
      ImagePB7off.visible := true ;
      ImagePB0on.visible := false ;
      ImagePB1on.visible := false ;
      ImagePB2on.visible := false ;
      ImagePB3on.visible := false ;
      ImagePB4on.visible := false ;
      ImagePB5on.visible := false ;
      ImagePB6on.visible := false ;
      ImagePB7on.visible := false ;

   end ;

 end ;



procedure ResetKIMPressed ;

begin
end;

procedure NMIKIMPressed ;

begin

  NMIkeypressed := true ;
end;


procedure DoMessages ;

begin
  Application.ProcessMessages ;
end;


procedure TfTIMSIM.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction := caFree ;
  stoprun := true ;
  stoprunkey := true ;
end;

procedure TfTIMSIM.AboutClick(Sender: TObject);
begin
  ShowMessage(version) ;
end;

procedure TfTIMSIM.bIRQClick(Sender: TObject);
begin
  IRQ ;
end;

procedure TfTIMSIM.bNMIClick(Sender: TObject);
begin
  NMI6502 ;
end;

procedure TfTIMSIM.bResetClick(Sender: TObject);
begin
  Reset6502
end;

procedure TfTIMSIM.Button1Click(Sender: TObject);
begin
  SerialPort.ShowSetupDialog   ;
end;


procedure TfTIMSIM.FormCreate(Sender: TObject);
var
  configfile   : string ;
  Settings : TIniFile;
  DefaultDirectory : string ;
begin
  configfile := GetappConfigFile(false) ;
  Settings := TIniFile.Create(configfile);
  DefaultDirectory := Settings.ReadString('Defaults', 'Defaultdir', '') ;
  Settings.Free;
  SetCurrentDir(DefaultDirectory) ;
  borderIcons := [biSystemMenu,biMaximize] ;
  ResetTIM ;
  PAPABledswitchesOff ;
  Addressmode := true ;
  SSTon := false ;
  loadtextopen := false ;
  savetextopen := false ;
  ResetKeypressed := false ;
  NMIKeypressed := false ;
  Irun.visible := true ;
  Istop.visible := false ;
  fTIMSIM.caption := version ;
  SerialOut := false ;
end;


procedure TfTIMSIM.ImagePA0SwOffClick(Sender: TObject);
begin
  ImagePA0SwOff.visible := false ;
  ImagePA0SwOn.visible := true ;
end;

procedure TfTIMSIM.ImagePA0SwOnClick(Sender: TObject);
begin
  ImagePA0SwOff.visible := true ;
  ImagePA0SwOn.visible := false  ;
end;

procedure TfTIMSIM.ImagePA1SwOffClick(Sender: TObject);
begin
  ImagePA1SwOff.visible := false ;
  ImagePA1SwOn.visible := true ;
end;

procedure TfTIMSIM.ImagePA1SwOnClick(Sender: TObject);
begin
  ImagePA1SwOff.visible := true ;
  ImagePA1SwOn.visible := false  ;
end;

procedure TfTIMSIM.ImagePA2SwOffClick(Sender: TObject);
begin
  ImagePA2SwOff.visible := false ;
  ImagePA2SwOn.visible := true ;
end;

procedure TfTIMSIM.ImagePA2SwOnClick(Sender: TObject);
begin
  ImagePA2SwOff.visible := true ;
  ImagePA2SwOn.visible := false  ;
end;

procedure TfTIMSIM.ImagePA3SwOffClick(Sender: TObject);
begin
  ImagePA3SwOff.visible := false ;
  ImagePA3SwOn.visible := true ;
end;

procedure TfTIMSIM.ImagePA3SwOnClick(Sender: TObject);
begin
  ImagePA3SwOff.visible := true ;
  ImagePA3SwOn.visible := false  ;
end;

procedure TfTIMSIM.ImagePA4SwOffClick(Sender: TObject);
begin
  ImagePA4SwOff.visible := false ;
  ImagePA4SwOn.visible := true ;
end;

procedure TfTIMSIM.ImagePA4SwOnClick(Sender: TObject);
begin
  ImagePA4SwOff.visible := true ;
  ImagePA4SwOn.visible := false
end;

procedure TfTIMSIM.ImagePA5SwOffClick(Sender: TObject);
begin
  ImagePA5SwOff.visible := false ;
  ImagePA5SwOn.visible := true ;
end;

procedure TfTIMSIM.ImagePA5SwOnClick(Sender: TObject);
begin
  ImagePA5SwOff.visible := true ;
  ImagePA5SwOn.visible := false  ;
end;

procedure TfTIMSIM.ImagePA6SwOffClick(Sender: TObject);
begin
  ImagePA6SwOff.visible := false ;
  ImagePA6SwOn.visible := true ;
end;

procedure TfTIMSIM.ImagePA6SwOnClick(Sender: TObject);
begin
  ImagePA6SwOff.visible := true ;
  ImagePA6SwOn.visible := false  ;
end;

procedure TfTIMSIM.ImagePA7SwOffClick(Sender: TObject);
begin
  ImagePA7SwOff.visible := false ;
  ImagePA7SwOn.visible := true ;
end;

procedure TfTIMSIM.ImagePA7SwOnClick(Sender: TObject);
begin
  ImagePA7SwOff.visible := true ;
  ImagePA7SwOn.visible := false  ;
end;

procedure TfTIMSIM.ImagePB0SwOffClick(Sender: TObject);
begin
  ImagePB0SwOff.visible := false ;
  ImagePB0SwOn.visible := true ;
end;

procedure TfTIMSIM.ImagePB0SwOnClick(Sender: TObject);
begin
  ImagePB0SwOff.visible := true ;
  ImagePB0SwOn.visible := false
end;

procedure TfTIMSIM.ImagePB1SwOffClick(Sender: TObject);
begin
  ImagePB1SwOff.visible := false ;
  ImagePB1SwOn.visible := true
end;

procedure TfTIMSIM.ImagePB1SwOnClick(Sender: TObject);
begin
  ImagePB1SwOff.visible := true ;
  ImagePB1SwOn.visible := false
end;

procedure TfTIMSIM.ImagePB2SwOffClick(Sender: TObject);
begin
  ImagePB2SwOff.visible := false ;
  ImagePB2SwOn.visible := true ;
end;

procedure TfTIMSIM.ImagePB2SwOnClick(Sender: TObject);
begin
  ImagePB2SwOff.visible := true ;
  ImagePB2SwOn.visible := false
end;

procedure TfTIMSIM.ImagePB3SwOffClick(Sender: TObject);
begin
  ImagePB3SwOff.visible := false ;
  ImagePB3SwOn.visible := true ;
end;

procedure TfTIMSIM.ImagePB3SwOnClick(Sender: TObject);
begin
  ImagePB3SwOff.visible := true ;
  ImagePB3SwOn.visible := false
end;

procedure TfTIMSIM.ImagePB4SwOffClick(Sender: TObject);
begin
 ImagePB4SwOff.visible := false ;
 ImagePB4SwOn.visible := true ;
end;

procedure TfTIMSIM.ImagePB4SwOnClick(Sender: TObject);
begin
  ImagePB4SwOff.visible := true ;
  ImagePB4SwOn.visible := false
end;

procedure TfTIMSIM.ImagePB5SwOffClick(Sender: TObject);
begin
 ImagePB5SwOff.visible := false ;
 ImagePB5SwOn.visible := true ;
end;

procedure TfTIMSIM.ImagePB5SwOnClick(Sender: TObject);
begin
  ImagePB5SwOff.visible := true ;
  ImagePB5SwOn.visible := false
end;

procedure TfTIMSIM.ImagePB6SwOffClick(Sender: TObject);
begin
  ImagePB6SwOff.visible := false ;
  ImagePB6SwOn.visible := true ;
end;

procedure TfTIMSIM.ImagePB6SwOnClick(Sender: TObject);
begin
  ImagePB6SwOff.visible := true ;
  ImagePB6SwOn.visible := false
end;

procedure TfTIMSIM.ImagePB7SwOffClick(Sender: TObject);
begin
 ImagePB7SwOff.visible := false ;
 ImagePB7SwOn.visible := true ;
end;

procedure TfTIMSIM.ImagePB7SwOnClick(Sender: TObject);
begin
  ImagePB7SwOff.visible := true ;
  ImagePB7SwOn.visible := false

end;

procedure TfTIMSIM.ImgMOSClick(Sender: TObject);
var
  helpurl : string ;

  begin
    helpurl := 'http://retro.hansotten.nl/6502-sbc/kim-1-manuals-and-software/' ;
    {$IFDEF macos}
      OpenURL('file://' + StringReplace(helpurl, ' ', '%20', [rfReplaceAll])) ;
    {$ELSE}
      OpenURL(helpurl) ;
    {$ENDIF}
  end ;

procedure DoRun ;
var
  runcnt  : integer ;
begin
  with fTIMSIM do
  begin
  Irun.visible := false ;
  Istop.visible:= true ;
  stoprunkey := false ;
  Fdebugwindow.trun.visible := true ;
  PC := $7006 ;
  while not stoprunkey do
    begin
      for runcnt := 1 to 1000 do
        begin
          Onestep ;
          if Resetkeypressed
            then
              begin
                Resetkeypressed := false ;
                Reset6502 ;
              end;
          if NMIkeypressed
            then
              begin
                NMIkeypressed := false ;
                NMI6502 ;
              end;
        end;
      Application.ProcessMessages ;
    end;
  Irun.visible := true ;
  Istop.visible:= false ;
  Fdebugwindow.trun.visible := false ;
  end ;
end;

procedure TfTIMSIM.IrunClick(Sender: TObject);
begin
 DoRun ;
end;

procedure TfTIMSIM.istopClick(Sender: TObject);
begin
  Irun.visible := true ;
  Istop.visible:= false ;
  stoprunkey := true ;
end;

procedure TfTIMSIM.lsuperjoltClick(Sender: TObject);
begin

end;


procedure TfTIMSIM.MCheckforUpdateClick(Sender: TObject);
var
  helpurl : string ;

begin
  helpurl := 'http://retro.hansotten.nl/6502-sbc/6530-6532/tim-6530-004/tim-superjolt-simulator/' ;
  {$IFDEF macos}
    OpenURL('file://' + StringReplace(helpurl, ' ', '%20', [rfReplaceAll])) ;
  {$ELSE}
    OpenURL(helpurl) ;
  {$ENDIF}
end;

procedure TfTIMSIM.MDebuggerClick(Sender: TObject);
begin
  Fdebugwindow.visible := true ;
  Fdebugwindow.BringToFront ;
end;

procedure TfTIMSIM.MdefaultworkdirectoryClick(Sender: TObject);
var
  configfile   : string ;
  Settings : TIniFile;
begin
  if SelectDefaultDirectoryDialog.execute
    then
      begin
        ShowMessage('Default work folder set to '
                    + SelectDefaultDirectoryDialog.filename) ;
        SetCurrentDir( SelectDefaultDirectoryDialog.filename) ;
        configfile := GetappConfigFile(false) ;
        Settings := TIniFile.Create(configfile);
        Settings.WriteString('Defaults', 'Defaultdir',
                              SelectDefaultDirectoryDialog.filename) ;
        Settings.Free;
      end ;
end;

procedure TfTIMSIM.menuAboutClick(Sender: TObject);
begin
      ShowMessage(version)
end;




procedure TfTIMSIM.MExitClick(Sender: TObject);
begin
  stoprunkey := true ;
  stoprun := true ;
  Close ;
end;
procedure TfTIMSIM.MdebugClick(Sender: TObject);
begin
  Fdebugwindow.visible := true ;
  Fdebugwindow.BringToFront ;
end;

procedure TfTIMSIM.MFileLoadClick(Sender: TObject);
begin
  FFileLoad.visible := true ;
  FFileLoad.BringToFront ;
end;


procedure TfTIMSIM.MFileSaveClick(Sender: TObject);
begin
  FFileSave.visible := true ;
  FFileSave.BringToFront ;
end;

procedure TfTIMSIM.mHelpfileClick(Sender: TObject);

var
  helpurl : string ;

  begin
    helpurl := 'http://retro.hansotten.nl/6502-sbc/6530-6532/tim-6530-004/tim-superjolt-simulator/tim-simulator-documentation/' ;
    {$IFDEF macos}
      OpenURL('file://' + StringReplace(helpurl, ' ', '%20', [rfReplaceAll])) ;
    {$ELSE}
      OpenURL(helpurl) ;
    {$ENDIF}
   end;


procedure TfTIMSIM.MTIMmanualClick(Sender: TObject);
var
  helpurl : string ;

begin
  helpurl := 'http://retro.hansotten.nl/6502-sbc/6530-6532/tim-6530-004/' ;
  {$IFDEF macos}
    OpenURL('file://' + StringReplace(helpurl, ' ', '%20', [rfReplaceAll])) ;
  {$ELSE}
    OpenURL(helpurl) ;
  {$ENDIF}
 end;




procedure TfTIMSIM.mloadtextClick(Sender: TObject);
begin
  if LoadTextOpen
    then
      CloseFile(LoadTextfile) ;
  if DialogOpenTextfile.execute
    then
      begin
        LoadTextFilename := DialogOpenTextfile.filename ;
        try
          assignfile(LoadTextfile,LoadTextFilename) ;
        except
         on E: EInOutError do
           begin
             ShowMessage('Error opening '
                         + LoadTextFilename + ' '
                         + ' ' + E.Message);
             exit ;
           end
        end;
        reset(LoadTextfile) ;
        LoadTextOpen := true ;
        CRfound := false ;
        KeyAvailable := true ;
      end ;
end;

procedure TfTIMSIM.mprofilerClick(Sender: TObject);
begin
  Fprofiler.visible := true ;
  Fprofiler.setfocus ;
  windowstate := wsNormal ;
end;

procedure TfTIMSIM.MResetClick(Sender: TObject);
begin
  ResetTIM ;
  ResetSimulator ;
end;

procedure TfTIMSIM.mrriotClick(Sender: TObject);
begin
 {
  frriot.visible := true ;
  frriot.setfocus ;
  windowstate := wsNormal ;
}
end;

procedure TfTIMSIM.MRunClick(Sender: TObject);
begin
  DoRun ;
end;

procedure TfTIMSIM.msavetextClick(Sender: TObject);
var
  boxstyle,
  reply : integer ;
  question : Pchar ;

begin
    if SaveTextOpen
    then
      CloseFile(SaveTextfile) ;

    if DialogSaveText.execute
      then
        begin
          SaveTextFilename := DialogSaveText.filename ;
          if fileExists(SaveTextFilename)
            then
              begin
                BoxStyle := MB_ICONQUESTION + MB_YESNO;
                question := Pchar('Overwrite existing file ' +
                             SaveTextFilename + ' ?') ;
                Reply := Application.MessageBox(question, 'File exists',BoxStyle);
                if reply <> IDYES
                  then
                    exit
              end ;

          try
            assignfile(SaveTextfile,SaveTextFilename) ;
          except
           on E: EInOutError do
             begin
               ShowMessage('Error opening '
                           + SaveTextFilename + ' '
                           + ' ' + E.Message);
               exit ;
             end
          end;
          rewrite(SaveTextfile) ;
          SaveTextOpen := true ;
        end ;
 end;

procedure TfTIMSIM.mSettingsClick(Sender: TObject);
begin
  fsettings.visible := true ;
  fsettings.setfocus ;
end;

procedure TfTIMSIM.MStopClick(Sender: TObject);
begin
  Irun.visible := true ;
  Istop.visible:= false ;
  stoprunkey := true ;
end;

procedure TfTIMSIM.mstopsavetextClick(Sender: TObject);
begin
  if SaveTextOpen
    then
      begin
        closefile(Savetextfile) ;
        SaveTextOpen := false ;
      end;
end;

procedure TfTIMSIM.mtapesaveClick(Sender: TObject);
begin

end;

procedure TfTIMSIM.mwconsoleClick(Sender: TObject);
begin
  Fconsole.visible := true ;
  Fconsole.setfocus ;
  WindowState := wsNormal
end;



procedure TfTIMSIM.MwdebuggerClick(Sender: TObject);
begin
  Fdebugwindow.visible := true ;
  Fdebugwindow.setfocus ;
  WindowState := wsNormal ;
end;

procedure TfTIMSIM.mwfileloadClick(Sender: TObject);
begin
  ffileload.visible := true ;
  ffileload.setfocus ;
  WindowState := wsNormal ;
end;

procedure TfTIMSIM.mwfilesaveClick(Sender: TObject);
begin
  ffilesave.visible := true ;
  ffilesave.setfocus ;
  WindowState := wsNormal ;
end;


procedure TfTIMSIM.MwsymboltableClick(Sender: TObject);
begin
  Fsymboltable.visible := true ;
  Fsymboltable.setfocus ;
  WindowState := wsNormal ;
end;

procedure TfTIMSIM.MwwatchClick(Sender: TObject);
begin
  FwatchBreak.visible := true ;
  FwatchBreak.setfocus ;
  WindowState := wsNormal ;
end;

procedure TfTIMSIM.SerialportRxData(Sender: TObject);
var
  str : string ;
begin
  str := SerialPort.ReadData ;
  lastkey := str[1] ;
  KeyAvailable := true ;
  if lastkey = chr(3)
    then
      VT_Break := true ;
end;



end.


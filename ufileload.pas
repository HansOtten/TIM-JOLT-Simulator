unit ufileload;

{
  Last update Hans Otten, August 4 2023

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

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
   ExtCtrls, strutils, LCLtype, Menus, FileUtil, LCLIntf ;

type

  { Tffileload }

  Tffileload = class(TForm)
    bload: TButton;
    bclose: TButton;
    bmemory: TButton;
    bloadmemory: TButton;
    estartaddress: TEdit;
    eloadfilename: TEdit;
    Label1: TLabel;
    lstartaddress: TLabel;
    lfilename: TLabel;
    mstatus: TMemo;
    blbin: TRadioButton;
    blhex: TRadioButton;
    blintelhex: TRadioButton;
    blmotosrec: TRadioButton;
    blmospaper: TRadioButton;
    blapple1: TRadioButton;
    dialogFileLoad: TOpenDialog;
    blkimtape: TRadioButton;
    blPRGfile: TRadioButton;
    bltimtape: TRadioButton;
    rgtype: TRadioGroup;
    procedure bcloseClick(Sender: TObject);
    procedure blapple1Click(Sender: TObject);
    procedure blbinClick(Sender: TObject);
    procedure blhexClick(Sender: TObject);
    procedure blintelhexClick(Sender: TObject);
    procedure blkimtapeClick(Sender: TObject);
    procedure blloadClick(Sender: TObject);
    procedure blmospaperClick(Sender: TObject);
    procedure blmotosrecClick(Sender: TObject);
    procedure bloadClick(Sender: TObject);
    procedure blPRGfileClick(Sender: TObject);
    procedure bltimtapeClick(Sender: TObject);
    procedure bmemoryClick(Sender: TObject);
    procedure bloadmemoryClick(Sender: TObject);
    procedure FormClose(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

const
  maxbuf = 64 ; {maximum number of multiparts in file }
  CR = $0D ;
  LF = $0A ;

type
  Tbufferparts  = record
                   bufferstart : integer ;
                   bufferend   : integer ;
                 end;
  Tbufferpart   = array[1..maxbuf] of Tbufferparts ;

var
  ffileload: Tffileload;
  { multipart buffering }
  buffer        : array[0 .. $FFFF] of byte ;
  bufferparts   : Tbufferpart ;
  buffers_inuse : integer ;  { all buffers 1 .. buffers_inuse are in use }
  currentbuf    : integer ;
  buffercnt     : integer ;

  loadfile      : file of byte ; { savefile reused for parts }
  hloaded       : boolean ;
  exitreason    : string ;
  startaddress  : integer ;
  tapeID        : byte ;    { for KIM-1 tape files }

implementation

{$R *.lfm}

uses loadhexformats, utim, udebugwindow ;

var
  LoadFileOpen : boolean ;

function validatehexword(hexstring: string) : boolean ;

  var
    valid : boolean ;
    value : integer ;

  begin
      try
        begin
          value  := hex2dec(hexstring) ;
          valid := true ;
         end;
       except
         on E: EConvertError do
           valid := false ;
       end;
       if valid
         then
           valid := (value >= 0) and (value <= $FFFF) ;
       validatehexword := valid ;
  end ;

procedure Initbuffer ;

{ all buffers 1 .. buffers_inuse are in use, so zero but first }

var
  cnt : integer ;

begin
  buffers_inuse := 0 ;
  currentbuf := 1 ;
  for cnt := 1 to maxbuf do
    begin
      bufferparts[cnt].bufferstart := 0 ;
      bufferparts[cnt].bufferend := 0 ;
    end ;
end ;

procedure InitLoad ;

begin
  with ffileload do
  begin
    eloadfilename.text := '' ;
    estartaddress.text  := '0' ;
    TapeID := 0 ;
    dialogFileLoad.Filter := 'Binary Files|*.bin'  ;
    dialogFileLoad.filename := ''  ;
    blbin.Checked := true ;
    mstatus.Lines.clear ;
    startaddress := 0  ;
    LoadFileOpen := false ;
    Initbuffer ;
    hloaded := false ;
  end;
end;

{ Tffileload }

procedure Tffileload.bcloseClick(Sender: TObject);
begin
  ffileload.visible := false ;
  InitLoad ;
  Close ;
end;

procedure Tffileload.blbinClick(Sender: TObject);
begin
  dialogFileLoad.Filter :=  'Binary files|*.bin'
end;

procedure Tffileload.blhexClick(Sender: TObject);
begin
  dialogFileLoad.Filter :=  'Hex Files|*.hex'
end;

procedure Tffileload.blintelhexClick(Sender: TObject);
begin
  dialogFileLoad.Filter := 'Intel hex Files|*.ihex;*.hex'
end;

procedure Tffileload.blkimtapeClick(Sender: TObject);
begin
  dialogFileLoad.Filter := 'All Files|*.kim'
end;


procedure Tffileload.blmotosrecClick(Sender: TObject);
begin
  dialogFileLoad.Filter :=  'Srecord Files|*.srec'
end;
procedure Tffileload.blmospaperClick(Sender: TObject);
begin
  dialogFileLoad.Filter := 'All Files|*.pap;*.ptp'
end;

procedure Tffileload.blapple1Click(Sender: TObject);
begin
  dialogFileLoad.Filter := 'All Files|*.ahex'
end;

procedure Tffileload.blloadClick(Sender: TObject);
begin
  if eloadfilename.text <> ''
    then
      DialogFileLoad.filename :=  eloadfilename.text ;
  if DialogFileLoad.execute
    then
      eloadfilename.text := ExtractFilename(DialogFileLoad.filename) ;
end;

procedure Tffileload.bloadClick(Sender: TObject);
begin

  mstatus.lines.add('Load started') ;
  InitBuffer ;
  { check if loadfile and savefile can be opened }
  if loadfileopen
    then
      closefile(loadfile) ;

  if DialogFileLoad.filename = ''
    then
      begin
        ShowMessage('Missing name for file to load from') ;
        exit ;
      end
    else
      try
        assignfile(loadfile, DialogFileLoad.filename) ;
        reset(loadfile) ;
        loadfileopen := true ;
       except
         on E: EInOutError do
           begin
             ShowMessage('Error opening '
                         + DialogFileLoad.filename + ' '
                         + ' ' + E.Message);
             exit ;
           end
       end;

  startaddress := hex2dec(estartaddress.text) ;
  mstatus.lines.add('File to load : ' + DialogFileLoad.filename) ;

  if blbin.checked
    then
      mstatus.lines.add('Start address used for BIN ' + inttohex(startaddress, 4)) ;
  { convert file format }
  hloaded := false ;
  if blbin.checked then
    loadBINfile
  else if blPRGfile.checked then
      loadPRGfile
  else if blhex.checked then
    loadhexfile
  else if blintelhex.checked then
    loadIntelhexfile
  else if blmospaper.checked then
    loadMOSpapertape
  else if blmotosrec.checked then
    loadMotorolaSrec
  else if blapple1.checked then
    loadApple1Hex
  else if blkimtape.checked then
      loadKimtape
  else if bltimtape.checked then
      loadTIMpapertape ;
   if not hloaded
    then
      begin
        mstatus.lines.add('File is not a valid hex file, not loaded') ;
        mstatus.lines.add('Error is ' + exitreason) ;
        exit
      end ;

  if blPRGfile.checked
    then
      mstatus.lines.add('Start address from PRG file ' + inttohex(startaddress, 4)) ;
  for buffercnt := 1 to buffers_inuse do
    mstatus.lines.add('File part ' + inttostr(buffercnt) +
                      ' loaded, startaddress : $' +
                        inttohex(bufferparts[buffercnt].bufferstart,4) +
                       ' to $' +
                        inttohex(bufferparts[buffercnt].bufferend,4)
                        ) ;
   if LoadFileOpen
    then
       begin
        closefile(loadfile) ;
        LoadFileOpen := false ;
      end ;

end;

procedure Tffileload.blPRGfileClick(Sender: TObject);
begin
  begin
  dialogFileLoad.Filter :=  'PRG files|*.PRG'
end;
end;

procedure Tffileload.bltimtapeClick(Sender: TObject);
begin
  dialogFileLoad.Filter := 'TIM papertape|*.tim'
end;

procedure Tffileload.bmemoryClick(Sender: TObject);

var
  cnt       : integer ;
  buffercnt : integer ;
begin

  for buffercnt := 1 to buffers_inuse do
    for cnt := bufferparts[buffercnt].bufferstart to bufferparts[buffercnt].bufferend do
      memory[cnt] := buffer[cnt] ;
  mstatus.lines.add('Loaded in memory') ;
  udebugwindow.RefreshAll ;
end;

procedure Tffileload.bloadmemoryClick(Sender: TObject);
begin
  if eloadfilename.text <> ''
    then
      DialogFileLoad.filename :=  eloadfilename.text ;
  if DialogFileLoad.execute
    then
      eloadfilename.text := ExtractFilename(DialogFileLoad.filename) ;
end;

procedure Tffileload.FormClose(Sender: TObject);
begin
  InitLoad ;
end;

procedure Tffileload.FormCreate(Sender: TObject);
begin
  ShowInTaskBar := stAlways ;
  borderIcons := [biSystemMenu,biMaximize] ;
  InitLoad ;
end;

end.


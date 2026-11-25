unit ufilesave;

{
  Last update Hans Otten, August 1 2023

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
  ExtCtrls, strutils, LCLtype, Menus, FileUtil, LCLIntf  ;

type

  { Tffilesave }

  Tffilesave = class(TForm)
    bfilesave: TButton;
    bexit: TButton;
    bsavememory: TButton;
    edefinetype: TEdit;
    eend: TEdit;
    estartaddress: TEdit;
    esavefilename: TEdit;
    etapeID: TEdit;
    Lfilesave: TLabel;
    ldefinetype: TLabel;
    lend: TLabel;
    lstartaddress: TLabel;
    lsavetomemory: TLabel;
    ltapeID: TLabel;
    mstatus: TMemo;
    bsbin: TRadioButton;
    bshex: TRadioButton;
    bsintelhex: TRadioButton;
    bsmotosrec: TRadioButton;
    bsmospaper: TRadioButton;
    bsapple1: TRadioButton;
    bskimtape: TRadioButton;
    bsdefinetype: TRadioButton;
    bsPRGfile: TRadioButton;
    bstimtape: TRadioButton;
    RadioGroup1: TRadioGroup;
    DialogFileSave: TSaveDialog;
    procedure bexitClick(Sender: TObject);
    procedure bfilesaveClick(Sender: TObject);
    procedure bsapple1Click(Sender: TObject);
    procedure bsavememoryClick(Sender: TObject);
    procedure bsbinClick(Sender: TObject);
    procedure bsdefinetypeClick(Sender: TObject);
    procedure bshexClick(Sender: TObject);
    procedure bsintelhexClick(Sender: TObject);
    procedure bskimtapeClick(Sender: TObject);
    procedure bsmospaperClick(Sender: TObject);
    procedure bsmotosrecClick(Sender: TObject);
    procedure bsPRGfileClick(Sender: TObject);
    procedure bstimtapeClick(Sender: TObject);
    procedure esavefilenameEditingDone(Sender: TObject);
    procedure eendEditingDone(Sender: TObject);
    procedure estartaddressEditingDone(Sender: TObject);
    procedure etapeIDEditingDone(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

const

  linuxlocationhtml = '' ;
  maxbuf = 64 ; {maximum number of multiparts in file }
  CR = $0D ;
  LF = $0A ;
  defaultDefineByte = '.byte $'  ;

type

  Tbufferparts  = record
                   bufferstart : integer ;
                   bufferend   : integer ;
                 end;

  Tbufferpart   = array[1..maxbuf] of Tbufferparts ;


var
  ffilesave: Tffilesave;

  { multipart buffering }
  buffer        : array[0 .. $FFFF] of byte ;
  bufferparts   : Tbufferpart ;
  buffers_inuse : integer ;  { all buffers 1 .. buffers_inuse are in use }
  currentbuf    : integer ;
  buffercnt     : integer ;

  savefile     : file of byte ; { savefile reused for parts }
  SaveFilePath,
  SaveFileName,
  SaveFileExtension,
  FullSaveFileName : string ;   { multipart hex and bin files
                                  will have startaddress appended to name }

  SaveFileOpen : boolean ;

  saved        : boolean ;
  exitreason   : string ;


  startaddress : integer ;
  endaddress   : integer ;
  tapeID       : integer ;

implementation

uses

  savehexformats, utim, udebugwindow ;


{$R *.lfm}

{ Tffilesave }


procedure InitSave ;

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
    end;
   with ffilesave do
     begin
       esavefilename.text   := '' ;
       estartaddress.text  := '0' ;
       eend.text := '0' ;
       DialogFileSave.Filter := 'All Files|*.bin'  ;
       DialogFileSave.filename := ''  ;
       bsBIN.Checked := true ;
       mstatus.Lines.clear ;
       startaddress := 0  ;
       endaddress := 0 ;
       SaveFileOpen := false ;
       saved := false ;
       ltapeID.visible := false ;
       etapeID.visible := false ;
       etapeID.text := '0';
       ldefinetype.visible := false ;
       edefinetype.visible := false ;
       edefinetype.text := defaultDefineByte ;
     end ;
end ;

procedure SplitSaveFilename ;

var
  i : integer ;

begin
   with ffilesave do
   begin
     { split filename into two for multiple parts files }
     SaveFilePath      := ExtractFilePath(DialogFileSave.filename) ;
     FullSaveFileName  := ExtractFileName(DialogFileSave.filename) ;
     SaveFileExtension := ExtractFileExt(DialogFileSave.filename) ;

     SaveFileName := '' ;
     i := 1 ;
     while i < length(FullSaveFilename) do
       if FullSaveFileName[i] <> '.'
         then
           begin
             SaveFileName := SaveFileName +  FullSaveFileName[i] ;
             i := i + 1
           end
         else
           i := length(FullSaveFilename)  ;
    end ;
end;

procedure Tffilesave.bexitClick(Sender: TObject);
begin
  ffilesave.visible := false ;
  InitSave ;
  Close ;
end;

procedure Tffilesave.bfilesaveClick(Sender: TObject);

var
  cnt : integer ;
  boxstyle,
  reply : integer ;
    question : Pchar ;
begin
  if DialogFileSave.filename = ''
    then
      begin
        ShowMessage('Missing name for file to save into') ;
        exit ;
      end
  else if fileExists(DialogFileSave.filename)
    then
      begin
        BoxStyle := MB_ICONQUESTION + MB_YESNO;
        question := Pchar('Overwrite existing file ' +
                           DialogFileSave.filename + ' ?') ;
        Reply := Application.MessageBox(question, 'File exists',BoxStyle);
        if reply <> IDYES
          then
            exit
      end ;
  { check if acceptable memory selected }
  startaddress := hex2dec(estartaddress.text) ;
  endaddress := hex2dec(eend.text) ;
  if (endaddress = 0)
     then
       ShowMessage('Zero size, nothing to save')
  else if endaddress <= startaddress
     then
       ShowMessage('End address must be higher than start address')
  else
    begin
       mstatus.lines.add('File to save  : ' + DialogFileSave.filename) ;
       mstatus.lines.add('Start address : $' + inttohex(startaddress, 4)) ;
       mstatus.lines.add('End address   : $' + inttohex(endaddress, 4)) ;

       { fill buffer from memory }
       buffers_inuse := 1 ;
       bufferparts[1].bufferstart := startaddress ;
       bufferparts[1].bufferend := endaddress  ;
       for cnt := startaddress to endaddress do
         buffer[cnt] := memory[cnt] ;
       exitreason := '' ;
       saved := false ;
      if bsbin.checked then
        saveBINfile
      else if bsPRGfile.checked then
        savePRGfile
       else if bshex.checked then
         savehexfile
       else if bsintelhex.checked then
         saveIntelhexfile
       else if bsmospaper.checked then
         saveMOSpapertape
       else if bsTIMtape.checked then
         saveTIMpapertape
       else if bsmotosrec.checked then
         saveMotorolaSrec
       else if bsapple1.checked then
         saveApple1Hex
       else if bsKIMtape.checked then
         begin
           tapeID := hex2dec(etapeID.text) ;
           saveKIMtape(tapeID)  ;
         end
       else if bsdefinetype.checked then
         saveDefineType(edefinetype.text) ;
       mstatus.lines.add('Saved to: ' + DialogFileSave.filename) ;
    end ;
  if SaveFileOpen
    then
      begin
        CloseFile(savefile) ;
        SaveFileOpen := false ;
      end ;
end;

procedure Tffilesave.bsbinClick(Sender: TObject);
begin
   DialogFileSave.filter := 'Binary Files|*.bin' ;
end;

procedure Tffilesave.bsdefinetypeClick(Sender: TObject);
begin
  edefinetype.visible := true ;
  ldefinetype.visible := true ;
  DialogFileSave.filter :=  'ASM Files|*.asm' ;
end;

procedure Tffilesave.bshexClick(Sender: TObject);
begin
   DialogFileSave.filter :=  'Hex Files|*.hex' ;
end;

procedure Tffilesave.bsintelhexClick(Sender: TObject);
begin
  DialogFileSave.filter := 'Intel hex|*.ihex;*.hex' ;
end;

procedure Tffilesave.bskimtapeClick(Sender: TObject);
begin
    DialogFileSave.filter :=  'KIM tape|*.kim' ;
end;


procedure Tffilesave.bsmospaperClick(Sender: TObject);
begin
  DialogFileSave.filter := 'MOS Papertape Files|*.pap;*.ptp' ;
end;

procedure Tffilesave.bsmotosrecClick(Sender: TObject);
begin
  DialogFileSave.filter :=  'Srecord Files|*.srec'
end;

procedure Tffilesave.bsPRGfileClick(Sender: TObject);
begin
  DialogFileSave.filter :=  'PRG Files|*.prg'
end;

procedure Tffilesave.bstimtapeClick(Sender: TObject);
begin
    DialogFileSave.filter :=  'TIM papertape|*.tim' ;
end;

procedure Tffilesave.bsapple1Click(Sender: TObject);
begin
    DialogFileSave.filter :=  'Apple Hex|*.ahex' ;
end;


procedure Tffilesave.esavefilenameEditingDone(Sender: TObject);
begin
  if esavefilename.text <> ''
    then
      splitSaveFilename ;
end;

procedure Tffilesave.eendEditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if not validatehexword(dword, eend.text)
    then
      begin
        ShowMessage('Not a valid start address, must be hex 0 .. FFFF')  ;
        estartaddress.text := '' ;
      end;
end;

procedure Tffilesave.estartaddressEditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if not validatehexword(dword, estartaddress.text)
    then
      begin
        ShowMessage('Not a valid start address, must be hex 0 .. FFFF')  ;
        estartaddress.text := '' ;
      end;

end;

procedure Tffilesave.etapeIDEditingDone(Sender: TObject);
var
  dbyte : integer ;
begin
  dbyte := 0 ;
  if not ValidateHexByte(dbyte, etapeID.text)
    then
      begin
        ShowMessage('Tape address must be 00 - FF')  ;
        etapeID.text := '00' ;
      end;
end;

procedure Tffilesave.FormActivate(Sender: TObject);
begin
  SetFocus ;
end;

procedure Tffilesave.FormClose(Sender: TObject);
begin
  InitSave ;
end;

procedure Tffilesave.FormCreate(Sender: TObject);
begin
  ShowInTaskBar := stAlways ;
  borderIcons := [biSystemMenu,biMaximize] ;
  InitSave ;
end;


procedure Tffilesave.bsavememoryClick(Sender: TObject);
begin
  if esavefilename.text <> ''
    then
      DialogFileSave.filename :=  esavefilename.text ;
  if DialogFileSave.execute
    then
      esavefilename.text := ExtractFileName(DialogFileSave.filename) ;
  splitSaveFilename ;
end;


end.


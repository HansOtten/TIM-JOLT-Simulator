unit uprofiler;

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
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, DBGrids, Grids,
  StdCtrls, Menus;

type

  { TFprofiler }

  TFprofiler = class(TForm)
    bSaveProfiler: TButton;
    bexitprofiler: TButton;
    brefresh: TButton;
    bclearprofiler: TButton;
    cprofile: TCheckBox;
    gprofiler: TStringGrid;
    ProfilerSaveDialog: TSaveDialog;
    procedure bclearprofilerClick(Sender: TObject);
    procedure bexitprofilerClick(Sender: TObject);
    procedure brefreshClick(Sender: TObject);
    procedure bSaveProfilerClick(Sender: TObject);
    procedure cprofileChange(Sender: TObject);
    procedure cprofileClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  Fprofiler: TFprofiler;

const
  instructions : array[0..255] of string =
    ('BRK','ORA (zp,x)','','','TSB', 'ORA zp', 'ASL zp','RMB0',
     'PHP',     'ORA #','ASL A','','TSB abs' , 'ORA abs','ASL abs','BBR0',

     'BPL','ORA (zp),Y','ORA (zp)','','TRB zp','ORA zp,X','ASL zp,X','RMB1',
     'CLC','ORA abs,Y','INC a','','TRB abs', 'ORA abs,x','ASL abs,X', 'BBR1',

     'JSR', 'AND (zp,X)','','','BIT zp','AND zp','ROL zp', 'RMB2',
     'PLP','AND #','ROL A','','BIT abs','AND abs','ROL abs','BBR2',

     'BMI','AND (zp),Y','AND (d)','','BIT zp,X','AND zp,X','ROL zp,X','RMB3',
     'SEC','AND abs,Y','DEC A','','BIT abs,X','AND abs,X','ROL abs,X','BBR3',

     'RTI','EOR (zp,X)','','','','EOR zp','LSR zp','RMB4',
     'PHA','EOR #','LSR A','','JMP abs','EOR abs','LSR abs','BBR4',

     'BVC','EOR (zp),Y','','','','EOR zp,X','LSR zp,X','RMB5',
     'CLI','EOR abs,Y','PHY','','','EOR abs,X','LSR abs,X','BBR5',

     'RTS','ADC (zp),Y','','','STZ zp,X','ADC zp','ROR zp','RMB6',
     'PLA','ADC #','ROR A','','JMP (abs)','ADC abs','ROR abs','BBR6',

     'BVS','ADC (zp),Y','','STZ zp,X','ADC zp,X','ROR zp,X','','RMB7',
     'SEI','ADC abs,Y','PLY','','JMP (abs,X)','ADC abs,X','ROR abs,x','BBR7',

     'BRA','STA (zp),Y','STA (Zp)','','STY zp','STA zp','STX zp','SMB0',
     'DEY','BIT #','TXA','','STY abs','STA abs','STX abs','BBS0',

     'BCC','STA (zp),Y','STA (zp)','','STY zp,X','STA zp,X','STX zp,Y','SMB1',
     'TYA','STA abs,Y','TXS','','STZ abs','STA abs,x','STZ abs,X','BBS1',

     'LDY #','LDA (zp,X)','LDX #','','LDY zp','LDA zp','LDX zp','SMB2',
     'TAY','LDA #','TAX','','LDY abs','LDA abs','LDX abs','BBS2',

     'BCS','LDA (zp),Y','LDA (zp)','','LDY zp,X','LDA zp,X','LDY zp,Y','SMB3',
     'CLV','LDA abs,Y','TSX','','LYY abs,X','LDa abs,X','LDX abs,Y','BBS3',

     'CPY #','CMP (zp,X)','','','CPY zp','CMP zp','DEC zp','SMB4',
     'INY','CMP#','DEX','','CPY abs','CMP abs','DEC abs','BBS4',

     'BNE','CMP (zp),Y','CMP (zp)','','','CMP zp,X','DEC zp,X','SMB5',
     'CLD','CMP abs,Y','PHX','','','CMP abs,X','DEC abs,x','BBS5',

     'CPX #','SBC (zp,X','','','CPX zp','SBC zp','INC zp','SMB6',
     'INX','SBC #','NOP','','CPX abs','SBC abs','INC abs','BBS6',

     'BEQ','SBC (zp),Y','SBC (zp)','','','SBC zp,X','INC zp,X','SMB7',
     'SED','SBC abs,Y','PLX','','','SBC zp,X','INC zp,X','SMB7'
    ) ;

    { record opcode hit for profiling }


var
  doprofiler       : boolean ;
  profilerhits     : array[0 ..255] of int64 ;

procedure DoCheckprofiler(opcode : integer) ;

procedure Clearprofiler ;

implementation


{$R *.lfm}

{ TFprofiler }

procedure Clearprofiler ;
var
  cnt : integer ;
begin
  for cnt := 0 to 255 do
    profilerhits[cnt] := 0 ;
end ;

procedure DoCheckprofiler(opcode : integer) ;

begin
  if Doprofiler
    then
      inc(profilerhits[opcode]) ;
end ;


procedure FillHeaders ;
var
  colcnt,rowcnt: integer ;
begin
  for rowcnt := 1 to 16 do
    Fprofiler.gprofiler.cells[0,2*rowcnt -1] := '    ' + inttohex(16*(rowcnt -1),2) ;
  for colcnt := 1 to 16 do
    Fprofiler.gprofiler.cells[colcnt,0] := '    ' + inttohex((colcnt -1) ,2) ;
end;

procedure FillInstructions ;
var
  rowcnt, colcnt : integer ;
begin
  for rowcnt := 1 to 16 do
    for colcnt := 1 to 16 do
      begin
        Fprofiler.gprofiler.cells[colcnt,(2* rowcnt) -1] := instructions[colcnt - 1 + (rowcnt -1) * 16];
      end;
end;

procedure FillPRofiledata ;
var
  rowcnt, colcnt : integer ;
  hits : integer ;
begin
  for rowcnt := 1 to 16 do
    for colcnt := 1 to 16 do
      begin
        hits := profilerhits[(colcnt + (rowcnt -1) * 16) - 1] ;
        if hits > 0
          then
            Fprofiler.gprofiler.cells[colcnt,(2* rowcnt)] := inttostr(hits)
      end;
end;


procedure TFprofiler.FormActivate(Sender: TObject);
begin
  FillHeaders ;
  FillInstructions ;
  FillProfiledata ;
end;

procedure TFprofiler.FormCreate(Sender: TObject);
begin
    ShowInTaskBar := stAlways ;
    borderIcons := [biSystemMenu,biMaximize] ;
end;

procedure TFprofiler.bexitprofilerClick(Sender: TObject);
begin
  Fprofiler.visible := false ;
end;

procedure TFprofiler.bclearprofilerClick(Sender: TObject);
begin
    Clearprofiler ;
    FillPRofiledata ;
end;

procedure TFprofiler.brefreshClick(Sender: TObject);
begin
    FillProfiledata ;
end;

procedure TFprofiler.bSaveProfilerClick(Sender: TObject);
var
  hitcnt : integer ;
  profilerfile     : text ;
  mnemonic : string ;

begin
  { Open profiler data files *.CSV }
  ProfilerSaveDialog.filter := 'CSV profiler data|*.csv' ;
  if ProfilerSaveDialog.execute
    then
      begin
        try
          assignfile(profilerfile ,ProfilerSaveDialog.filename) ;
        except
         on E: EInOutError do
           begin
             ShowMessage('Error opening '
                         + ProfilerSaveDialog.filename + ' '
                         + ' ' + E.Message);
             exit ;
           end
        end;
        rewrite(profilerfile) ;
      end;

  { dump profiler data comma delimited'
   'instruction name', 'profiler hits' }
  for hitcnt := 0 to 255 do
    begin
      write(profilerfile,'"') ;
      mnemonic := instructions[hitcnt] ;
      if mnemonic = ''
        then
          mnemonic := 'Unknown' ;
      write(profilerfile, mnemonic) ;
      write(profilerfile,'","') ;
      write(profilerfile, inttostr(profilerhits[hitcnt])) ;
      writeln(profilerfile,'"') ;
    end;
    ShowMessage('Profiler data saved to '
                         + ProfilerSaveDialog.filename) ;
  CloseFile(profilerfile) ;
end;

procedure TFprofiler.cprofileChange(Sender: TObject);
begin

end;

procedure TFprofiler.cprofileClick(Sender: TObject);
begin
  if cprofile.checked
    then
      begin
        Doprofiler := true ;
        ClearProfiler
      end
    else
      Doprofiler := false
end;

end.


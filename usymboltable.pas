unit usymboltable ;

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
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  LCLProc, SynEdit ;

type

  { TFsymboltable }

  TFsymboltable = class(TForm)
    blsearch: TButton;
    bsymbolrefresh: TButton;
    bcleartable: TButton;
    elsearch: TEdit;
    Lsymbolname: TLabel;
    lsymboladdress: TLabel;
    memosymboltable: TSynEdit;
    procedure bcleartableClick(Sender: TObject);
    procedure blsearchClick(Sender: TObject);
    procedure bsymbolrefreshClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  end;

var
  Fsymboltable: TFsymboltable;

procedure ShowSymbolTable ;
procedure ClearSymboltable ;

implementation

uses
  udebugwindow ;


{$R *.lfm}

{ TFsymboltable }
procedure ShowSymbolTable ;

var
  cnt : integer ;
  sline : string ;

begin

  Fsymboltable.memosymboltable.clear ;
  for cnt := 0 to 65535 do
    begin
      if symbolTable[cnt] <> ''
        then
          begin
            sline := inttohex(cnt,4) + '      ' + symbolTable[cnt] ;
            Fsymboltable.memosymboltable.lines.add(sline) ;
          end;
    end;

end ;

procedure ClearSymbolTable ;

var
  cnt : integer ;
begin
  for cnt := 0 to $FFFF do
    symbolTable[cnt] := '' ;
end ;

procedure TFsymboltable.FormCreate(Sender: TObject);
begin
  ShowInTaskBar := stAlways ;
  borderIcons := [biSystemMenu,biMaximize] ;
  ShowSymbolTable ;
  memoSymboltable.gutter.visible := false ;
end;

procedure TFsymboltable.bsymbolrefreshClick(Sender: TObject);
begin
  ShowSymbolTable ;
end;

procedure TFsymboltable.FormActivate(Sender: TObject);
begin
  ShowSymbolTable ;
  memoSymboltable.gutter.visible := false ;
end;

procedure TFsymboltable.bcleartableClick(Sender: TObject);
begin
  ClearSymbolTable ;
  ShowSymbolTable ;
end;

procedure TFsymboltable.blsearchClick(Sender: TObject);
var
  nrline, posline : integer ;
begin
  for nrline := 0 to memosymboltable.lines.count do
    if pos(elsearch.text, memosymboltable.lines[nrline]) <> 0
      then
        begin
          posline := nrline ;
          memosymboltable.caretY := posline + 5 ;
          exit ;
        end;
end;


end.


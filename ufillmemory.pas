unit ufillmemory;
{
  Last update Hans Otten, October 4 2023

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
{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TFFillmemory }

  TFFillmemory = class(TForm)
    BFillClear: TButton;
    BFillMove: TButton;
    BStartFill: TButton;
    EFillbyte: TEdit;
    EFillEnd: TEdit;
    EFillStart: TEdit;
    LFillbyte: TLabel;
    LFillFrom: TLabel;
    LTo: TLabel;
    procedure BFillClearClick(Sender: TObject);
    procedure BFillMoveClick(Sender: TObject);
    procedure EFillbyteEditingDone(Sender: TObject);
    procedure EFillEndEditingDone(Sender: TObject);
    procedure EFillStartEditingDone(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  FFillmemory: TFFillmemory;

implementation

{$R *.lfm}

uses
  udebugwindow, utim ;

var
  FillStart,
  FillEnd    : integer ;
  FillByte   : byte ;


procedure ClearAll ;

begin
  with FFillmemory do
    begin
      EFillStart.text := '' ;
      FillStart := 0 ;
      EFillEnd.text := '' ;
      FillEnd := 0 ;
      EFillByte.text := '' ;
      FillByte := 0 ;
    end;
end;

{ TFFillmemory }

procedure TFFillmemory.BFillMoveClick(Sender: TObject);
var
  memcnt : integer ;
begin
  if (EFillStart.text = '') or (EFillEnd.text = '') or (EFillByte.text = '')
    then
      begin
        ShowMessage('Please fill in addresses and fill byte') ;
        exit
      end;
  if FillEnd < FillStart
    then
      begin
        ShowMessage('End address should be larger than start address') ;
        exit
      end;
  { fill fillbyte in memory}
  for memcnt := FillStart to FillEnd do
        memory[memcnt] := FillByte ;
  RefreshAll ;
  ShowMessage('Memory fill done') ;

end;

procedure TFFillmemory.EFillbyteEditingDone(Sender: TObject);
var
  dbyte : integer ;
begin
  dbyte := 0 ;
  if  EFillbyte.text <> ''
     then
       begin
         if ValidateHexByte(dbyte, EFillbyte.text)
           then
             Fillbyte := dbyte
           else
             begin
               ShowMessage('Hex byte or leave empty please' );
               EFillbyte.text :=  '' ;
            end;
       end;
end;

procedure TFFillmemory.BFillClearClick(Sender: TObject);
begin
  ClearAll
end;

procedure TFFillmemory.EFillEndEditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if EFillEnd.text <> ''
    then
      begin
        if ValidateHexWord(dword, EFillEnd.text)
          then
            FillEnd := dword
          else
            begin
              ShowMessage('Hex address please' );
              EFillEnd.text :=  ''
            end;
      end;
end;

procedure TFFillmemory.EFillStartEditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if EFillStart.text <> ''
    then
      begin
        if ValidateHexWord(dword, EFillStart.text)
          then
            FillStart := dword
          else
            begin
              ShowMessage('Hex address please' );
              EFillStart.text :=  ''
            end;
      end;
end;



procedure TFFillmemory.FormCreate(Sender: TObject);
begin
  ShowInTaskBar := stAlways ;
  ClearAll
end;




end.


unit umovecopymemory ;
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
  
  { TFMoveCopyMemory }

  TFMoveCopyMemory = class(TForm)
    BMoveClear: TButton;
    BStartMove: TButton;
    EMoveEnd: TEdit;
    EMoveTo: TEdit;
    EFillbyte: TEdit;
    EMoveStart: TEdit;
    LFillremark: TLabel;
    LMoveFrom: TLabel;
    LMoveTo: TLabel;
    LFillbyte: TLabel;
    LTo: TLabel;
    procedure BMoveClearClick(Sender: TObject);
    procedure BStartMoveClick(Sender: TObject);
    procedure EFillbyteEditingDone(Sender: TObject);
    procedure EMoveEndEditingDone(Sender: TObject);
    procedure EMoveStartEditingDone(Sender: TObject);
    procedure EMoveToEditingDone(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  FMoveCopyMemory: TFMoveCopyMemory;

implementation

{$R *.lfm}

{ TFMoveCopyMemory }

uses
  udebugwindow, utim ;

var
  MoveStart,
  MoveEnd,
  MoveTo     : integer ;
  FillByte   : byte ;


procedure ClearAll ;

begin
  with FMoveCopyMemory do
    begin
      EMoveStart.text := '' ;
      MoveStart := 0 ;
      EMoveEnd.text := '' ;
      MoveEnd := 0 ;
      EMoveTo.text := '' ;
      MoveTo := 0 ;
      EFillByte.text := '' ;
      FillByte := 0 ;
    end;
end;

procedure TFMoveCopyMemory.FormCreate(Sender: TObject);
begin
  ShowInTaskBar := stAlways ;
  ClearAll
end;

procedure TFMoveCopyMemory.FormActivate(Sender: TObject);
begin
  ClearAll ;
end;

procedure TFMoveCopyMemory.BMoveClearClick(Sender: TObject);
begin
  ClearAll ;
end;

procedure TFMoveCopyMemory.BStartMoveClick(Sender: TObject);
var
  {save temporary to buffer during move copy to prevent overwriting }
  buffer     : array[0.. $FFFF] of byte ;
  memcnt     : integer ;
  cnt        : integer ;
begin
  if (EMoveTo.text = '')  or (EMoveStart.text = '') or (EMoveEnd.text = '')
    then
      begin
        ShowMessage('Please fill in all addresses') ;
        exit
      end;
  if MoveEnd < MoveStart
    then
      begin
        ShowMessage('End address should be larger than start address') ;
        exit
      end;

  { move data to copy/move to buffer }
  for memcnt := MoveStart to MoveEnd do
    buffer[memcnt] := memory[memcnt] ;

  { fill fillbyte in memory}
  if EfillByte.text <> ''
    then
      for memcnt := MoveStart to MoveEnd do
        memory[memcnt] := FillByte ;

  { move data from buffer to To memory }
  cnt := 0 ;
  for memcnt :=  MoveStart to MoveEnd do
    begin
      memory[MoveTo + cnt] := buffer[memcnt] ;
      cnt := cnt + 1
    end;
  RefreshAll ;
  ShowMessage('Memory move/copy done') ;
end;

procedure TFMoveCopyMemory.EFillbyteEditingDone(Sender: TObject);
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

procedure TFMoveCopyMemory.EMoveEndEditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if EMoveEnd.text <> ''
    then
      begin
        if ValidateHexWord(dword, EMoveEnd.text)
          then
            MoveEnd := dword
          else
            begin
              ShowMessage('Hex address please' );
              EMoveEnd.text :=  ''
            end;
      end;
end;

procedure TFMoveCopyMemory.EMoveStartEditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if EMoveStart.text <> ''
    then
      begin
        if ValidateHexWord(dword, EMoveStart.text)
          then
            MoveStart := dword
          else
            begin
              ShowMessage('Hex address please' );
              EMoveStart.text :=  ''
            end;
      end;
end;

procedure TFMoveCopyMemory.EMoveToEditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if EMoveTo.text <> ''
    then
      begin
        if ValidateHexWord(dword, EMoveTo.text)
          then
            MoveTo := dword
          else
            begin
              ShowMessage('Hex address please' );
              EMoveTo.text :=  ''
            end;
      end;
end;



end.


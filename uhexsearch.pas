unit uhexsearch;
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

  { TFHexSearch }

  TFHexSearch = class(TForm)
    BStartHexSearch: TButton;
    BHexSearchClear: TButton;
    Ehexsearchbyte1: TEdit;
    Ehexsearchbyte2: TEdit;
    Ehexsearchbyte3: TEdit;
    EHexSearchStart: TEdit;
    EHexSearchEnd: TEdit;
    LTo: TLabel;
    LSearchhexfor: TLabel;
    LSearchmemory: TLabel;
    MhexSearch: TMemo;
    procedure BHexSearchClearClick(Sender: TObject);
    procedure BStartHexSearchClick(Sender: TObject);
    procedure Ehexsearchbyte1EditingDone(Sender: TObject);
    procedure Ehexsearchbyte2EditingDone(Sender: TObject);
    procedure Ehexsearchbyte3EditingDone(Sender: TObject);
    procedure EHexSearchEndEditingDone(Sender: TObject);
    procedure EHexSearchStartEditingDone(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  FHexSearch: TFHexSearch;

implementation

{$R *.lfm}

uses
  udebugwindow, utim ;

{ TFHexSearch }

var
  searchbyte1,
  searchbyte2,
  searchbyte3   : byte ;
  startsearch,
  endsearch     : integer ;
  dosearchbyte1,
  dosearchbyte2,
  dosearchbyte3 : boolean ;



procedure ClearSearch ;

begin
  with FHexSearch do
    begin
      searchbyte1 := 0 ;
      dosearchbyte1 := false ;
      Ehexsearchbyte1.text := '' ;
      searchbyte2 := 0 ;
      dosearchbyte2 := false ;
      Ehexsearchbyte2.text := '' ;
      searchbyte3 := 0 ;
      dosearchbyte3 := false ;
      Ehexsearchbyte3.text := '' ;
      startsearch := 0 ;
      EHexSearchStart.text := '' ;
      endsearch   := 0 ;
      EHexSearchEnd.text := '' ;
      MHexSearch.Clear ;
    end;
end;

procedure TFHexSearch.FormActivate(Sender: TObject);
begin
  ClearSearch ;
end;

procedure TFHexSearch.BHexSearchClearClick(Sender: TObject);
begin
    ClearSearch ;
end;

procedure TFHexSearch.BStartHexSearchClick(Sender: TObject);
var
  memcnt : integer ;
  found  : integer ;

  procedure addtosearchmemo ;

  begin
    MhexSearch.lines.add(inttohex(memcnt,4)) ;
    found := found + 1 ;
  end ;

begin
  found := 0 ;
  if not dosearchbyte1
    then
      begin
        ShowMessage('Nothing to search') ;
        exit
      end ;
  if endsearch < startsearch
    then
    begin
      ShowMessage('End address should be greater than start address') ;
      exit
    end ;
  { we have valid first search byte and valid address range }
  if dosearchbyte2
    then
      begin
        dec(endsearch) ;
        if dosearchbyte3
          then
            dec(endsearch) ;
      end;
  MhexSearch.lines.add('Searching for ' +
                        Ehexsearchbyte1.text + ' ' +
                        Ehexsearchbyte2.text + ' ' +
                        Ehexsearchbyte3.text ) ;
  for memcnt := startsearch to endsearch do
    begin
      if  memory[memcnt] = searchbyte1
        then
          if not dosearchbyte2
            then
                addtosearchmemo
            else
              if memory[memcnt + 1] = searchbyte2
                then
                  if not dosearchbyte3
                    then
                      addtosearchmemo
                    else
                       if memory[memcnt + 2] = searchbyte3
                        then
                          addtosearchmemo  ;
    end;
  if found > 0
    then
      MhexSearch.lines.add('Found ' + inttostr(found) + ' times')
    else
       MhexSearch.lines.add('Nothing found') ;

end ;

procedure TFHexSearch.Ehexsearchbyte1EditingDone(Sender: TObject);
var
  dbyte : integer ;
begin
  dbyte := 0 ;
  if  Ehexsearchbyte1.text <> ''
     then
       begin
         if ValidateHexByte(dbyte, Ehexsearchbyte1.text)
           then
             begin
               searchbyte1 := dbyte ;
               dosearchbyte1 := true ;
             end
           else
             begin
               ShowMessage('Hex byte or empty please' );
               Ehexsearchbyte1.text :=  '' ;
               dosearchbyte1 := false ;
            end;
       end;
end;


procedure TFHexSearch.Ehexsearchbyte2EditingDone(Sender: TObject);
var
  dbyte : integer ;
begin
  dbyte := 0 ;
  if  Ehexsearchbyte2.text <> ''
     then
       begin
         if ValidateHexByte(dbyte, Ehexsearchbyte2.text)
           then
             begin
               searchbyte2 := dbyte ;
               dosearchbyte2 := true ;
             end
           else
             begin
               ShowMessage('Hex byte or empty please' );
               Ehexsearchbyte2.text :=  '' ;
               dosearchbyte2 := false ;
            end;
       end;
end;

procedure TFHexSearch.Ehexsearchbyte3EditingDone(Sender: TObject);
var
  dbyte : integer ;
begin
  dbyte := 0 ;
  dosearchbyte3 := false ;
  if  Ehexsearchbyte3.text <> ''
     then
       begin
         if ValidateHexByte(dbyte, Ehexsearchbyte3.text)
           then
             begin
               searchbyte3 := dbyte ;
               dosearchbyte3 := true ;
             end
           else
             begin
               ShowMessage('Hex byte or empty please' );
               Ehexsearchbyte3.text :=  '' ;
               dosearchbyte3 := false ;
            end;
       end;
end;


procedure TFHexSearch.EHexSearchEndEditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if EHexSearchEnd.text <> ''
    then
      begin
        if ValidateHexWord(dword, EHexSearchEnd.text)
          then
            endsearch := dword
          else
            begin
              ShowMessage('Hex address please' );
              EHexSearchEnd.text :=  ''
            end;
      end;
end;

procedure TFHexSearch.EHexSearchStartEditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if EHexSearchStart.text <> ''
    then
      begin
        if ValidateHexWord(dword, EHexSearchStart.text)
          then
            startsearch := dword
          else
            begin
              ShowMessage('Hex address please' );
              EHexSearchStart.text :=  ''
            end;
      end;
end;

procedure TFHexSearch.FormCreate(Sender: TObject);
begin
  ShowInTaskBar := stAlways ;
  ClearSearch ;
end;

end.


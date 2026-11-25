unit usettings;

{ Last update Hans Otten, March 2026 }

{
  MIT License

  Copyright (c) 2019 Hans Otten

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
  ExtCtrls, inifiles, umaintimsim,lazserial ;

type

  { Tfsettings }

  Tfsettings = class(TForm)
    Bsetdefaultworkingdir: TButton;
    bexit: TButton;
    bsetupserialport: TButton;
    BUseSerialPort: TButton;
    SelectDefaultDirectoryDialog: TSelectDirectoryDialog;
    procedure bexitClick(Sender: TObject);
    procedure BsetdefaultworkingdirClick(Sender: TObject);
    procedure bsetupserialportClick(Sender: TObject);
    procedure BUseSerialPortClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;


const
  txtUSinternational = 'US International' ;
  txtGerman          = 'German' ;
  txtBelgiumFrench   = 'Belgium France' ;

var
  fsettings: Tfsettings;

implementation

{$R *.lfm}

uses uconsole ;

{ Tfsettings }

procedure Tfsettings.BsetdefaultworkingdirClick(Sender: TObject);
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
end ;

procedure Tfsettings.bsetupserialportClick(Sender: TObject);
begin
  fTIMSIM.SerialPort.ShowSetupDialog ;
end;

procedure Tfsettings.BUseSerialPortClick(Sender: TObject);
begin
  if SerialOut
    then
      begin
        fTIMSIM.SerialPort.Close ;
        SerialOut := false ;
        Fconsole.visible := true ;
        BUseSerialPort.caption := 'Use Serial Port'
      end
    else
      begin
        fTIMSIM.SerialPort.Open ;
        SerialOut := true ;
        Fconsole.visible := false ;
        BUseSerialPort.caption := 'Use Console'
      end;

end;


procedure Tfsettings.FormActivate(Sender: TObject);
begin

end;

procedure Tfsettings.FormCreate(Sender: TObject);
begin
  ShowInTaskBar := stAlways ;
  borderIcons := [biSystemMenu,biMaximize] ;

end;


procedure Tfsettings.bexitClick(Sender: TObject);
begin
  fsettings.visible := false ;
end;


end.


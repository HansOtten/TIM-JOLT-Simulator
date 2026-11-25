unit uwatchbreak;

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
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TFwatchBreak }

  TFwatchBreak = class(TForm)
    bclearRegisters: TButton;
    bexitwatch: TButton;
    bclearwatches: TButton;
    bclearbreaks: TButton;
    btracelogfolder: TButton;
    bviewpofiler: TButton;
    cbreak10: TCheckBox;
    ctrace: TCheckBox;
    cprofile: TCheckBox;
    cwatchregA: TCheckBox;
    cwatchregSP: TCheckBox;
    cwatchregX: TCheckBox;
    cwatchregY: TCheckBox;
    cbreak2: TCheckBox;
    cbreak3: TCheckBox;
    cbreak4: TCheckBox;
    cbreak5: TCheckBox;
    cbreak6: TCheckBox;
    cbreak7: TCheckBox;
    cbreak8: TCheckBox;
    cbreak9: TCheckBox;
    cwatch1: TCheckBox;
    cwatch10: TCheckBox;
    cbreak1: TCheckBox;
    cwatch2: TCheckBox;
    cwatch3: TCheckBox;
    cwatch4: TCheckBox;
    cwatch5: TCheckBox;
    cwatch6: TCheckBox;
    cwatch7: TCheckBox;
    cwatch8: TCheckBox;
    cwatch9: TCheckBox;
    ebreak10: TEdit;
    eregpointA: TEdit;
    eregpointSP: TEdit;
    eregpointX: TEdit;
    eregpointY: TEdit;
    ebreak2: TEdit;
    ebreak3: TEdit;
    ebreak4: TEdit;
    ebreak5: TEdit;
    ebreak6: TEdit;
    ebreak7: TEdit;
    ebreak8: TEdit;
    ebreak9: TEdit;
    ewatch1: TEdit;
    ewatch10: TEdit;
    ebreak1: TEdit;
    ewatch2: TEdit;
    ewatch3: TEdit;
    ewatch4: TEdit;
    ewatch5: TEdit;
    ewatch6: TEdit;
    ewatch7: TEdit;
    ewatch8: TEdit;
    ewatch9: TEdit;
    Label1: TLabel;
    lenabledregisters: TLabel;
    lwatchpoints: TLabel;
    lenabled: TLabel;
    lenabled1: TLabel;
    lwatches: TLabel;
    lwatches1: TLabel;
    DialogLogfiles: TSelectDirectoryDialog;
    procedure bclearbreaksClick(Sender: TObject);
    procedure bclearRegistersClick(Sender: TObject);
    procedure bclearwatchesClick(Sender: TObject);
    procedure bexitwatchClick(Sender: TObject);
    procedure btracelogfolderClick(Sender: TObject);
    procedure bviewpofilerClick(Sender: TObject);
    procedure cbreak10EditingDone(Sender: TObject);
    procedure cbreak1EditingDone(Sender: TObject);
    procedure cbreak2EditingDone(Sender: TObject);
    procedure cbreak3EditingDone(Sender: TObject);
    procedure cbreak4EditingDone(Sender: TObject);
    procedure cbreak5EditingDone(Sender: TObject);
    procedure cbreak6EditingDone(Sender: TObject);
    procedure cbreak7EditingDone(Sender: TObject);
    procedure cbreak8EditingDone(Sender: TObject);
    procedure cbreak9EditingDone(Sender: TObject);
    procedure cprofileChange(Sender: TObject);
    procedure ctraceChange(Sender: TObject);
    procedure ctraceClick(Sender: TObject);
    procedure cwatch10EditingDone(Sender: TObject);
    procedure cwatch1EditingDone(Sender: TObject);
    procedure cwatch2EditingDone(Sender: TObject);
    procedure cwatch3EditingDone(Sender: TObject);
    procedure cwatch4EditingDone(Sender: TObject);
    procedure cwatch5EditingDone(Sender: TObject);
    procedure cwatch6EditingDone(Sender: TObject);
    procedure cwatch7EditingDone(Sender: TObject);
    procedure cwatch8EditingDone(Sender: TObject);
    procedure cwatch9EditingDone(Sender: TObject);
    procedure cwatchregAEditingDone(Sender: TObject);
    procedure cwatchregSPEditingDone(Sender: TObject);
    procedure cwatchregXEditingDone(Sender: TObject);
    procedure cwatchregYEditingDone(Sender: TObject);
    procedure ebreak10EditingDone(Sender: TObject);
    procedure ebreak1EditingDone(Sender: TObject);
    procedure ebreak2EditingDone(Sender: TObject);
    procedure ebreak3EditingDone(Sender: TObject);
    procedure ebreak4EditingDone(Sender: TObject);
    procedure ebreak5EditingDone(Sender: TObject);
    procedure ebreak6EditingDone(Sender: TObject);
    procedure ebreak7EditingDone(Sender: TObject);
    procedure ebreak8EditingDone(Sender: TObject);
    procedure ebreak9EditingDone(Sender: TObject);
    procedure eregpointAEditingDone(Sender: TObject);
    procedure eregpointSPEditingDone(Sender: TObject);
    procedure eregpointXEditingDone(Sender: TObject);
    procedure eregpointYEditingDone(Sender: TObject);
    procedure ewatch1EditingDone(Sender: TObject);
    procedure ewatch10EditingDone(Sender: TObject);
    procedure ewatch2EditingDone(Sender: TObject);
    procedure ewatch3EditingDone(Sender: TObject);
    procedure ewatch4EditingDone(Sender: TObject);
    procedure ewatch5EditingDone(Sender: TObject);
    procedure ewatch6EditingDone(Sender: TObject);
    procedure ewatch7EditingDone(Sender: TObject);
    procedure ewatch8EditingDone(Sender: TObject);
    procedure ewatch9EditingDone(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  FwatchBreak: TFwatchBreak;

implementation

{$R *.lfm}

uses
  udebugwindow, uprofiler ;

{ TFwatchBreak }

procedure ResetRegistersform ;
begin
  with fWatchBreak do
    begin
      eregpointA.text  := '' ;
      eregpointX.text  := '' ;
      eregpointY.text  := '' ;
      eregpointSP.text := '' ;
      cwatchregA.state   := cbUnchecked ;
      cwatchregX.state   := cbUnchecked ;
      cwatchregY.state   := cbUnchecked ;
      cwatchregSP.state  := cbUnchecked ;
    end;
end;

procedure ResetWatchesform ;
begin
  with fWatchBreak do
    begin
      ewatch1.text  := '' ;
      ewatch2.text  := '' ;
      ewatch3.text  := '' ;
      ewatch4.text  := '' ;
      ewatch5.text  := '' ;
      ewatch6.text  := '' ;
      ewatch7.text  := '' ;
      ewatch8.text  := '' ;
      ewatch9.text  := '' ;
      ewatch10.text := '' ;
      cwatch1.state  := cbUnchecked ;
      cwatch2.state  := cbUnchecked ;
      cwatch3.state  := cbUnchecked ;
      cwatch4.state  := cbUnchecked ;
      cwatch5.state  := cbUnchecked ;
      cwatch6.state  := cbUnchecked ;
      cwatch7.state  := cbUnchecked ;
      cwatch8.state  := cbUnchecked ;
      cwatch9.state  := cbUnchecked ;
      cwatch10.state  := cbUnchecked ;
    end ;
end ;
procedure ResetBreakpointsform ;
begin
  with fWatchBreak do
    begin
     ebreak1.text  := '' ;
     ebreak2.text  := '' ;
     ebreak3.text  := '' ;
     ebreak4.text  := '' ;
     ebreak5.text  := '' ;
     ebreak6.text  := '' ;
     ebreak7.text  := '' ;
     ebreak8.text  := '' ;
     ebreak9.text  := '' ;
     ebreak10.text := '' ;
     cbreak1.state := cbUnchecked ;
     cbreak2.state := cbUnchecked ;
     cbreak3.state := cbUnchecked ;
     cbreak4.state := cbUnchecked ;
     cbreak5.state := cbUnchecked ;
     cbreak6.state := cbUnchecked ;
     cbreak7.state := cbUnchecked ;
     cbreak8.state := cbUnchecked ;
     cbreak9.state := cbUnchecked ;
     cbreak10.state := cbUnchecked ;
    end;
end ;

procedure TFwatchBreak.ebreak1EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak1.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak1.text)
         then
           breakpoint_list[1] := dword
         else
           begin
             ebreak1.text := '' ;
             breakpoint_list[1] := -1 ;
             cbreak1.State := cbUnChecked
           end
       end
     else
       breakpoint_list[1] := -1
end ;

procedure TFwatchBreak.ebreak2EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak2.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak2.text)
         then
           breakpoint_list[2] := dword
         else
           begin
             ebreak2.text := '' ;
             breakpoint_list[2] := -1 ;
             cbreak2.State := cbUnChecked
           end
       end
     else
       breakpoint_list[2] := -1
end ;

procedure TFwatchBreak.ebreak3EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak3.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak3.text)
         then
           breakpoint_list[3] := dword
         else
           begin
             ebreak3.text := '' ;
             breakpoint_list[3] := -1 ;
             cbreak3.State := cbUnChecked
           end
       end
     else
       breakpoint_list[3] := -1
end ;

procedure TFwatchBreak.ebreak4EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak4.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak4.text)
         then
           breakpoint_list[4] := dword
         else
           begin
             ebreak4.text := '' ;
             breakpoint_list[4] := -1 ;
             cbreak4.State := cbUnChecked
           end
       end
     else
       breakpoint_list[4] := -1
end ;

procedure TFwatchBreak.ebreak5EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak5.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak5.text)
         then
           breakpoint_list[5] := dword
         else
           begin
             ebreak5.text := '' ;
             breakpoint_list[5] := -1 ;
             cbreak5.State := cbUnChecked
           end
       end
     else
       breakpoint_list[5] := -1
end ;

procedure TFwatchBreak.ebreak6EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak6.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak6.text)
         then
           breakpoint_list[6] := dword
         else
           begin
             ebreak1.text := '' ;
             breakpoint_list[6] := -1 ;
             cbreak6.State := cbUnChecked
           end
       end
     else
       breakpoint_list[6] := -1
end ;

procedure TFwatchBreak.ebreak7EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak7.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak7.text)
         then
           breakpoint_list[7] := dword
         else
           begin
             ebreak7.text := '' ;
             breakpoint_list[7] := -1 ;
             cbreak7.State := cbUnChecked
           end
       end
     else
       breakpoint_list[7] := -1
end ;

procedure TFwatchBreak.ebreak8EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak8.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak8.text)
         then
           breakpoint_list[8] := dword
         else
           begin
             ebreak8.text := '' ;
             breakpoint_list[8] := -1 ;
             cbreak8.State := cbUnChecked
           end
       end
     else
       breakpoint_list[8] := -1
end ;

procedure TFwatchBreak.ebreak9EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak9.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak9.text)
         then
           breakpoint_list[9] := dword
         else
           begin
             ebreak9.text := '' ;
             breakpoint_list[9] := -1 ;
             cbreak9.State := cbUnChecked
           end
       end
     else
       breakpoint_list[9] := -1
end ;

procedure TFwatchBreak.eregpointAEditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatchregA.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexbyte(dword, eregpointA.text)
         then
           begin
             RegisterAwatch := dword ;
             RegisterAenabled := true ;
           end
         else
           begin
             eregpointA.text := '' ;
             RegisterAwatch := -1 ;
             cwatchregA.State := cbUnChecked
           end
       end
     else
     begin
       RegisterAwatch := -1 ; ;
       RegisterAenabled := false ;
      end
end ;

procedure TFwatchBreak.eregpointSPEditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatchregSP.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexbyte(dword, eregpointSP.text)
         then
           begin
             RegisterSPwatch := dword ;
             RegisterSPenabled := true ;
           end
         else
           begin
             eregpointSP.text := '' ;
             RegisterSpwatch := -1 ;
             cwatchregSP.State := cbUnChecked
           end
       end
     else
     begin
       RegisterSPwatch := -1 ; ;
       RegisterSPenabled := false ;
      end
end ;

procedure TFwatchBreak.eregpointXEditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatchregX.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexbyte(dword, eregpointX.text)
         then
           begin
             RegisterXwatch := dword ;
             RegisterXenabled := true ;
           end
         else
           begin
             eregpointX.text := '' ;
             RegisterXwatch := -1 ;
             cwatchregX.State := cbUnChecked
           end
       end
     else
       begin
         RegisterXwatch := -1 ; ;
         RegisterXenabled := false ;
        end


end ;

procedure TFwatchBreak.eregpointYEditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatchregY.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexbyte(dword, eregpointY.text)
         then
           begin
             RegisterYwatch := dword ;
             RegisterYenabled := true ;
           end
         else
           begin
             eregpointY.text := '' ;
             RegisterYwatch := -1 ;
             cwatchregY.State := cbUnChecked
           end
       end
     else
     begin
       RegisterYwatch := -1 ; ;
       RegisterYenabled := false ;
      end
end ;

procedure TFwatchBreak.ebreak10EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak10.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak10.text)
         then
           breakpoint_list[10] := dword
         else
           begin
             ebreak10.text := '' ;
             breakpoint_list[10] := -1 ;
             cbreak10.State := cbUnChecked
           end
       end
     else
       breakpoint_list[10] := -1
end ;


procedure TFwatchBreak.bexitwatchClick(Sender: TObject);
begin
  fwatchbreak.visible := false ;
end;

procedure TFwatchBreak.btracelogfolderClick(Sender: TObject);
begin
  if DialogLogfiles.execute
    then
      begin
        tracefiledir := DialogLogfiles.filename + PathDelim ;
      end;
end;

procedure TFwatchBreak.bviewpofilerClick(Sender: TObject);
begin
  Fprofiler.visible := true ;
end;

procedure TFwatchBreak.cbreak1EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak1.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak1.text)
         then
           breakpoint_list[1] := dword
         else
           begin
             ebreak1.text := '' ;
             breakpoint_list[1] := -1 ;
             cbreak1.State := cbUnChecked
           end
       end
     else
       breakpoint_list[1] := -1
end ;

procedure TFwatchBreak.cbreak2EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak2.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak2.text)
         then
           breakpoint_list[2] := dword
         else
           begin
             ebreak2.text := '' ;
             breakpoint_list[2] := -1 ;
             cbreak2.State := cbUnChecked
           end
       end
     else
       breakpoint_list[2] := -1
end ;

procedure TFwatchBreak.cbreak3EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak3.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak3.text)
         then
           breakpoint_list[3] := dword
         else
           begin
             ebreak3.text := '' ;
             breakpoint_list[3] := -1 ;
             cbreak3.State := cbUnChecked
           end
       end
     else
       breakpoint_list[3] := -1
end ;

procedure TFwatchBreak.cbreak4EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak4.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak4.text)
         then
           breakpoint_list[4] := dword
         else
           begin
             ebreak4.text := '' ;
             breakpoint_list[4] := -1 ;
             cbreak4.State := cbUnChecked
           end
       end
     else
       breakpoint_list[4] := -1
end ;

procedure TFwatchBreak.cbreak5EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak5.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak5.text)
         then
           breakpoint_list[5] := dword
         else
           begin
             ebreak5.text := '' ;
             breakpoint_list[5] := -1 ;
             cbreak5.State := cbUnChecked
           end
       end
     else
       breakpoint_list[5] := -1
end ;

procedure TFwatchBreak.cbreak6EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak1.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak6.text)
         then
           breakpoint_list[6] := dword
         else
           begin
             ebreak6.text := '' ;
             breakpoint_list[6] := -1 ;
             cbreak6.State := cbUnChecked
           end
       end
     else
       breakpoint_list[6] := -1
end ;

procedure TFwatchBreak.cbreak7EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak7.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak7.text)
         then
           breakpoint_list[7] := dword
         else
           begin
             ebreak7.text := '' ;
             breakpoint_list[7] := -1 ;
             cbreak7.State := cbUnChecked
           end
       end
     else
       breakpoint_list[7] := -1
end ;

procedure TFwatchBreak.cbreak8EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak8.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak8.text)
         then
           breakpoint_list[8] := dword
         else
           begin
             ebreak8.text := '' ;
             breakpoint_list[8] := -1 ;
             cbreak8.State := cbUnChecked
           end
       end
     else
       breakpoint_list[8] := -1
end ;

procedure TFwatchBreak.cbreak9EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak9.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak9.text)
         then
           breakpoint_list[9] := dword
         else
           begin
             ebreak9.text := '' ;
             breakpoint_list[9] := -1 ;
             cbreak9.State := cbUnChecked
           end
       end
     else
       breakpoint_list[9] := -1
end ;

procedure TFwatchBreak.cprofileChange(Sender: TObject);
begin
  if cprofile.checked
    then
      begin
        Clearprofiler ;
        DoProfiler := true ;
      end
    else
      DoProfiler := false ;
end;

procedure TFwatchBreak.ctraceChange(Sender: TObject);
  begin
    if tracefileopen
      then
        begin
          writeln(tracefile, 'Trace closed') ;
          closefile(tracefile);
          tracefileopen := false ;
        end;
    if ctrace.checked
      then
        OpenAndStartTrace
      else
  end;

procedure TFwatchBreak.ctraceClick(Sender: TObject);
begin

end;

procedure TFwatchBreak.cbreak10EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cbreak10.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ebreak10.text)
         then
           breakpoint_list[10] := dword
         else
           begin
             ebreak10.text := '' ;
             breakpoint_list[10] := -1 ;
             cbreak10.State := cbUnChecked
           end
       end
     else
       breakpoint_list[10] := -1
end ;

procedure TFwatchBreak.cwatch1EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatch1.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ewatch1.text)
         then
           begin
             watches_list[1] := dword ;
             watches_enabled := true
           end
         else
           begin
             ewatch1.text := '' ;
             watches_list[1] := -1 ;
             cwatch1.State := cbUnChecked
           end
       end
     else
       watches_list[1] := -1
end ;

procedure TFwatchBreak.cwatch2EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatch2.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ewatch2.text)
         then
           begin
             watches_list[2] := dword ;
             watches_enabled := true
           end
         else
           begin
             ewatch2.text := '' ;
             watches_list[2] := -1 ;
             cwatch2.State := cbUnChecked
           end
       end
     else
       watches_list[2] := -1
end ;

procedure TFwatchBreak.cwatch3EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatch3.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ewatch3.text)
         then
           begin
             watches_list[3] := dword ;
             watches_enabled := true
           end
         else
           begin
             ewatch3.text := '' ;
             watches_list[3] := -1 ;
             cwatch3.State := cbUnChecked
           end
       end
     else
       watches_list[1] := -1
end ;

procedure TFwatchBreak.cwatch4EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatch4.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ewatch4.text)
         then
           begin
             watches_list[4] := dword ;
             watches_enabled := true
           end
         else
           begin
             ewatch4.text := '' ;
             watches_list[4] := -1 ;
             cwatch4.State := cbUnChecked
           end
       end
     else
       watches_list[4] := -1
end ;

procedure TFwatchBreak.cwatch5EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatch5.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ewatch5.text)
         then
           begin
             watches_list[5] := dword ;
             watches_enabled := true
           end
         else
           begin
             ewatch5.text := '' ;
             watches_list[5] := -1 ;
             cwatch5.State := cbUnChecked
           end
       end
     else
       watches_list[5] := -1
end ;

procedure TFwatchBreak.cwatch6EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatch6.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ewatch6.text)
         then
           begin
             watches_list[6] := dword ;
             watches_enabled := true
           end
         else
           begin
             ewatch6.text := '' ;
             watches_list[6] := -1 ;
             cwatch6.State := cbUnChecked
           end
       end
     else
       watches_list[6] := -1
end ;

procedure TFwatchBreak.cwatch7EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatch7.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ewatch7.text)
         then
           begin
             watches_list[7] := dword ;
             watches_enabled := true
           end
         else
           begin
             ewatch7.text := '' ;
             watches_list[7] := -1 ;
             cwatch7.State := cbUnChecked
           end
       end
     else
       watches_list[1] := -1
end ;

procedure TFwatchBreak.cwatch8EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatch8.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ewatch8.text)
         then
           begin
             watches_list[8] := dword ;
             watches_enabled := true
           end
         else
           begin
             ewatch8.text := '' ;
             watches_list[8] := -1 ;
             cwatch8.State := cbUnChecked
           end
       end
     else
       watches_list[8] := -1
end ;

procedure TFwatchBreak.cwatch9EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatch9.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ewatch9.text)
         then
           begin
             watches_list[9] := dword ;
             watches_enabled := true
           end
         else
           begin
             ewatch9.text := '' ;
             watches_list[9] := -1 ;
             cwatch9.State := cbUnChecked
           end
       end
     else
       watches_list[9] := -1
end ;

procedure TFwatchBreak.cwatchregAEditingDone(Sender: TObject);
var
  dword : integer ;
begin
if cwatchregA.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexbyte(dword, eregpointA.text)
         then
           begin
             RegisterAwatch := dword ;
             RegisterAenabled := true ;
           end
         else
           begin
             eregpointA.text := '' ;
             RegisterAwatch := -1 ;
             cwatchregA.State := cbUnChecked
           end
       end
     else
     begin
       RegisterAwatch := -1 ; ;
       RegisterAenabled := false ;
      end
end ;

procedure TFwatchBreak.cwatchregSPEditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatchregSP.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexbyte(dword, eregpointSP.text)
         then
           begin
             RegisterSPwatch := dword ;
             RegisterSPenabled := true ;
           end
         else
           begin
             eregpointSP.text := '' ;
             RegisterSPwatch := -1 ;
             cwatchregSP.State := cbUnChecked
           end
       end
     else
     begin
       RegisterSPwatch := -1 ; ;
       RegisterSPenabled := false ;
      end
end ;

procedure TFwatchBreak.cwatchregXEditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatchregX.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexbyte(dword, eregpointX.text)
         then
           begin
             RegisterXwatch := dword ;
             RegisterXenabled := true ;
           end
         else
           begin
             eregpointX.text := '' ;
             RegisterXwatch := -1 ;
             cwatchregX.State := cbUnChecked
           end
       end
     else
     begin
       RegisterXwatch := -1 ; ;
       RegisterXenabled := false ;
      end
end ;

procedure TFwatchBreak.cwatchregYEditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatchregY.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexbyte(dword, eregpointY.text)
         then
           begin
             RegisterYwatch := dword ;
             RegisterYenabled := true ;
           end
         else
           begin
             eregpointY.text := '' ;
             RegisterYwatch := -1 ;
             cwatchregY.State := cbUnChecked
           end
       end
     else
     begin
       RegisterYwatch := -1 ; ;
       RegisterYenabled := false ;
      end
end ;


procedure TFwatchBreak.cwatch10EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  if cwatch10.State = cbChecked
    then
      begin
       dword := 0 ;
       if validatehexword(dword, ewatch10.text)
         then
           begin
             watches_list[10] := dword ;
             watches_enabled := true
           end
         else
           begin
             ewatch1.text := '' ;
             watches_list[10] := -1 ;
             cwatch10.State := cbUnChecked
           end
       end
     else
       watches_list[10] := -1
end ;


procedure TFwatchBreak.ewatch1EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if not validatehexword(dword, ewatch1.text)
    then
      begin
        ewatch1.text := '' ;
        watches_list[1] := -1 ;
        cwatch1.State := cbUnChecked
      end
    else if cwatch1.State = cbChecked
      then
        begin
          watches_list[1] := dword ;
          watches_enabled := true
        end
end;

procedure TFwatchBreak.ewatch2EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if not validatehexword(dword, ewatch2.text)
    then
      begin
        ewatch2.text := '' ;
        watches_list[2] := -1 ;
        cwatch2.State := cbUnChecked
      end
  else if cwatch2.State = cbChecked
    then
      begin
        watches_list[2] := dword ;
        watches_enabled := true
      end
end;

procedure TFwatchBreak.ewatch3EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if not validatehexword(dword, ewatch3.text)
    then
      begin
        ewatch3.text := '' ;
        watches_list[3] := -1 ;
        cwatch3.State := cbUnChecked
      end
  else if cwatch3.State = cbChecked
    then
      begin
        watches_list[3] := dword ;
        watches_enabled := true
      end
end;

procedure TFwatchBreak.ewatch4EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if not validatehexword(dword, ewatch4.text)
    then
      begin
        ewatch4.text := '' ;
        watches_list[4] := -1 ;
        cwatch4.State := cbUnChecked
      end
  else if cwatch4.State = cbChecked
    then
      begin
        watches_list[4] := dword ;
        watches_enabled := true
      end
end;

procedure TFwatchBreak.ewatch5EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if not validatehexword(dword, ewatch5.text)
    then
      begin
        ewatch5.text := '' ;
        watches_list[5] := -1 ;
        cwatch5.State := cbUnChecked
      end
  else if cwatch5.State = cbChecked
    then
      watches_list[5] := dword ;
end;

procedure TFwatchBreak.ewatch6EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if not validatehexword(dword, ewatch6.text)
    then
      begin
        ewatch6.text := '' ;
        watches_list[6] := -1 ;
        cwatch6.State := cbUnChecked
      end
  else if cwatch6.State = cbChecked
    then
      begin
        watches_list[6] := dword ;
        watches_enabled := true
      end
end;

procedure TFwatchBreak.ewatch7EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if not validatehexword(dword, ewatch7.text)
    then
      begin
        ewatch7.text := '' ;
        watches_list[7] := -1 ;
        cwatch7.State := cbUnChecked
      end
  else if cwatch7.State = cbChecked
    then
      begin
        watches_list[7] := dword ;
        watches_enabled := true
      end
end;

procedure TFwatchBreak.ewatch8EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if not validatehexword(dword, ewatch8.text)
    then
      begin
        ewatch8.text := '' ;
        watches_list[8] := -1 ;
        cwatch8.State := cbUnChecked
      end
  else if cwatch8.State = cbChecked
    then
      begin
        watches_list[8] := dword ;
        watches_enabled := true
      end
end;

procedure TFwatchBreak.ewatch9EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if not validatehexword(dword, ewatch9.text)
    then
      begin
        ewatch9.text := '' ;
        watches_list[9] := -1 ;
        cwatch9.State := cbUnChecked
      end
  else if cwatch9.State = cbChecked
    then
      begin
        watches_list[9] := dword ;
        watches_enabled := true
      end
end;

procedure TFwatchBreak.ewatch10EditingDone(Sender: TObject);
var
  dword : integer ;
begin
  dword := 0 ;
  if not validatehexword(dword, ewatch10.text)
    then
      begin
        ewatch10.text := '' ;
        watches_list[10] := -1 ;
        cwatch10.State := cbUnChecked
      end
  else if cwatch10.State = cbChecked
    then
      begin
        watches_list[10] := dword ;
        watches_enabled := true
      end
end;

procedure TFwatchBreak.FormActivate(Sender: TObject);
begin
  { form is shown, so fill values from arrays and variables }
  ResetRegistersform ;
  if RegisterAenabled
    then
      begin
        eregpointA.text := inttohex(RegisterAwatch,2) ;
        cwatchregA.state  := cbchecked ;
      end ;
  if RegisterXenabled
    then
      begin
        eregpointX.text := inttohex(RegisterAwatch,2) ;
        cwatchregX.state  := cbchecked ;
      end ;
  if RegisterAenabled
    then
      begin
        eregpointY.text := inttohex(RegisterAwatch,2) ;
        cwatchregY.state  := cbchecked ;
      end ;

  ResetWatchesform ;
  if watches_list[1] <> -1
    then
      begin
        ewatch1.text := inttohex(watches_list[1],4) ;
        cwatch1.state := cbChecked ;
      end;   ResetWatchesform ;
  if watches_list[1] <> -1
    then
      begin
        ewatch1.text := inttohex(watches_list[1],4) ;
        cwatch1.state := cbChecked ;
      end;

  if watches_list[2] <> -1
    then
      begin
        ewatch1.text := inttohex(watches_list[2],4) ;
        cwatch1.state := cbChecked ;
      end;
  if watches_list[3] <> -1
    then
      begin
        ewatch1.text := inttohex(watches_list[3],4) ;
        cwatch1.state := cbChecked ;
      end;
  if watches_list[4] <> -1
    then
      begin
        ewatch1.text := inttohex(watches_list[4],4) ;
        cwatch1.state := cbChecked ;
      end;
  if watches_list[5] <> -1
    then
      begin
        ewatch1.text := inttohex(watches_list[5],4) ;
        cwatch1.state := cbChecked ;
      end;
  if watches_list[6] <> -1
    then
      begin
        ewatch1.text := inttohex(watches_list[6],4) ;
        cwatch1.state := cbChecked ;
      end;
  if watches_list[7] <> -1
    then
      begin
        ewatch1.text := inttohex(watches_list[7],4) ;
        cwatch1.state := cbChecked ;
      end;
  if watches_list[8] <> -1
    then
      begin
        ewatch1.text := inttohex(watches_list[8],4) ;
        cwatch1.state := cbChecked ;
      end;
  if watches_list[9] <> -1
    then
      begin
        ewatch1.text := inttohex(watches_list[9],4) ;
        cwatch1.state := cbchecked ;
      end;
  if watches_list[10] <> -1
    then
      begin
        ewatch1.text := inttohex(watches_list[10],4) ;
        cwatch1.state := cbchecked ;
      end;

  ResetBreakpointsform ;
  if breakpoint_list[1] <> -1
    then
      begin
        ebreak1.text := inttohex(breakpoint_list[1],4) ;
        cbreak1.state := cbChecked ;
      end;
  if breakpoint_list[2] <> -1
    then
      begin
        ebreak1.text := inttohex(breakpoint_list[1],4) ;
        cbreak1.state := cbChecked ;
      end;
  if breakpoint_list[1] <> -1
    then
      begin
        ebreak1.text := inttohex(breakpoint_list[1],4) ;
        cbreak1.state := cbChecked ;
      end;
  if breakpoint_list[3] <> -1
    then
      begin
        ebreak1.text := inttohex(breakpoint_list[1],4) ;
        cbreak1.state := cbChecked ;
      end;
  if breakpoint_list[4] <> -1
    then
      begin
        ebreak1.text := inttohex(breakpoint_list[1],4) ;
        cbreak1.state := cbChecked ;
      end;
  if breakpoint_list[5] <> -1
    then
      begin
        ebreak1.text := inttohex(breakpoint_list[1],4) ;
        cbreak1.state := cbChecked ;
      end;
  if breakpoint_list[6] <> -1
    then
      begin
        ebreak1.text := inttohex(breakpoint_list[1],4) ;
        cbreak1.state := cbChecked ;
      end;
  if breakpoint_list[7] <> -1
    then
      begin
        ebreak1.text := inttohex(breakpoint_list[1],4) ;
        cbreak1.state := cbChecked ;
      end;
  if breakpoint_list[8] <> -1
    then
      begin
        ebreak1.text := inttohex(breakpoint_list[1],4) ;
        cbreak1.state := cbChecked ;
      end;
  if breakpoint_list[9] <> -1
    then
      begin
        ebreak1.text := inttohex(breakpoint_list[1],4) ;
        cbreak1.state := cbChecked ;
      end;
  if breakpoint_list[10] <> -1
    then
      begin
        ebreak1.text := inttohex(breakpoint_list[1],4) ;
        cbreak1.state := cbChecked ;
      end;
end;

procedure TFwatchBreak.FormCreate(Sender: TObject);
begin
  ShowInTaskBar := stAlways ;
  borderIcons := [biSystemMenu,biMaximize] ;
end;

procedure TFwatchBreak.bclearwatchesClick(Sender: TObject);
begin
  ResetWatches ;
  ResetWatchesform ;
end;

procedure TFwatchBreak.bclearbreaksClick(Sender: TObject);
begin
  ResetBreakpoints ;
  ResetBreakpointsform ;
end;

procedure TFwatchBreak.bclearRegistersClick(Sender: TObject);
begin
  ResetRegisterwatchpoints ;
  ResetRegistersform ;
end;

end.


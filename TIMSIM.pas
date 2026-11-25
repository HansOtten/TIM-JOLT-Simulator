program TIMSIM;

{
  Last update Hans Otten, November 2026

  MIT License

  Copyright (c) 2019, 2021 Hans Otten

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
  SOFTWARE

  }

{ TIM Simulator change log

V0.1 27 oktober 2023
V0.2 22 november 2023 file menu restored
V0.3 25 november 2023 console limited to ascii chars 32-126
v0.4 1 DECEMBER 2023 Forms on taskbar LH command works Tiny Basic works
V0.6 February 2024 Console updates, file open/save fullproof
v0.7 November 2024 Support ACIA ROM moved to F800.
Can now load KIM-5 Resident Asembler/Editor
V0.8 serial I/O besides console
V0.9 keyboard variants removed, OS delivers right key code
V0.10.2 November 2026 updated load/save, VT100 console
}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, LazSerialPort,
  { you can add units after this }
  umaintimsim, u6502cpu, uconsole, udebugwindow, udisassemble6502, utim,
  ufileload, ufilesave, savehexformats, loadhexformats, usymboltable,
  uwatchbreak, uprofiler, usettings ,
  uhexSearch, umovecopymemory, ufillmemory;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TfTIMSIM, fTIMSIM);
  Application.CreateForm(TFconsole, Fconsole);
  Application.CreateForm(TFdebugwindow, Fdebugwindow);
  Application.CreateForm(Tffileload, ffileload);
  Application.CreateForm(Tffilesave, ffilesave);
  Application.CreateForm(TFsymboltable, Fsymboltable);
  Application.CreateForm(TFwatchBreak, FwatchBreak);
  Application.CreateForm(TFprofiler, Fprofiler);
  Application.CreateForm(Tfsettings, fsettings);
  Application.CreateForm(TFHexSearch, FHexSearch);
  Application.CreateForm(TFMoveCopyMemory, FMoveCopyMemory);
  Application.CreateForm(TFFillmemory, FFillmemory);
  { Console: clear with the final colours and show it at startup }
  Reset_VT;
  Fconsole.Show;
  Application.Run;
end.


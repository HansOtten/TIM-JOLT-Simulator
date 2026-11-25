unit utim;

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

{ break and watch added }


{$DEFINE KIM1}
{ not DEFINE KIM1 replaces ReadMem and WriteMem with no KIM-1 register version
  for testing with 6502 tests }

{$mode objfpc}{$H+}

interface

uses

  Classes, SysUtils;

const

{ 6530 RRIOT 6530-004}

{ TIM memory layout
  87  6E00            IOBASE =$6E00
  88  6E00            MPA    =IOBASE+0
  89  6E01            MDA    =IOBASE+1
  90  6E02            MPB    =IOBASE+2
  91  6E03            MDB    =IOBASE+3
  92  6E04            MCLKIT =IOBASE+4
  93  6E04            MCLKRD =IOBASE+4
  94  6E05            MCLKIF =IOBASE+5
  95  FFF8            UINT   =$FFF8

  FFC0                RAM64  =$FFC0
  mapped in with PB4 after reset, at boot the ROM is at FFFF

  TIM expects RAM at low memory for zeropage and stack.

  TIM support ROM at E000-EDF9
  ACIA 6850 at EF00

  TIM ROM $7000- $73FF




  }

IOBASE = $6E00     ; { 6530-044 I/O base address }

aMPA    = IOBASE+0  ;
aMDA    = IOBASE+1  ;
aMPB    = IOBASE+2  ;
aMDB    = IOBASE+3  ;
aMCLKIT = IOBASE+4  ;
aMCLKRD = IOBASE+4  ;
aMCLKIF = IOBASE+5  ;

ACIAbaseAddress = $FE00 ; { 6850 }

var
  memory : array[0.. $FFFF] of byte ;

  MPA, MDA,
  MPB, MDB     : integer ;

  CLK1T1,
  CLK8T1,
  CLK64T1,
  CLK1024T1,
  CLKRDI1,
  CLKRDT1       : integer ;

  Timerdivisor1 : integer ;
  Timer1        : integer ;
  Timer1On      : boolean ;


{ for CPU emulation }
function ReadMem(address : word) : byte ;
procedure writeMem(address : word ; data: byte) ;
procedure ResetTIM ;
procedure Onestep ;

implementation

uses
  u6502cpu, uconsole, umaintimsim, udebugwindow,
   uprofiler ;

const
  {$I timrom.inc }
  {$I joltsw.inc }
  {$I timsimrom.inc }

procedure OutChar(kar : char) ;

begin
  if SerialOut
    then
      begin
        fTIMSIM.SerialPort.WriteData(kar) ;
      end
  else
    VT_ShowChar(kar) ;
end;

procedure AfterStep ;

begin
  { timer RRIOTs free running }
  memory[aMCLKRD] := memory[aMCLKRD] - Cycles ;
end;

procedure Onestep ;

begin
  Onestep65 ;
  TotalCycles := TotalCycles + cycles ;
  DoCheckProfiler(opcode) ;
  AfterSTep ;
end ;

function ReadMem(address : word) : byte ;

{ recognizes:
  ACIA emulation for serial I/O
  PIA Jolt or SuperJolt
  TIM RRIOT
  rest treated as RAM
}
var
  wcnt : integer ;
begin
  if watches_enabled
    then
      begin
        watch_accessed := false ;
        { look up in watch_list }
        wcnt := 1 ;
        while (wcnt < max_watch) and (not watch_accessed) do
          begin
            if (address = watches_list[wcnt])
               then
                 begin
                   watch_accessed := true ;
                   watch_address := address ;
                 end ;
            wcnt := wcnt + 1 ;
          end;
      end ;
  { ACIA  Read  ACIAbaseAddress bit 0 : char received, bit 1 : ready for transmit }
  if address = ACIAbaseAddress
    then
       begin
         if KeyAvailable
           then
             { Receiver Data Register Full and Transmit Data Register Empty }
             Readmem := 3
            else
              { Transmit Data Register Empty, always }
              Readmem := 2 ;
         exit ;
        end  ;
  { ACIAbaseAddress + 1    received char }
  if address = (ACIAbaseAddress + 1)
    then
      begin
        Readmem := ord(VT_Readkey) ;
        exit ;
      end;
  { RRIOT registers }
  if address = aMPA
    then
      readmem := MPA
  else if address = aMDA
    then
      readmem := MPA
  else if address = aMPB
    then
      readmem := 0
  else if address = aMDB
    then
      readmem := MDB
  { rest of memory is RAM or ROM }
  else
    ReadMem := memory[address] ;
end ;

 procedure writeMem(address : word ; data: byte) ;
 { recognizes:
  ACIA emulation for serial I/O
  PIA Jolt or SuperJolt
  TIM RRIOT
  rest treated as RAM
}
var
   wcnt : integer ;
 begin
   if watches_enabled
     then
       begin
         watch_accessed := false ;
         { look up in watch_list }
         wcnt := 1 ;
         while (wcnt < max_watch) and (not watch_accessed) do
           begin
             if (address = watches_list[wcnt])
                then
                  begin
                    watch_accessed := true ;
                    watch_address := address ;
                  end ;
             wcnt := wcnt + 1 ;
           end;
       end;
   if address = ACIAbaseAddress + 1 then
     begin
       { write to console text file if open }
       if SaveTextOpen
         then
           write(SaveTextFile, data) ;
        OutChar(chr(data)) ;
        exit ;
     end ;
   { RRIOT }
   if address = aMPA
    then
      MDA := data
   else if address = aMDA
     then
       MDA := data
   else if address = aMPB
     then
       MPB := data
   else if address = aMDB
    then
      MDB := data
    { do not write to ROM }
   else if not ((address >= $7000) and (address <= $7FFF))
     then
       memory[address] := data ;
 end ;

procedure ResetRRIOT ;

  begin
    MPA := 0 ;
    MDA := 0 ;
    MPB := 1 ;
    MDB := 0 ;
    CLK1T1    := 0 ;
    CLK8T1    := 0 ;
    CLK64T1   := 0 ;
    CLK1024T1 := 0 ;
    CLKRDI1   := 0 ;
    CLKRDT1   := 0 ;
    TimerDivisor1 := 1 ;
    Timer1On      := false ;
  end;

procedure PATCHTIMROM ;
 {

 701E Compute bit time to 7050
 4C 50 70

 72da out

 72c6 WRT return at 72E8 RTS with

 72e9 RDT

 733d RDHSR load from high speed reader

 7291 RTS  delay 1 bit time

 }

  begin
   { skip bit rate detection }
  memory[$701E] := $4C ;
  memory[$701F] := $50 ;
  memory[$7020] := $70 ;
 { RDT patch to serial ACIA }
  memory[$72E9] := $4C ;
  memory[$72EA] := $09 ;
  memory[$72EB] := $F8 ;
  { OUTCH to serial }
  memory[$72C6] := $4C ;
  memory[$72C7] := $06 ;
  memory[$72C8] := $F8 ;

  { 7291 RTS  delay 1 bit time   }
  memory[$7291] := $60 ;
end ;

procedure ResetTIM ;
  var
    cnt : word ;
 begin
  { clear RAM memory areas }
   for cnt := 0 to $FFFF do
      memory[cnt] := 0 ;
   { clear Processor state to known values }
   A := 0 ;
   X := 0 ;
   Y := 0 ;
   PC := $7006 ;
   SP := $FF ;
   Processor_Status := $00 ;
   Cycles := 0 ;
   { load TIM ROMs }
   for cnt := 0 to timromsize -1  do
     begin
       memory[timromload + cnt] := timrom[cnt] ;
     end ;
   for cnt := 0 to joltswsize -1  do
     begin
       memory[joltswload + cnt] := joltsw[cnt] ;
     end ;
   { load ACIA ROM }
   for cnt := 0 to timsimromsize - 1 do
     begin
       memory[timsimromload + cnt] := timsimrom[cnt] ;
     end ;
   { load TIM vectors from TIM ROMs }
   for cnt := 0 to 7 do
     memory[$FFFF - 7 + cnt] := memory[$73FF - 7 + cnt] ;
   ResetRRIOT ;
   PatchTIMROM ;
   StopRunkey := true ;
   stoprun := true ;
   breaksetting := normal ;
   Reset6502 ;
 end;

procedure ResetCPU ;
  begin
    ResetTIM ;
    Reset6502 ;
  end;


end.


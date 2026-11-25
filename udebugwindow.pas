unit udebugwindow;

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


{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus,
  ExtCtrls, Buttons, SynEdit ;


type

  { TFdebugwindow }

  TFdebugwindow = class(TForm)
    brefreshdisassembly: TButton;
    bstepn: TButton;
    bNMI: TButton;
    brunto: TButton;
    brefresh: TButton;
    bexit: TButton;
    bplus: TButton;
    bmin: TButton;
    bIRQ: TButton;
    bReset: TButton;
    brun: TButton;
    bstop: TButton;
    bstepover: TButton;
    bstepin: TButton;
    B_zero_ticks: TButton;
    cDflag: TCheckBox;
    cBflag: TCheckBox;
    c65c02: TCheckBox;
    estartcode: TEdit;
    eendcode: TEdit;
    lstartcode: TLabel;
    lmaxcode: TLabel;
    mCleartable: TMenuItem;
    menudissymbol: TMenuItem;
    MMoveCopyMemory: TMenuItem;
    MFillmemory: TMenuItem;
    Mhexsearch: TMenuItem;
    MSearch: TMenuItem;
    mloadCC65Symboltable: TMenuItem;
    mrriot: TMenuItem;
    menuResetSimulator: TMenuItem;
    MenuSimulator: TMenuItem;
    menuShowtable: TMenuItem;
    mLoadTASMSymboltable: TMenuItem;
    Msymboltable: TMenuItem;
    DialogOpenSymboltable: TOpenDialog;
    bwatches: TSpeedButton;
    trun: TColorButton;
    cIflag: TCheckBox;
    cCflag: TCheckBox;
    cVflag: TCheckBox;
    cZflag: TCheckBox;
    cNflag: TCheckBox;
    eaddress: TEdit;
    edata: TEdit;
    eanimate: TEdit;
    estepcount: TEdit;
    eProcessorStatus: TEdit;
    esteps: TEdit;
    eCurrentPCDisasssembly: TEdit;
    eticks: TEdit;
    estack: TEdit;
    ePC: TEdit;
    eYRegister: TEdit;
    eXRegister: TEdit;
    eARegister: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    ltracelog: TLabel;
    lzeropagef: TLabel;
    lzeropage: TLabel;
    Label4: TLabel;
    lstepstaken: TLabel;
    lanimate: TLabel;
    lPS: TLabel;
    laddress: TLabel;
    ldata: TLabel;
    lmemory1: TLabel;
    lstatus: TLabel;
    lstack: TLabel;
    ldissembly: TLabel;
    lmemory: TLabel;
    L_Processor_Status: TLabel;
    L_Run: TLabel;
    lstackpointer: TLabel;
    L_PC: TLabel;
    L_Y_register: TLabel;
    L_X_register: TLabel;
    L_A_register: TLabel;
    logfilesdirselect: TMenuItem;
    mtracelog: TMemo;
    mMain: TMainMenu;
    mFile: TMenuItem;
    mExit: TMenuItem;
    mSaveFile: TMenuItem;
    mLoadFile: TMenuItem;
    P_ProcessorStatus: TPanel;
    P_Run: TPanel;
    mdisassembly: TSynEdit;
    mmemory: TSynEdit;
    mstack: TSynEdit;
    mzeropage: TSynEdit;
    DialogLogfiles: TSelectDirectoryDialog;
    tsteptimer: TTimer;
    procedure bbreakpointsClick(Sender: TObject);
    procedure bexitClick(Sender: TObject);
    procedure bIRQClick(Sender: TObject);
    procedure bNMIClick(Sender: TObject);
    procedure brefreshClick(Sender: TObject);
    procedure bplusClick(Sender: TObject);
    procedure bminClick(Sender: TObject);
    procedure brefreshdisassemblyClick(Sender: TObject);
    procedure bResetClick(Sender: TObject);
    procedure bstepnClick(Sender: TObject);
    procedure bstepoverClick(Sender: TObject);
    procedure bstopClick(Sender: TObject);
    procedure bruntoClick(Sender: TObject);
    procedure brunClick(Sender: TObject);
    procedure bstepinClick(Sender: TObject);
    procedure bwatchesClick(Sender: TObject);
    procedure B_zero_ticksClick(Sender: TObject);
    procedure cBflagEditingDone(Sender: TObject);
    procedure cCflagEditingDone(Sender: TObject);
    procedure cDflagEditingDone(Sender: TObject);
    procedure c65C02Click(Sender: TObject);
    procedure cIflagEditingDone(Sender: TObject);
    procedure cNflagEditingDone(Sender: TObject);
    procedure cVflagEditingDone(Sender: TObject);
    procedure cZflagEditingDone(Sender: TObject);
    procedure eaddressChange(Sender: TObject);
    procedure eaddressClick(Sender: TObject);
    procedure eaddressEditingDone(Sender: TObject);
    procedure eanimateEditingDone(Sender: TObject);
    procedure eARegisterEditingDone(Sender: TObject);
    procedure edataEditingDone(Sender: TObject);
    procedure eendcodeEditingDone(Sender: TObject);
    procedure ePCEditingDone(Sender: TObject);
    procedure eProcessorStatusEditingDone(Sender: TObject);
    procedure estackEditingDone(Sender: TObject);
    procedure estartcodeEditingDone(Sender: TObject);
    procedure eXRegisterEditingDone(Sender: TObject);
    procedure eYRegisterEditingDone(Sender: TObject);
    procedure estepsEditingDone(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure logfilesdirselectClick(Sender: TObject);
    procedure L_Processor_StatusClick(Sender: TObject);
    procedure mCleartableClick(Sender: TObject);
    procedure MenuConsoleOnClick(Sender: TObject);
    procedure menudissymbolClick(Sender: TObject);
    procedure menuResetSimulatorClick(Sender: TObject);
    procedure menuShowtableClick(Sender: TObject);
    procedure mExitClick(Sender: TObject);
    procedure MFillmemoryClick(Sender: TObject);
    procedure MhexsearchClick(Sender: TObject);
    procedure mloadCC65SymboltableClick(Sender: TObject);
    procedure mLoadFileClick(Sender: TObject);
    procedure mLoadTASMSymboltableClick(Sender: TObject);
    procedure mmemoryChange(Sender: TObject);
    procedure MMoveCopyMemoryClick(Sender: TObject);
    procedure mrriotClick(Sender: TObject);
    procedure mSaveFileClick(Sender: TObject);
    procedure mstackClick(Sender: TObject);
    procedure mzeropageChange(Sender: TObject);
    procedure mzeropageClick(Sender: TObject);
    procedure trunClick(Sender: TObject);
    procedure tsteptimerTimer(Sender: TObject);


  end;

const
  max_watch = 10 ;
  max_break = 10 ;

type

  TSymbolTable = array[0..$FFFF] of string ;

var
  Fdebugwindow: TFdebugwindow;

  Symboltable : TSymbolTable ;

var

  dissymbol         : boolean ;
  startcode,
  endcode           : integer ;
  stoprun           : boolean ;
  watch_accessed    : boolean ;
  watches_list      : array[1..max_watch] of integer ;
  watches_enabled   : boolean ;
  watch_Address     : integer ;
  breakpoint_list   : array[1..max_break] of integer ;
  RegisterAwatch,
  RegisterXwatch,
  RegisterYwatch,
  RegisterSPwatch   : integer ;
  RegisterAenabled,
  RegisterXenabled,
  RegisterYenabled,
  RegisterSPenabled : boolean ;
  TotalCycles       : Int64 ;

procedure RefreshAll ;
procedure ResetSimulator ;
function validatehexbyte(var dbyte: integer ;
                         hexstring: string) : boolean ;
function validatehexword(var dword : integer ;
                         hexstring: string) : boolean ;

procedure ResetWatches ;

procedure ResetBreakpoints ;

procedure ResetRegisterWatchpoints ;

procedure OpenAndStartTrace ;


const
  tracefilename = 'KIM1SIMtrace' ;

var
  tracefileOpen    : boolean ;
  tracefile        : text ;
  tracefiledir     : string ;



implementation

{$R *.lfm}

uses
    u6502cpu, udisassemble6502,  umaintimsim,
    utim, strutils, ufileload, ufilesave, usymboltable,
    uwatchbreak,  uhexsearch, umovecopymemory,
    ufillmemory ;

{ TFdebugwindow }

var
  addresstochange  : integer ;
  stepstorun       : integer ;
  stepsanimatetime : integer ;
  stepsrun         : integer ;
  symbolfile       : text ;
  symbolfilename   : string ;

  startDisPC       : integer ;

function validatehexword(var dword : integer ;
                         hexstring: string) : boolean ;
var
  valid : boolean ;
  value : integer ;

begin
    try
      begin
        value  := hex2dec(hexstring) ;
        valid := true ;
       end;
     except
       on E: EConvertError do
         valid := false ;
     end;
     if valid
       then
         valid := (value >= 0) and (value <= $FFFF) ;
     if valid
       then
         dword := value
       else
         dword := 0 ;
     validatehexword := valid ;
end ;

procedure AddPCtotrace ;
var
  symbol : Tsymbol ;
  aline, asline : string ;
  NextPC : integer ;
  strace : string ;

begin
  aline := '' ;
  asline := '' ;
  symbol.slabel  := '' ;
  symbol.address := 0  ;
  NextPC := PC ;
  disassemble6502(PC, NextPC, aline, asline, symbol) ;

  if SymbolTable[PC] <> ''
    then
      strace := SymbolTable[PC] + ' ' ;
  strace := strace + aline ;
  strace := strace + ' A=' + inttohex(A,2) ;
  strace := strace + ' X=' + inttohex(X,2) ;
  strace := strace + ' Y=' + inttohex(Y,2)   ;
  strace := strace + ' SP=' + inttohex(SP,2) + ' ';

  if (Processor_Status and Negativebit) <> 0
    then
      strace := strace + 'N'
    else
      strace := strace + 'n' ;
  if (Processor_Status and Overflowbit) <> 0
    then
      strace := strace + 'V'
    else
      strace := strace + 'v' ;
  strace := strace + '-' ;
  if (Processor_Status and Breakbit ) <> 0
    then
      strace := strace + 'B'
    else
      strace := strace + 'b' ;
  if (Processor_Status and Decimalbit ) <> 0
    then
      strace := strace + 'D'
    else
      strace := strace + 'd' ;
  if (Processor_Status and Interruptbit) <> 0
    then
      strace := strace + 'I'
    else
      strace := strace + 'i' ;
  if (Processor_Status and Zerobit ) <> 0
    then
      strace := strace + 'Z'
    else
      strace := strace + 'z' ;
  if (Processor_Status and Carrybit ) <> 0
    then
      strace := strace + 'C'
    else
      strace := strace + 'c' ;
  strace := strace +  ' TotalCycles=' + inttostr(cycles) + ' ' ;
  strace := strace +  asline + ' ' + symbol.slabel ;
  writeln(tracefile, strace) ;
  FdebugWindow.mtracelog.lines.add(strace) ;
end;


procedure OpenAndStartTrace ;
var
  year, month, day, hr, min, sec, ms: Word;
  strdatetime : string ;
  tracename : string ;
begin
  if tracefileopen
    then
      closefile(tracefile) ;
  tracefileopen := false ;

  DecodeDate(Date,year,month,day);
  DecodeTime(Time,hr, min, sec, ms);
  strdatetime := (Format ('%d',[day])) +
                 (Format ('%d',[year]))+
                 (Format ('%d',[hr])) +
                 (Format ('%d',[min])) +
                 (Format ('%d',[sec])) ;
  tracename :=  tracefiledir +  tracefilename + strdatetime + '.log' ;
  {$i-}
  assign(tracefile, tracename) ;
  rewrite(tracefile) ;
  {$i+}
  if IOresult  = 0 then
    begin
      tracefileopen := true ;
      write(tracefile,'Trace log started, CPU =') ;
      if Is65C02
        then
          write(tracefile,' 65C02')
        else
          write(tracefile,' 6502') ;
      writeln(tracefile) ;
      AddPCtotrace ;
    end ;
end;

function validatehexbyte(var dbyte: integer ;
                         hexstring: string) : boolean ;
var
  valid : boolean ;
  value : integer ;
begin
    try
      begin
        value  := hex2dec(hexstring) ;
        valid := true ;
       end;
     except
       on E: EConvertError do
         valid := false ;
     end;
     if valid
       then
         valid := (value >= 0) and (value <= $FF) ;
     if valid
       then
         dbyte := value
       else
         dbyte := 0 ;
     validatehexbyte := valid ;
end ;

procedure PositionCaret(caddr : integer);
var
  caretpos : integer ;
begin
  with Fdebugwindow do
    begin
      caretpos := ((caddr + 1) div 16) + 5 ;
      if caddr < $80
        then
          caretpos := 1 ;
      mmemory.CaretY:= caretpos ;
    end ;
end ;

procedure RefreshZeroPage ;
var
  countPC,
  i,
  currentPC  : integer ;
  dumpline,
  asciiline  : string ;
  dbyte      : byte ;
  caretp     : integer ;
begin
  with Fdebugwindow do
    begin
      caretp :=  mZeropage.CaretY ;
      mZeropage.BeginUpdate(false) ;
      mZeropage.lines.clear ;
      countPC := 0 ;
      while countPC < $FF do
        begin
          dumpline := inttohex(countPC, 4) + ': ' ;
           asciiline := ' ' ;
           for i := 0 to 15 do
             begin
               currentPC := countPC + i ;
               dbyte := Memory[currentPC] ;
               dumpline := dumpline + inttohex(dbyte,2) + ' ';
               dbyte := dbyte and $7F ;
               if (dbyte > $1F) and (dbyte < $7F)
                 then
                   asciiline := asciiline + chr(dbyte)
                 else
                   asciiline := asciiline + '.' ;
             end;
           countPC := countPC + 16 ;
           mZeropage.lines.add(dumpline + asciiline);
        end ;
      mZeropage.CaretY := caretp ;
      mZeropage.EndUpdate ;
    end;
end;

procedure RefreshMemory ;
var
  countPC, i, currentPC  : integer ;
  asciiline,
  dumpline : string ;
  dbyte : byte ;
  showpc : boolean ;
  caretp : integer;
begin
   with Fdebugwindow do
     begin
       caretp :=  mmemory.CaretY ;
       mmemory.BeginUpdate(false) ;
       mmemory.lines.clear ;
       countPC := 0 ;
       showPC := false ;
       while countPC < 65535 do
         begin
           dumpline := inttohex(countPC, 4) + ': ' ;
           asciiline := ' ' ;
           for i := 0 to 15 do
             begin
               currentPC := countPC + i ;
               if currentPC = addresstochange
                 then
                   showPC := true ;
               dbyte := Memory[currentPC] ;
               dumpline := dumpline + inttohex(dbyte,2) + ' ';
               dbyte := dbyte and $7F ;
               if (dbyte > $1F) and (dbyte < $7F)
                 then
                   asciiline := asciiline + chr(dbyte)
                 else
                   asciiline := asciiline + '.' ;
             end;
           if showPC
             then
               begin
                 dumpline := '>' + dumpline ;
                 ShowPC := false
               end
             else
                 dumpline := ' ' + dumpline ;
           countPC := countPC + 16 ;
           mmemory.lines.add(dumpline + asciiline);
         end ;
        mmemory.CaretY := caretp ;
        {
       PositionCaret(caretp) ;
       }
       mmemory.EndUpdate ;
     end;
end;

procedure RefreshStack ;
var
  cnt : integer ;
  stline : string ;
begin

  with Fdebugwindow do
    begin
      mstack.BeginUpdate(false) ;
      mstack.lines.clear ;
      for cnt := $01FF downto $0100 do
        begin
           stline :=  inttohex(cnt, 4) + ': ' + inttohex(memory[cnt],2) ;
           if cnt = (SP + $100)
             then
               stline := ' >> ' + stline + ' <<- SP'
             else
               stline := '    ' + stline ;
           mstack.lines.add(stline ) ;
         end ;
      mstack.CaretY:= $100 - SP ;
      mstack.EndUpdate ;
    end;
end;

procedure RefreshCaretDisassembly(caretPC : integer) ;

begin
    with Fdebugwindow do
      if caretPC >= StartdisPC
        then
          mdisassembly.CaretY := PC - StartdisPC + 1  ;
end;

procedure RefreshDisassembly ;

var
  symbol : Tsymbol ;
  aline, asline : string ;
  caretPC,
  currentPC,
  NextPC,
  enddisPC : integer ;

begin

  with Fdebugwindow do
    begin
      mdisassembly.clear ;
      mdisassembly.BeginUpdate(false) ;
      if (startcode = 0) and (endcode = 0)
        then
          begin
           NextPC := PC ;
           enddisPC  := NextPC + $100
          end
        else
          begin
            NextPC   := startcode ;
            caretPC  := NextPC ;
            enddisPC := endcode ;
           end ;
      while NextPC < enddisPC do
        begin
          currentPC := NextPC ;
          aline := '' ;
          asline := '' ;
          symbol.slabel  := '' ;
          symbol.address := -1  ;
          disassemble6502(currentPC, NextPC, aline, asline, symbol) ;
          if symbol.address = -1
            then
              symbol.slabel := '' ;

          mdisassembly.lines.add(' ' + aline +
                                 ' ' + asline +
                                 ' ' + symbol.slabel +
                                 ' ' + symboltable[currentPC] );
        end ;
      startdisPC := caretPC ;
      {
      RefreshCaretDisassembly(caretPC) ;
      }
       mdisassembly.CaretY := 1 ;
      mdisassembly.EndUpdate ;
    end;
end ;

procedure RefreshProcessorStatus ;

var
  symbol : Tsymbol ;
  aline, asline : string ;
  NextPC : integer ;

begin
  with Fdebugwindow do
    begin
      { fill all processor status fields with current values }
      eARegister.text := inttohex(  A,2) ;
      eXRegister.text := inttohex(  X,2) ;
      eYRegister.text := inttohex(  Y,2) ;

      cNflag.checked := (Processor_Status and  Negativebit)  <> 0 ;
      cZflag.checked := (Processor_Status and  Zerobit)      <> 0 ;
      cVflag.checked := (Processor_Status and  Overflowbit)  <> 0 ;
      cCflag.checked := (Processor_Status and  Carrybit)     <> 0 ;
      cIflag.checked := (Processor_Status and  Interruptbit) <> 0 ;
      cBflag.checked := (Processor_Status and  Breakbit)     <> 0  ;
      cDflag.checked := (Processor_Status and  Decimalbit)   <> 0 ;
      eProcessorStatus.text := inttohex(Processor_Status, 2) ;

      ePC.text       := inttohex(PC, 4) ;
      estack.text    := inttohex(SP, 2) ;
      eticks.text    := inttostr(Totalcycles) ;
      c65C02.checked := Is65C02 ;

      aline := '' ;
      asline := '' ;
      symbol.slabel  := '' ;
      symbol.address := -1  ;
      NextPC := PC ;
      disassemble6502(PC, NextPC, aline, asline, symbol) ;
      if symbol.address = -1
        then
          symbol.slabel := '' ;
      eCurrentPCDisasssembly.text := symboltable[PC] +
                                     ' ' + aline +
                                     ' ' + asline +
                                     ' ' + symbol.slabel ;

    end  ;
 end;


procedure RefreshAll ;

  begin
    {refresh all fields on screen }
    RefreshStack ;
    RefreshMemory ;
    RefreshZeroPage ;
    RefreshPRocessorStatus ;
    RefreshCaretDisassembly(PC) ;
  end ;

procedure ResetRegisterWatchpoints ;
begin
  RegisterAwatch  := -1 ;
  RegisterXwatch  := -1 ;
  RegisterYwatch  := -1 ;
  RegisterSPwatch := -1 ;
  RegisterAenabled  := false ;
  RegisterXenabled  := false ;
  RegisterYenabled  := false ;
  RegisterSPenabled := false ;
end;

procedure ResetWatches ;

var
  cnt : integer ;
begin

  for cnt := 1 to max_watch do
    begin
      watches_list[cnt] := -1 ;
    end;
  watches_enabled := false ;
end ;

procedure ResetBreakpoints ;

var
  cnt : integer ;
begin
  for cnt := 1 to max_break do
    begin
     breakpoint_list[cnt] := -1 ;

    end;
end ;

procedure ResetSimulator ;

begin
  with Fdebugwindow do
    begin
      addresstochange := 0 ;
      eaddress.text := '0' ;
      edata.text := '0' ;
      mstack.Clear ;
      mmemory.Clear ;
      mZeropage.clear ;
      mdisassembly.Clear ;
      mtracelog.clear ;
      mstack.gutter.visible := false ;
      mmemory.gutter.visible := false ;
      mdisassembly.gutter.visible := false ;
      mZeropage.gutter.visible := false ;
      tracefileOpen := false ;
      eanimate.text := '0' ;
      esteps.text := '1' ;
      stepstorun := 1 ;
      stepsanimatetime := 0 ;
      stoprun := false ;
      mmemory.Scrollbars := ssAutoVertical;
      mzeropage.Scrollbars := ssAutoVertical;
      RefreshAll ;
      RefreshDisAssembly ;
      ClearSymboltable ;
      dissymbol := false ;
      startcode := 0 ;
      endcode := 0 ;
      estartcode.text := '0' ;
      eendcode.text := '0' ;
      c65C02.checked := Is65c02 ;
      ResetWatches ;
      ResetBreakpoints ;
      ResetRegisterwatchpoints ;
    end ;
end ;

procedure TFdebugwindow.FormCreate(Sender: TObject);

begin
  borderIcons := [biSystemMenu,biMaximize] ;
  ResetSimulator ;
  bwatches.caption := 'Set breakpoints' + LineEnding + 'and Watchpoints' ;
  ShowInTaskBar := stAlways ;
end;

procedure TFdebugwindow.logfilesdirselectClick(Sender: TObject);
begin
  if DialogLogfiles.execute
    then
      begin
        tracefiledir := DialogLogfiles.filename + PathDelim ;
      end;
end;

procedure TFdebugwindow.L_Processor_StatusClick(Sender: TObject);
begin
  RefreshPRocessorStatus ;
end;

procedure TFdebugwindow.mCleartableClick(Sender: TObject);
begin
  ClearSymbolTable ;
end;

procedure TFdebugwindow.MenuConsoleOnClick(Sender: TObject);
begin

end;

procedure TFdebugwindow.menudissymbolClick(Sender: TObject);
begin
  dissymbol := not dissymbol ;
  menudissymbol.checked := dissymbol ;
end;

procedure TFdebugwindow.menuResetSimulatorClick(Sender: TObject);
begin
  ResetTIM ;
  ResetSimulator ;
end;

procedure TFdebugwindow.menuShowtableClick(Sender: TObject);
begin
  ShowSymbolTable ;
  fsymboltable.visible := true ;
end;

procedure TFdebugwindow.mExitClick(Sender: TObject);
begin
  Close ;
end;

procedure TFdebugwindow.MFillmemoryClick(Sender: TObject);
begin
  FFillmemory.visible := true ;
  FFillmemory.BringToFront ;
end;

procedure TFdebugwindow.MhexsearchClick(Sender: TObject);
begin
  FHExSearch.visible := true ;
  FHExSearch.BringToFront ;
end;

procedure TFdebugwindow.mloadCC65SymboltableClick(Sender: TObject);
{ load CC65 label file, as produced by LD65 }

{ load TASM symbol table }
{ 'al'<blank><address 6 hex digit><blank><label> }

var
  symbolline : string ;
  cnt   : integer ;
  slabel : string ;
  saddress : string ;
  address : integer ;

begin
  { load symbol table from file }
  DialogOpenSymboltable.filter := 'CC65 LD65|*.lbl' ;
  if DialogOpenSymboltable.execute
    then
      begin
        symbolfilename := DialogOpenSymboltable.filename ;
        try
          assignfile(symbolfile ,DialogOpenSymboltable.filename) ;
        except
         on E: EInOutError do
           begin
             ShowMessage('Error opening '
                         + DialogOpenSymboltable.filename + ' '
                         + ' ' + E.Message);
             exit ;
           end
        end;
        reset(symbolfile) ;
        while not eof(symbolfile) do
          begin
            readln(symbolfile, symbolline) ;
            if length(symbolline) < 6
              then
                begin
                  ShowMessage('Invalid symbol file') ;
                  exit
                end ;
            cnt := 1 ;
            { check record type,start with 'al ' }
            slabel := '' ;
            for cnt := 1 to 3 do
              slabel := slabel + symbolline[cnt] ;
            if slabel <> 'al '
              then
                begin
                  ShowMessage('Not a CC65 symbol table') ;
                  exit
                end ;
            { get address }
            saddress := '' ;
            for cnt := 6 to 9 do
               saddress := saddress + symbolline[cnt] ;
            { get label , to end of line read}
            slabel := '' ;
            for cnt := 11 to length(symbolline) do
              slabel := slabel +  symbolline[cnt] ;
            { add to table }
            address := 0 ;
            if ValidateHexword(address, saddress)
              then
                symboltable[address] := slabel
              else
                begin
                  ShowMessage('Invalid address in symbol file') ;
                  exit
                end;
          end;
        CloseFile(symbolfile) ;
        ShowMessage('TASM Symbol table loaded') ;
      end;
end ;

procedure TFdebugwindow.bexitClick(Sender: TObject);
begin
  fdebugwindow.visible := false ;
end;

procedure TFdebugwindow.bbreakpointsClick(Sender: TObject);
begin
    fWatchBreak.visible := true ;
end;

procedure TFdebugwindow.bIRQClick(Sender: TObject);
begin
  IRQ ;
end;

procedure TFdebugwindow.bNMIClick(Sender: TObject);
begin
  NMI6502 ;
end;

procedure TFdebugwindow.brefreshClick(Sender: TObject);
begin
  RefreshAll ;
  RefreshDisassembly ;
end;

procedure TFdebugwindow.bplusClick(Sender: TObject);

begin
  inc(addresstochange) ;
  if addresstochange > $FFFF
    then
      addresstochange := 0 ;
  eaddress.text := inttohex(addresstochange,4) ;
  edata.text := inttohex(memory[addresstochange],2) ;
  PositionCaret(addresstochange) ;
end;

procedure TFdebugwindow.bminClick(Sender: TObject);

begin
  dec(addresstochange) ;
  if addresstochange < 0
   then
      addresstochange := $FFFF ;
  eaddress.text := inttohex(addresstochange,4) ;
  edata.text := inttohex(memory[addresstochange],2) ;
  PositionCaret(addresstochange) ;
end;

procedure TFdebugwindow.brefreshdisassemblyClick(Sender: TObject);
begin
  RefreshDisassembly ;
end;

procedure TFdebugwindow.bResetClick(Sender: TObject);
begin
   Reset6502 ;
end;

procedure TFdebugwindow.bstepnClick(Sender: TObject);

begin
  StopRunkey := true ;
  stoprun := false ;
  trun.visible := true ;
  if stepsanimatetime > 0
    then
      tsteptimer.interval := stepsanimatetime * 1000
    else
    tsteptimer.interval := 1 ;
  stepsrun := 1 ;
  tsteptimer.enabled:= true ;
end;

procedure TFdebugwindow.bstepoverClick(Sender: TObject);

var
  overPC : integer ;

begin
  if not StopRunkey
    then
      begin
        ShowMessage('CPU Running, Stop TIM first') ;
        exit ;
      end;
  if memory[pc] = $20{ JSR }
    then
      begin
        stoprun := false ;
         trun.visible := true ;
        overPC := PC + 3 ;
        while (PC <> overPC) and (not stoprun) do
          begin
            if FwatchBreak.ctrace.checked and tracefileopen
               then
                 AddPCtotrace ;
            Onestep ;
            Application.processMessages ;
          end ;
       trun.visible := false ;
     end
    else
      begin
        Onestep ;
        if FwatchBreak.ctrace.checked and tracefileopen
          then
            AddPCtotrace ;
      end ;
  RefreshAll ;
end;

procedure TFdebugwindow.bstopClick(Sender: TObject);
begin
  StopRunkey := true ;
  stoprun := true ;
end;

procedure TFdebugwindow.bruntoClick(Sender: TObject);
var
  cnt : integer ;
begin
  if not StopRunkey
    then
      begin
        ShowMessage('CPU Running, Stop TIM first') ;
        exit ;
      end;
  stoprun := false ;
  trun.visible := true ;
  while (not stoprun) do
    begin
      if FwatchBreak.ctrace.checked and tracefileopen
        then
          AddPCtotrace ;
      watch_accessed := false ;
      Onestep ;
      Application.processMessages ;
      { check if Register watchpoint accessed display and stop }
      if RegisterSPenabled and (SP <= RegisterSPwatch)
        then
          begin
            ShowMessage('Stackpointer watchpoint '
                        + inttohex(RegisterSPwatch,2)
                        + ' accessed at '
                        + inttohex(PC,4)) ;
            stoprun := true ;
          end ;
      if RegisterAenabled and (A = RegisterAwatch)
        then
          begin
            ShowMessage('Register A watchpoint '
                        + inttohex(RegisterAwatch,2)
                        + ' accessed at '
                        + inttohex(PC,4)) ;
            stoprun := true ;
          end ;
       if RegisterXenabled and (X = RegisterXwatch)
        then
          begin
            ShowMessage('Register X watchpoint '
                        + inttohex(RegisterXwatch,2)
                        + ' accessed at '
                        + inttohex(PC,4)) ;
            stoprun := true ;
          end ;
       if RegisterYenabled and (Y = RegisterYwatch)
        then
          begin
            ShowMessage('Register Y watchpoint '
                        + inttohex(RegisterYwatch,2)
                        + ' accessed at '
                        + inttohex(PC,4)) ;
            stoprun := true ;
          end ;

      { check if watch accessed, display and stop }
      if watch_accessed
        then
          begin
            ShowMessage('Watch address '
                        + inttohex(watch_address,4)
                        + ' accessed at '
                        + inttohex(PC,4)
                        + ' value '
                        + inttohex(Readmem(watch_address),4));
            stoprun := true ;
          end ;
      { check if breakpoint, display and stop }
      if not stoprun
        then
          for cnt := 1 to max_break do
            if breakpoint_list[cnt] = PC
              then
                begin
                  ShowMessage('Break at '
                              + inttohex(PC,4)) ;
                  stoprun := true ;
                end;
    end ;
  if FwatchBreak.ctrace.checked and tracefileopen
     then
       AddPCtotrace ;
  trun.visible := false ;
  RefreshAll ;
end;

procedure TFdebugwindow.brunClick(Sender: TObject);

var
  runcnt : integer ;

begin
  if not StopRunkey
    then
      begin
        ShowMessage('CPU Running, Stop TIM first') ;
        exit ;
      end;
  stoprun := false ;
  trun.visible := true ;
  while not stoprun do
    begin
      for runcnt := 1 to 1000 do
        begin
          Onestep ;
          if Resetkeypressed
            then
              begin
                Resetkeypressed := false ;
                Reset6502 ;
              end;
        end;
      Application.ProcessMessages ;
    end;
  trun.visible := false ;
  RefreshAll ;
end;


procedure TFdebugwindow.bstepinClick(Sender: TObject);
begin
  if not StopRunkey
    then
      begin
        ShowMessage('CPU Running, Stop TIM first') ;
        exit ;
      end;
  Onestep ;
  if FwatchBreak.ctrace.checked and tracefileopen
    then
      AddPCtotrace ;
  RefreshAll ;
end;

procedure TFdebugwindow.bwatchesClick(Sender: TObject);
begin
  fWatchBreak.visible := true ;
end;

procedure TFdebugwindow.B_zero_ticksClick(Sender: TObject);
begin
  TotalCycles := 0 ;
  RefreshProcessorStatus
end;

procedure TFdebugwindow.cBflagEditingDone(Sender: TObject);
begin
  if cBflag.checked
    then
      Processor_Status := Processor_Status or Breakbit
    else
      Processor_Status := Processor_Status and (not Breakbit);
  RefreshProcessorStatus
end;

procedure TFdebugwindow.cCflagEditingDone(Sender: TObject);
begin
    if cCflag.checked
    then
      Processor_Status := Processor_Status or Carrybit
    else
      Processor_Status := Processor_Status and (not Carrybit);
  RefreshProcessorStatus
end;

procedure TFdebugwindow.cDflagEditingDone(Sender: TObject);
begin
    if cDflag.checked
    then
      Processor_Status := Processor_Status or Decimalbit
    else
      Processor_Status := Processor_Status and (not Decimalbit);
  RefreshProcessorStatus
end;

procedure TFdebugwindow.c65C02Click(Sender: TObject);
begin
  Is65C02 := c65C02.checked ;
  RefreshAll ;
end;

procedure TFdebugwindow.cIflagEditingDone(Sender: TObject);
begin
      if cIflag.checked
    then
      Processor_Status := Processor_Status or Interruptbit
    else
      Processor_Status := Processor_Status and (not Interruptbit);
  RefreshProcessorStatus
end;


procedure TFdebugwindow.cNflagEditingDone(Sender: TObject);

begin
  if cNflag.checked
    then
      Processor_Status := Processor_Status or Negativebit
    else
      Processor_Status := Processor_Status and (not Negativebit);
  RefreshProcessorStatus
end;



procedure TFdebugwindow.cVflagEditingDone(Sender: TObject);
begin
  if cVflag.checked
    then
      Processor_Status := Processor_Status or Overflowbit
    else
      Processor_Status := Processor_Status and (not Overflowbit);
    RefreshProcessorStatus
end;

procedure TFdebugwindow.cZflagEditingDone(Sender: TObject);
begin
    if cZflag.checked
    then
      Processor_Status := Processor_Status or Zerobit
    else
      Processor_Status := Processor_Status and (not Zerobit);
  RefreshProcessorStatus
end;

procedure TFdebugwindow.eaddressChange(Sender: TObject);
begin

end;

procedure addresscheck ;
var
  dword : integer ;

 begin
   with fdebugwindow do
     begin
       dword := 0 ;
       if ValidateHexWord(dword, eaddress.text)
         then
           addresstochange := dword ;
       eaddress.text := inttohex(addresstochange,4) ;
       edata.text := inttohex(memory[addresstochange],2) ;
       RefreshAll ;
       PositionCaret(addresstochange) ;
     end ;
 end ;


procedure TFdebugwindow.eaddressClick(Sender: TObject);
begin
  addresscheck ;
 end;

procedure TFdebugwindow.eaddressEditingDone(Sender: TObject);

begin
  addresscheck ;
end;

procedure TFdebugwindow.eanimateEditingDone(Sender: TObject);

var
  dword : integer ;

begin
   dword := 0 ;
   if ValidateHexWord(dword, eanimate.text)
      then
        stepsanimatetime := dword
end;


procedure TFdebugwindow.eARegisterEditingDone(Sender: TObject);

var
  dbyte : integer ;

begin
  dbyte := 0 ;
  if ValidateHexByte(dbyte, eARegister.text)
    then
      A := dbyte ;
  RefreshProcessorstatus ;
end;




procedure TFdebugwindow.edataEditingDone(Sender: TObject);
var
  dbyte : integer ;

begin
   dbyte := 0 ;
   if ValidateHexByte(dbyte, edata.text)
    then
      begin
        memory[addresstochange] := dbyte ;
        inc(addresstochange) ;
        if addresstochange > $FFFF
          then
            addresstochange := 0 ;
        eaddress.text := inttohex(addresstochange, 4) ;
        edata.text := inttohex(memory[addresstochange],2) ;
        RefreshMemory ;
        PositionCaret(addresstochange) ;
        edata.SetFocus
      end;
end;


procedure TFdebugwindow.ePCEditingDone(Sender: TObject);
var
  dword : integer ;

begin
   dword := 0 ;
   if ValidateHexWord(dword, ePC.text)
    then
      PC := dword ;

   RefreshProcessorstatus ;
   if FwatchBreak.ctrace.checked and tracefileopen
     then
        AddPCtotrace ;
end;

procedure TFdebugwindow.eProcessorStatusEditingDone(Sender: TObject);
var
  dbyte : integer ;

begin
    dbyte := 0 ;
  if ValidateHexByte(dbyte, eProcessorStatus.text)
    then
      Processor_status := dbyte ;
  RefreshProcessorstatus ;
end;


procedure TFdebugwindow.estackEditingDone(Sender: TObject);
var
  dbyte : integer ;

begin
  dbyte := 0 ;
  if ValidateHexByte(dbyte, estack.text)
    then
      SP := dbyte ;
  RefreshProcessorstatus ;
  RefreshStack ;
end;

procedure TFdebugwindow.estartcodeEditingDone(Sender: TObject);
var
  dword : integer ;

begin
     dword := 0 ;
   if ValidateHexWord(dword, estartcode.text)
    then
      startcode := dword
    else
      begin
        estartcode.text :=  '0000' ;
        startcode := 0
      end;
   if endcode < startcode
     then
       begin
           endcode := (startcode + $100) ;
           if endcode > $FFFF
             then
               endcode := $FFFF ;
           eendcode.text :=  inttohex(endcode,4) ;
       end;

end;

procedure TFdebugwindow.eendcodeEditingDone(Sender: TObject);

var
  dword : integer ;

begin
   dword := 0 ;
   if ValidateHexWord(dword, eendcode.text)
    then
      endcode := dword
    else
      begin
        eendcode.text :=  '0000' ;
        endcode := 0 ;
      end;
   if endcode < startcode
     then
       begin
         startcode := endcode -$100 ;
         if startcode < 0
           then
             startcode := 0 ;
         estartcode.text := inttohex(startcode,4) ;
       end;
end;



procedure TFdebugwindow.eXRegisterEditingDone(Sender: TObject);
var
  dbyte : integer ;

begin
  dbyte := 0 ;
  if ValidateHexByte(dbyte, eXRegister.text)
    then
      X := dbyte ;
  RefreshProcessorstatus ;
end;

procedure TFdebugwindow.eYRegisterEditingDone(Sender: TObject);
var
  dbyte : integer ;

begin
  dbyte := 0 ;
  if ValidateHexByte(dbyte, eYRegister.text)
    then
      Y := dbyte ;
  RefreshProcessorstatus ;
end;

procedure TFdebugwindow.estepsEditingDone(Sender: TObject);

begin
  if not TryStrToInt(esteps.Text, stepstorun)
    then
      begin
        esteps.Text := '1' ;
        stepstorun := 1 ;
      end ;
end;

procedure TFdebugwindow.FormActivate(Sender: TObject);
begin
  WindowState := wsNormal ;
end;

procedure TFdebugwindow.mLoadFileClick(Sender: TObject);
begin
  FFileLoad.visible := true ;
  FFileLoad.BringToFront ;
end;


procedure TFdebugwindow.mLoadTASMSymboltableClick(Sender: TObject);

{ load TASM symbol table }
{ <label><blanks><address 4 hex digit> }

var
  symbolline : string ;
  addrcnt,
  cnt   : integer ;
  slabel : string ;
  saddress : string ;
  address : integer ;

begin
  { load symbol table from file }
  DialogOpenSymboltable.filter := 'TASM symbols|*.sym' ;
  if DialogOpenSymboltable.execute
    then
      begin
        symbolfilename := DialogOpenSymboltable.filename ;
        try
          assignfile(symbolfile ,DialogOpenSymboltable.filename) ;
        except
         on E: EInOutError do
           begin
             ShowMessage('Error opening '
                         + DialogOpenSymboltable.filename + ' '
                         + ' ' + E.Message);
             exit ;
           end
        end;
        {$I-}
        reset(symbolfile) ;
        {$I+}
        if IOresult <> 0
          then
            begin
              ShowMessage('Error opening '
                          + DialogOpenSymboltable.filename);
              exit ;

            end;
        while not eof(symbolfile) do
          begin
            readln(symbolfile, symbolline) ;
            if length(symbolline) < 6
              then
                begin
                  ShowMessage('Invalid symbol file') ;
                  exit
                end ;
            { get label }
            slabel := '' ;
            cnt := 1 ;
            while symbolline[cnt] <> ' ' do
              begin
                slabel := slabel +  symbolline[cnt] ;
                cnt := cnt + 1
              end ;
            while symbolline[cnt] = ' ' do
              cnt := cnt + 1 ;
            { get address }
            saddress := '' ;
           for addrcnt := cnt to cnt + 4 do
                  saddress := saddress + symbolline[addrcnt] ;
            address := 0 ;
            if ValidateHexword(address, saddress)
              then
                symboltable[address] := slabel
              else
                begin
                  ShowMessage('Invalid address in symbol file') ;
                  exit
                end;
          end;
        CloseFile(symbolfile) ;
        ShowMessage('TASM Symbol table loaded') ;
      end;
end;

procedure TFdebugwindow.mmemoryChange(Sender: TObject);
begin

end;



procedure TFdebugwindow.MMoveCopyMemoryClick(Sender: TObject);
begin
  begin
    Fmovecopymemory.visible := true ;
    FMovecopymemory.BringToFront ;
  end;

end;

procedure TFdebugwindow.mrriotClick(Sender: TObject);
begin
  {
  frriot.visible := true ;
  frriot.BringToFront ;
  }
end;


procedure TFdebugwindow.mSaveFileClick(Sender: TObject);
begin
  FFileSave.visible := true ;
  FFileSave.BringToFront ;
end;

procedure TFdebugwindow.mstackClick(Sender: TObject);
begin
  RefreshStack ;
end;

procedure TFdebugwindow.mzeropageChange(Sender: TObject);
begin

end;

procedure TFdebugwindow.mzeropageClick(Sender: TObject);
begin
  RefreshZeroPage ;
end;

procedure TFdebugwindow.trunClick(Sender: TObject);
begin
  stoprun := true ;
end;

procedure TFdebugwindow.tsteptimerTimer(Sender: TObject);
begin
  if stoprun
    then
      begin
        tsteptimer.enabled := false ;
        trun.visible := false ;
      end
    else
      begin
        OneStep ;
        if FwatchBreak.ctrace.checked and tracefileopen
          then
            AddPCtotrace ;
        RefreshAll ;
        estepcount.text := inttostr(stepsrun) ;
        inc(stepsrun) ;
        if stepsrun > stepstorun
          then
            begin
              tsteptimer.enabled := false ;
              trun.visible := false ;
            end;
      end;
end;


end.

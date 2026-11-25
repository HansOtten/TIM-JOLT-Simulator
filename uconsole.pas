unit uconsole;

{
  Last update Eduardo Casino March 2026

  MIT License

  Copyright (c) 2019, 2026 Hans Otten

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
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, SunFounder PiPower UPS Power Supply DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
  }
{

Based upon ideas in EMUZ80 by Roland Daleske
Translated,  restricted to real VT TTY, cleaned up, ANSI control codes

  Version for KIM-1 simulator
  V1.0 June  2019 initial version
  V1.1 April 2021 some bugs removed, callable from KIM-1
  V1.2 February 2022 VT100 subset handling
  V1.3 Usable as unit, KIM-1 and TIM Simulator uses.

  External routines:
  procedure VT_ShowChar(kar : char) ; at current cursor position
  function VT_Readkey : char ;      ; last typed key
  procedure Reset_VT ;              ; Init and starts cursor, call first

  Calling unit needs to define procedure
  LoadTextFile LoadTextOpen,
  and var kar,  see  uses  umainkim1sim ;

  Note that the font used is Courier New.
  Install ttf cour.ttf on Linux in e.g. .home/<user>/.fonts
  to prevent substitution with artefacts
  }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls,
  Graphics, Dialogs, ExtCtrls, Menus, dateutils,
   LclIntf, LclType, Clipbrd, StdCtrls ;
type
  { TFconsole }
  TFconsole = class(TForm)
    ColorDialogFontConsole: TColorDialog;
    Image_mon1 : TImage;
    Image_mon2 : TImage;
    MColorfont: TMenuItem;
    MColorBack: TMenuItem;
    MNoLFtoCR: TMenuItem;
    MLFtoCR: TMenuItem;
    MCopy: TMenuItem;
    MPaste: TMenuItem;
    mResetConsole: TMenuItem;
    PopupMEnuConsole: TPopupMenu;
    timer_Screenrefresh : TTimer;
    Cursortimer         : TTimer;
    ScrollBar1          : TScrollBar;
    procedure CursortimerTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormUTF8KeyPress(Sender: TObject; var UTF8Key: TUTF8Char);
    procedure MColorBackClick(Sender: TObject);
    procedure MColorfontClick(Sender: TObject);
    procedure MLFtoCRClick(Sender: TObject);
    procedure MNoLFtoCRClick(Sender: TObject);
    procedure mResetConsoleClick(Sender: TObject);
    procedure timer_ScreenrefreshTimer(Sender: TObject);
    procedure ImageMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImageMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure ImageMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MCopyClick(Sender: TObject);
    procedure MPasteClick(Sender: TObject);
    procedure PopupMenuConsolePopup(Sender: TObject);
    procedure ScrollBar1Scroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  private
    procedure TextToMon ;
    procedure AutoScrollTimerTimer(Sender: TObject);

  public
  end;

var
  Fconsole: TFconsole;
  lastKey         : char ;
  KeyAvailable    : boolean ;
  CRfound         : boolean ;  { to prevent two CR's if DOS text file }
  VT_Break        : boolean ;  { true if Control-C in Lastkey }
  LoadTextfile    : file of byte ;
  LoadTextOpen    : boolean ;

procedure VT_ShowChar(kar : char) ;
function VT_Readkey : char ;
procedure Reset_VT ;

implementation
{$R *.lfm}

uses utim ;

 const
    MaxLines     = 25 ;
    MaxRows      = 80 ;
    ScrollLines  = 1000 ;
    ScrollBarWidth = 24 ;
   row_height    = 22;
   row_width     = 12;
   border        = 10 ;
   consoleWidth  = (MaxRows * row_width) + (2 * border) ;
   consoleHeight = (MaxLines * row_height) + (2 * border) ;
   ClearChar = ' ' ;
   CR = $0D ;
   LF = $0A ;
   FF = $0C ;
   BS = $08 ;
   ESC = $1B ;
   DEL = $7F ;
   TB  = $09 ;
   OpeningBracket = '[' ;
   Ccursor = '_' ;
   DefaultFColor = $89fdaf ;
   DefaultBColor = clBlack ;
 type
   TCText  = array[1..MaxLines, 1..MaxRows] of char ;
   TCColor = array[1..MaxLines,1..MaxRows] of TColor ;
   TCStyle = array[1..MaxLines,1..MaxRows] of TFontstyles ;

   TMCursor = record
                on_off    : boolean ;
                row,line  : integer ;
                character : char ;
              end;
   TTerminalstate = (NormalTerminalState, EscapeTerminalState,
                    CSITerminalState, CSITerminalStateParameter, CSITerminalParameterLineState) ;

  var
    MCursor               : TMCursor;
    ConsoleText           : TCText  ;
    ConsoleFColor         : TCColor ;
    ConsoleBColor         : TCColor ;
    ConsoleStyle          : TCSTyle ;
    TerminalState         : TTerminalState;
    FColor, BColor        : TColor;
    Cstyle                : TFontStyles;
    CSIPar1,
    CSIPar2               : integer;
    SavedCursorLine,
    SavedCursorRow        : integer ;

  type
    TCellCoord = record
      Line, Row: Integer;
    end;

  var
    Selecting: Boolean;
    HasSelection: Boolean;
    SelStart, SelEnd: TCellCoord;
    PasteQueue: string;
    PasteIndex: Integer;
    LastClickTime: DWord;
    ClickCount: Integer;
    AutoScrollTimer: TTimer;
    AutoScrollDir: Integer;

  type
    TLineBuf = array[1..MaxRows] of char;
    TColorBuf = array[1..MaxRows] of TColor;
    TStyleBuf = array[1..MaxRows] of TFontStyles;
    PLineBuf = ^TLineBuf;
    PColorBuf = ^TColorBuf;
    PStyleBuf = ^TStyleBuf;

  var
    ScrollText: array[1..ScrollLines] of TLineBuf;
    ScrollFColor: array[1..ScrollLines] of TColorBuf;
    ScrollBColor: array[1..ScrollLines] of TColorBuf;
    ScrollStyle: array[1..ScrollLines] of TStyleBuf;
    ScrollCount: Integer;
    ScrollStart: Integer;
    ScrollOffset: Integer;

procedure TFconsole.FormCreate(Sender: TObject);
begin
  Fconsole.scaled := true ;
  ShowInTaskBar := stAlways ;
  borderIcons := [biSystemMenu] ;
  BorderStyle := bsSingle ;
  KeyPreview := True ;
  FColor := DefaultFColor ;
  BColor := DefaultBColor ;
  Cstyle := [] ;
  Fconsole.width  := consoleWidth + 20 + ScrollBarWidth ;
  FConsole.height := consoleHeight + 20 ;
  Image_Mon1.Left   := 5 ;
  Image_Mon1.Top    := 5 ;
  Image_Mon1.Height := FConsole.height - 10 ;
  Image_Mon1.Width  := Fconsole.width - 10 - ScrollBarWidth ;
  Image_Mon1.Canvas.Brush.Color := BColor ;
  Image_Mon1.Canvas.Pen.Color   := BColor ;
  Image_Mon1.Canvas.Pen.Width   := 1 ;
  Image_Mon1.Canvas.Font.Name   := 'Courier New' ;
  Image_Mon1.Canvas.Font.Size   := 15 ;
  Image_Mon1.Canvas.Font.Color  := FColor ;
  Image_Mon1.Canvas.Rectangle(0,0,Image_Mon1.Width + 5,Image_Mon1.Height)  ;
  Image_Mon2.Left   := 5 ;
  Image_Mon2.Top    := 5 ;
  Image_Mon2.Height := FConsole.height - 10 ;
  Image_Mon2.Width  := Fconsole.width - 10 - ScrollBarWidth ;
  Image_Mon2.Canvas.Brush.Color := BColor ;
  Image_Mon2.Canvas.Pen.Color   := BColor ;
  Image_Mon2.Canvas.Pen.Width   := 1;
  Image_Mon2.Canvas.Font.Name   := 'Courier New' ;
  Image_Mon2.Canvas.Font.Size   := 15 ;
  Image_Mon2.Canvas.Font.Color  := FColor ;
  Image_Mon2.Canvas.Rectangle(0,0,Image_Mon1.Width,Image_Mon1.Height);
  ScrollBar1.Left   := Image_Mon1.Left + Image_Mon1.Width + 2 ;
  ScrollBar1.Top    := Image_Mon1.Top ;
  ScrollBar1.Height := Image_Mon1.Height ;
  ScrollBar1.Width  := 20 ;
  ScrollBar1.Min := 0 ;
  ScrollBar1.Max := 0 ;
  ScrollBar1.Position := 0 ;
  ScrollBar1.SmallChange := 1 ;
  ScrollBar1.LargeChange := MaxLines ;
  ScrollBar1.Kind := sbVertical ;
  ScrollBar1.TabStop := False ;
  Image_Mon1.Visible:= true  ;
  Image_Mon2.Visible:= false ;
  ScrollCount := 0 ;
  ScrollStart := 1 ;
  ScrollOffset := 0 ;
  AutoScrollTimer := TTimer.Create(Self);
  AutoScrollTimer.Interval := 100;
  AutoScrollTimer.Enabled := False;
  AutoScrollTimer.OnTimer := @AutoScrollTimerTimer;
  Fconsole.visible := true ;
  Reset_VT ;
  VT_Break := false ;
  loadtextopen := false ;
end;

{ ---------------------------------------------------------------------------
  Scrollback ring-buffer slot helper
  --------------------------------------------------------------------------- }

{ Returns the 1-based ring-buffer slot for a given 1-based virtual-history
  line index (1 = oldest stored line, ScrollCount = most recently pushed).
  Standard circular-buffer offset-from-head formula:
    slot = ((head - 1 + (virtualIdx - 1)) mod capacity) + 1 }
function ScrollBufIdx(virtualIdx: Integer): Integer; inline;
begin
  Result := ((ScrollStart - 1 + virtualIdx - 1) mod ScrollLines) + 1;
end;

procedure VT_ShowChar(kar : char) ;
  procedure turn_off_cursor ;
  begin
    with FConsole do
      begin
        Cursortimer.enabled:= false ;
        ConsoleText[Mcursor.line,Mcursor.row] := MCursor.character ;
        Cursortimer.enabled:= true ;
       end;
   end ;

  procedure turn_on_cursor ;
   begin
     with FConsole do
       begin
         Cursortimer.enabled:= false ;
         MCursor.character := ConsoleText[Mcursor.line,Mcursor.row]  ;
         Cursortimer.enabled:= true ;
       end ;
   end;

  procedure PushScrollback;
  var
    row: Integer;
    idx: Integer;
  begin
    { Compute the ring-buffer slot to write into.
      Occupied slots span [ScrollStart .. ScrollStart+ScrollCount-1] (mod ScrollLines),
      where ScrollStart points to the oldest entry.  All indices are 1-based. }
    if ScrollCount < ScrollLines then
      begin
        { Buffer not yet full: increment the count first, then address the new tail. }
        Inc(ScrollCount);
        idx := ScrollBufIdx(ScrollCount);
      end
    else
      begin
        { Buffer full: recycle the oldest slot (= ScrollStart) and advance the head. }
        idx := ScrollStart;
        ScrollStart := (ScrollStart mod ScrollLines) + 1;
      end;
    with FConsole do
      begin
        { Save the line that is about to scroll off the top of the live screen. }
        for row := 1 to MaxRows do
          begin
            ScrollText[idx][row]   := ConsoleText[1, row];
            ScrollFColor[idx][row] := ConsoleFColor[1, row];
            ScrollBColor[idx][row] := ConsoleBColor[1, row];
            ScrollStyle[idx][row]  := ConsoleStyle[1, row];
          end;
        ScrollBar1.Max := ScrollCount;
        { Keep the scrollbar thumb at the bottom only when not scrolled back. }
        if ScrollOffset = 0 then
          ScrollBar1.Position := ScrollCount;
      end;
  end;

  procedure scroll_up;
  var
    line, row : integer;
  begin
    PushScrollback;
    with FConsole do
      begin
        { Shift every line up by one using whole-row assignment.
          This is equivalent to the cell-by-cell approach but relies on the
          fact that a row slice of a 2-D static array is a value type in
          FreePascal, so direct assignment copies all MaxRows cells at once. }
        for line := 1 to MaxLines - 1 do
          begin
            ConsoleText[line]   := ConsoleText[line + 1];
            ConsoleFColor[line] := ConsoleFColor[line + 1];
            ConsoleBColor[line] := ConsoleBColor[line + 1];
            ConsoleStyle[line]  := ConsoleStyle[line + 1];
          end;
        { Clear the newly exposed bottom line with the current default attributes. }
        for row := 1 to MaxRows do
          begin
            ConsoleText[MaxLines, row]   := Clearchar;
            ConsoleFColor[MaxLines, row] := FColor;
            ConsoleBColor[MaxLines, row] := BColor;
            ConsoleStyle[MaxLines, row]  := Cstyle;
          end;
        MCursor.line := MaxLines;
        MCursor.row  := 1;
      end;
  end;

  procedure ClearScreen;
   var
    line, row : integer;
  begin
    for line := 1 to MaxLines do
      for row := 1 to MaxRows do
        begin
          Consoletext[line,row]   := Clearchar ;
          ConsoleFColor[line,row] := FColor ;
          ConsoleBColor[line,row] := BColor ;
          ConsoleStyle[line,row]  := Cstyle;
        end;
    Mcursor.line := 1 ;
    Mcursor.row := 1 ;
  end;

  procedure Text_On_Console(kar : char);
  begin
    { make sure only printable characters enters textconsole }
    if (ord(kar) < 32) or (ord(kar) > 127)
      then
        exit ;
    Consoletext[MCursor.line, MCursor.row]   := kar ;
    ConsoleFColor[MCursor.line, MCursor.row] := FColor ;
    ConsoleBColor[MCursor.line, MCursor.row] := BColor ;
    ConsoleStyle[MCursor.line, MCursor.row]  := Cstyle ;
    Inc(MCursor.row) ;
    if MCursor.row > MaxRows
      then
        begin
          MCursor.row := 1 ;
          Inc(MCursor.line) ;
          if MCursor.line > MaxLines
            then
              scroll_up;
       end;
    end;

  procedure CarriageReturn ;
  begin
    MCursor.row := 1 ;
  end;

  procedure CursorUp ;
  begin
    if MCursor.line > 1
      then
        Dec(MCursor.line);
   end;

  procedure CursorDown ;
  begin
    if MCursor.line < MaxLines
      then
        Inc(MCursor.line);
  end;

  procedure CursorRight ;
  begin
    if MCursor.row < MaxRows
      then
        Inc(MCursor.row) ;
  end;

  procedure CursorLeft ;
  begin
    if MCursor.row > 1
      then
        Dec(MCursor.row) ;
  end;

  procedure CursorHome ;
  begin
    MCursor.row  := 1;
    MCursor.line := 1;
  end;

  procedure DeleteToEndofLine ;
  var
    row : integer;
  begin
    for row := MCursor.row to MaxRows do
      begin
        Consoletext[MCursor.line,row]   := Clearchar ;
        ConsoleFColor[MCursor.line,row] := FColor ;
        ConsoleBColor[MCursor.line,row] := BColor ;
        Consolestyle[MCursor.line,row]  := Cstyle ;
      end;
  end;

  procedure Backspace ;
  begin
    if Mcursor.row > 1
      then
        begin
           Consoletext[MCursor.line,MCursor.row]   := Clearchar ;
           ConsoleFColor[MCursor.line,MCursor.row] := FColor ;
           ConsoleBColor[MCursor.line,MCursor.row] := BColor ;
           Consolestyle[MCursor.line,MCursor.row]  := Cstyle ;
           dec(Mcursor.row) ;
         end ;
  end;

  procedure DeleteCharacter;
  var
    row : integer;
  begin
    for row := MCursor.row to MaxRows-1 do
      begin
        ConsoleText[MCursor.line,row]   := ConsoleText[MCursor.line,row + 1] ;
        ConsoleFColor[MCursor.line,row] := ConsoleFColor[MCursor.line, row+1] ;
        ConsoleBColor[MCursor.line,row] := ConsoleBColor[MCursor.line, row+1] ;
        ConsoleStyle[MCursor.line,row]  := ConsoleStyle[MCursor.line, row+1] ;
      end;
  end;

  procedure DeleteToBeginofLine ;
  var
    row : integer;
  begin
    for row:=1 to MCursor.row-1 do
      begin
        ConsoleText[MCursor.line,row]   := Clearchar ;
        ConsoleFColor[MCursor.line,row] := FColor ;
        ConsoleBColor[MCursor.line,row] := BColor ;
        ConsoleStyle[MCursor.line,row]  := Cstyle ;
      end;
  end;

  procedure DeleteLine ;
  var
    row : integer;
  begin
    for row:=1 to MaxRows do
      begin
        ConsoleText[MCursor.line,row]   := Clearchar;
        ConsoleFColor[MCursor.line,row] := FColor ;
        ConsoleBColor[MCursor.line,row] := BColor ;
        ConsoleStyle[MCursor.line,row]  := Cstyle;
      end;
    MCursor.row:=1;
  end;

  procedure DeletLineScroll ;
  var
    line, row : integer;
  begin
    for line:=MCursor.line to MaxLines-1 do
      begin
        ConsoleText[line]   := ConsoleText[line+1] ;
        ConsoleFColor[line] := ConsoleFColor[line+1] ;
        ConsoleBColor[line] := ConsoleBColor[line+1] ;
        ConsoleStyle[line]  := ConsoleStyle[line+1] ;
      end;
    for row:=1 to MaxRows do
      begin
        ConsoleText[MaxLines,row]   := Clearchar;
        ConsoleFColor[MaxLines,row] := FColor ;
        ConsoleBColor[MaxLines,row] := BColor ;
        ConsoleStyle[MaxLines,row]  := Cstyle;
      end;
    MCursor.row:=1;
  end;

  procedure DeleteToEndOfScreen ;
  var
    row, line : integer;
  begin
    DeleteToEndofLine;
    if MCursor.line<MaxLines
      then
        begin
          for line:=MCursor.line+1 to MaxLines do
            begin
               for row:=1 to MaxRows do
                 begin
                   ConsoleText[line,row]   := Clearchar;
                   ConsoleFColor[line,row] := FColor ;
                   ConsoleBColor[line,row] := BColor ;
                   ConsoleStyle[line,row]  := Cstyle;
                 end;
            end;
        end;
  end;

  procedure CursorDeleteToBeginofScreen ;
  var
    row, line : integer;
  begin
    DeleteToBeginofLine ;
    if MCursor.line>1 then
      begin
        for line:=1 to MCursor.line-1 do
          begin
            for row:=1 to MaxRows do
              begin
                ConsoleText[line,row]  := Clearchar;
                ConsoleFColor[line,row] := FColor ;
                ConsoleBColor[line,row] := BColor ;
                ConsoleStyle[line,row] := Cstyle;
              end;
          end;
      end;
  end;

  procedure LineFeed;
  begin
    inc(MCursor.line);
    if MCursor.line > MaxLines
      then
        scroll_up ;
  end;

  procedure InsertCharacterRight ;
  var
    row : integer;
  begin
    for row:= MaxRows downto MCursor.row + 1 do
      begin
        ConsoleText[MCursor.line,row]   := ConsoleText[MCursor.line,row-1] ;
        ConsoleFColor[MCursor.line,row] := ConsoleFColor[MCursor.line,row-1] ;
        ConsoleBColor[MCursor.line,row] := ConsoleBColor[MCursor.line,row-1] ;
        ConsoleStyle[MCursor.line,row]  := ConsoleStyle[MCursor.line,row-1] ;
      end;
    ConsoleText[MCursor.line,MCursor.row]   := Clearchar;
    ConsoleFColor[MCursor.line,MCursor.row] :=  FColor ;
    ConsoleBColor[MCursor.line,MCursor.row] :=  BColor ;
    ConsoleStyle[MCursor.line,MCursor.row]  :=  Cstyle;
  end;

  procedure InsertCharacterLeft ;
  var
    row : integer;
  begin
    for row:= 1 downto MCursor.row - 1 do
      begin
        ConsoleText[MCursor.line,row]   := ConsoleText[MCursor.line,row+1] ;
        ConsoleFColor[MCursor.line,row] := ConsoleFColor[MCursor.line,row+1] ;
        ConsoleBColor[MCursor.line,row] := ConsoleBColor[MCursor.line,row+1] ;
        ConsoleStyle[MCursor.line,row]  := ConsoleStyle[MCursor.line,row+1] ;
      end;
    ConsoleText[MCursor.line,MCursor.row]   := Clearchar;
    ConsoleFColor[MCursor.line,MCursor.row] :=  FColor ;
    ConsoleBColor[MCursor.line,MCursor.row] :=  BColor ;
    ConsoleStyle[MCursor.line,MCursor.row]  :=  Cstyle;
  end;

  procedure InsertLineScrollUp ;
  var
    line, row : integer;
  begin
    for line:= 1 downto MCursor.line-1 do
      begin
        ConsoleText[line]   := ConsoleText[line + 1] ;
        ConsoleFColor[line] := ConsoleFColor[line + 1] ;
        ConsoleBColor[line] := ConsoleBColor[line + 1] ;
        ConsoleStyle[line]  := ConsoleStyle[line  + 1] ;
      end;
    for row:=1 to MaxRows do
      begin
        ConsoleText[MCursor.line,row]   := Clearchar;
        ConsoleFColor[MCursor.line,row] := FColor ;
        ConsoleBColor[MCursor.line,row] := BColor ;
        ConsoleStyle[MCursor.line,row]  := Cstyle;
      end;
  end ;

  procedure InsertLineScrollDown ;
    var
      line, row : integer;
    begin
      for line:=MaxLines downto MCursor.line+1 do
        begin
          ConsoleText[line]   := ConsoleText[line - 1] ;
          ConsoleFColor[line] := ConsoleFColor[line - 1] ;
          ConsoleBColor[line] := ConsoleBColor[line - 1] ;
          ConsoleStyle[line]  := ConsoleStyle[line - 1] ;
        end;
      for row:=1 to MaxRows do
        begin
          ConsoleText[MCursor.line,row]   := Clearchar;
          ConsoleFColor[MCursor.line,row] := FColor ;
          ConsoleBColor[MCursor.line,row] := BColor ;
          ConsoleStyle[MCursor.line,row]  := Cstyle;
        end;
    end;

  procedure SetCursorPosition(line, row : integer);
  begin
    MCursor.line := line;
    MCursor.row  := row;
    if (MCursor.line > MaxLines)
      then
        MCursor.line := MaxLines;
    if (MCursor.row > MaxRows)
      then
        MCursor.row := MaxRows;
    end;

procedure ScrollDown;
  var
    line, row: Integer;
begin
  PushScrollback;
  for line := 1 to MaxLines - 1 do
    begin
      ConsoleText[line]   := ConsoleText[line + 1] ;
      ConsoleFColor[line] := ConsoleFColor[line + 1] ;
      ConsoleBColor[line] := ConsoleBColor[line + 1] ;
      ConsoleStyle[line]  := ConsoleStyle[line + 1] ;
    end;
  for row:=1 to MaxRows do
    begin
      ConsoleText[MCursor.line,row]   := Clearchar ;
      ConsoleFColor[MCursor.line,row] := FColor ;
      ConsoleBColor[MCursor.line,row] := BColor ;
      ConsoleStyle[MCursor.line,row]  := Cstyle ;
     end;
  MCursor.row  :=1 ;
  MCursor.line := MaxLines ;
end;

procedure Tab ;
  begin
    MCursor.row := 8*((MCursor.row div 8) +1) ;
    if MCursor.row > Maxrows
      then
        MCursor.row := Maxrows
  end;

procedure BackToNormalState ;
begin
  terminalstate := NormalTerminalState ;
  CSIPar1 := 0 ;
  CSIPar2 := 0 ;
end ;

procedure DoESCTerminalState ;
  begin
    if kar = OpeningBracket
      then
        TerminalState := CSITerminalState
      else
        BackToNormalState ;
  end ;

  procedure DoCSITerminalState ;
  { processing of received ESC sequence }
  begin
    case kar of
      '0'..'9' : begin
                   CSIPar1 := CSIPar1 * 10 + (ord(kar) - $30) ;
                   if CSIPar1 > 99
                     then
                       BackToNormalState
                     else
                       TerminalState := CSITerminalStateParameter
                 end ;
      'H'      : begin
                   CursorHome ;
                   BackToNormalState  ;
                 end ;
      'J'      : begin
                   DeleteToEndofScreen ;
                   BackToNormalState  ;
                 end ;
      'K'      : begin
                   DeleteToEndofLine ;
                   BackToNormalState  ;
                 end ;
      'M'      : begin
                   ScrollDown ;
                   CursorHome ;
                   BackToNormalState  ;
                 end ;
      'f'      : begin
                   CursorHome ;
                   BackToNormalState  ;
                 end ;
      'c'      : begin
                   Reset_VT ;
                   BackToNormalState  ;
                 end ;
      's'      : begin
                   savedCursorLine := Mcursor.line ;
                   SavedCursorRow  := Mcursor.row ;
                   BackToNormalState  ;
                 end ;
      'u'      : begin
                   Mcursor.line := savedCursorLine  ;
                   Mcursor.row  := SavedCursorRow ;
                   BackToNormalState  ;
                 end ;
      'm'      : begin
                   FColor := DefaultFColor ;
                   BColor := DefaultBColor ;
                   Cstyle := [] ;
                   ConsoleFColor[MCursor.line,MCursor.row] := FColor ;
                   ConsoleBColor[MCursor.line,MCursor.row] := BColor ;
                   Consolestyle[MCursor.line,MCursor.row]  := Cstyle ;
                   BackToNormalState  ;
                 end ;
      else
        BackToNormalState  ;
     end;
  end;

  procedure DoCSIParameterTerminalState ;
  var Scolor : Tcolor ;
  begin
    case kar of
      '0'..'9' : begin
                   CSIPar1 := CSIPar1 * 10 + (ord(kar) - $30) ;
                   if CSIPar1 > 99
                     then
                       BackToNormalState
                     else
                       TerminalState := CSITerminalStateParameter
                 end ;
      ';'      : begin
                   TerminalState :=CSITerminalParameterLineState ;
                 end;
      'A'      : begin
                   if Mcursor.line > CSIPar1
                     then
                       Mcursor.line := CSIPar1
                     else
                       Mcursor.line := 1 ;
                   BackToNormalState
                 end ;
      'B'      : begin
                   if Mcursor.line  + CSIPar1 < MaxLines
                     then
                       Mcursor.line := Mcursor.line  + CSIPar1
                     else
                       Mcursor.line := Maxlines  ;
                   BackToNormalState
                    end ;
      'C'      : begin
                   if Mcursor.row  + CSIPar1 < MaxRows
                     then
                       Mcursor.row := Mcursor.row  + CSIPar1
                     else
                       Mcursor.line := MaxRows  ;
                   BackToNormalState
                 end ;
      'D'      : begin
                   if Mcursor.Row > CSIPar1
                     then
                       Mcursor.line := Mcursor.Row - CSIPar1
                     else
                       Mcursor.Row := 1 ;
                   BackToNormalState
                 end ;
       'K'      : begin
                   case CSIPar1 of
                     0 : DeleteToEndOfline ;
                     1 : DeleteToBEginOfLine ;
                     2 : Deleteline ;
                     end ;
                   BackToNormalState
                 end ;
       'J'      : begin
                    case CSIPar1 of
                      0 : DeleteToEndofScreen ;
                      1 : CursorDeleteToBeginofScreen ;
                      2 : begin
                            ClearScreen ;
                            CursorHome ;
                          end;
                     end ;
                   BackToNormalState
                 end ;
       { color attributes }
      'm'      : begin
                   case CSIPar1 of
                     0 : begin
                           FColor := DefaultFColor ;
                           BColor := DefaultBColor ;
                           Cstyle := [] ;
                           ConsoleFColor[MCursor.line,MCursor.row] := FColor ;
                           ConsoleBColor[MCursor.line,MCursor.row] := BColor ;
                           Consolestyle[MCursor.line,MCursor.row]  := Cstyle ;
                         end ;
                     1 : begin
                           Cstyle := [fsBold] ;
                         end ;
                     4 : begin
                           { underline requires more bottom font space,
                             which is not available, so overstrike instead }
                           Cstyle := [fsStrikeOut] ;
                         end ;
                     5 : begin
                           Cstyle := [fsItalic] ;
                         end ;
                     7 : begin
                           Cstyle := [fsBold] ;
                           Scolor := Fcolor ;
                           FColor := BColor ;
                           BColor := Scolor ;
                         end ;
                     27: begin
                           Cstyle := [] ;
                           Scolor := Fcolor ;
                           FColor := BColor ;
                           BColor := Scolor ;
                         end ;
                     30:  FColor := RGBToColor(0,0,0) ;
                     31:  FColor := RGBToColor(187,0,0) ;
                     32:  FColor := RGBToColor(0,187,0) ;
                     33:  FColor := RGBToColor(229,229,16) ;
                     34:  FColor := RGBToColor(0,0,187) ;
                     35:  FColor := RGBToColor(187,0,187) ;
                     36:  FColor := RGBToColor(0,187,187) ;
                     37:  FColor := RGBToColor(229,229,229) ;
                     40:  BColor := RGBToColor(0,0,0) ;
                     41:  BColor := RGBToColor(187,0,0) ;
                     42:  BColor := RGBToColor(0,187,0) ;
                     43:  BColor := RGBToColor(229,229,16) ;
                     44:  BColor := RGBToColor(0,0,187) ;
                     45:  BColor := RGBToColor(187,0,187) ;
                     46:  BColor := RGBToColor(0,187,187) ;
                     47:  BColor := RGBToColor(229,229,229) ;
                     90:  FColor := RGBToColor(85,85,85) ;
                     91:  FColor := RGBToColor(255,0,0) ;
                     92:  FColor := RGBToColor(0,255,0) ;
                     93:  FColor := RGBToColor(255,255,0) ;
                     94:  FColor := RGBToColor(0,0,255) ;
                     95:  FColor := RGBToColor(255,0,255) ;
                     96:  FColor := RGBToColor(0,255,255) ;
                     97:  FColor := RGBToColor(255,255,255) ;
                     100: BColor := RGBToColor(85,85,85) ;
                     101: BColor := RGBToColor(255,0,0) ;
                     102: BColor := RGBToColor(0,255,0) ;
                     103: BColor := RGBToColor(255,255,0) ;
                     104: BColor := RGBToColor(0,0,255) ;
                     105: BColor := RGBToColor(255,0,255) ;
                     106: BColor := RGBToColor(0,255,255) ;
                     107: BColor := RGBToColor(255,255,255) ;
                     end;
                   BackToNormalState
                 end ;
      { Insert/Delete }
      'L'      : begin
                   if CSIPar1 = 1
                     then
                       InsertLineScrollDown ;
                   BackToNormalState
                 end ;
      'P'      : begin
                   if CSIPar1 = 1
                     then
                       { delete current char, shift line left } ;
                       InsertCharacterLeft ;
                   BackToNormalState
                 end ;
      '@'      : begin
                   if CSIPar1 = 1
                     then
                       { delete current char, shift line right } ;
                       InsertCharacterRight ;
                   BackToNormalState
                 end ;
      'M'      : begin
                   if CSIPar1 = 1
                     then
                       { delete current line , shift sceeen up } ;
                   InsertLineScrollUp ;
                   BackToNormalState
                 end ;
       else
         BackToNormalState
       end;
   end ;

  procedure DoCSITerminalParameterLineState ;
  begin
    case kar of
      '0'..'9' : begin
                   CSIPar2 := (CSIPar2 * 10) + (ord(kar) - $30) ;
                   if CSIPar2 > 99
                     then
                       BackToNormalState
                     else
                   TerminalState := CSITerminalParameterLineState
                 end ;
       'H', 'f'  : begin
                    SetCursorPosition(CSIPar1, CSIPar2) ;
                    BackToNormalState
                  end;
       else
         BackToNormalState
     end ;
  end ;

begin
  with Fconsole do
    begin
      turn_off_cursor ;
      if terminalstate = NormalTerminalState
        then
          begin
            if (ord(kar) > $1F) and (ord(kar) <> DEL)
              then
                Text_on_console(kar)
              else
                case ord(kar) of
                  $01 : CursorHome ;
                  $04 : CursorRight ;
                  $05 : CursorUp ;
                  BS  : Backspace ;
                  TB  : Tab ;
                  LF  : LineFeed ;
                  FF  : ClearScreen ;
                  CR  : CarriageReturn ;
                  $13 : CursorLeft ;
                  $16 : DeleteToEndofLine ;
                  $18 : CursorDown ;
                  ESC : begin
                          terminalstate := EscapeTerminalState ;
                          CSIPar1 := 0 ;
                          CSIPar2 := 0 ;
                        end;
                  DEL : Backspace ;
                 end ;
          end
      else if terminalstate = EscapeTerminalState
        then
          DoESCTerminalState
      else if terminalstate = CSITerminalState
        then
          DoCSITerminalState
      else if terminalstate = CSITerminalStateParameter
        then
          DoCSIParameterTerminalState
      else if terminalstate = CSITerminalParameterLineState
        then
          DoCSITerminalParameterLineState ;
      turn_on_cursor ;
    end ;
end ;

{ ---------------------------------------------------------------------------
  Viewport scroll helpers
  --------------------------------------------------------------------------- }

{ Set the viewport scroll offset to NewOffset, clamped to [0..ScrollCount].
  Both selection endpoints are shifted by the change in offset so that the
  highlighted text stays at the same visual rows during a manual scroll.
  Updates the scrollbar thumb, window caption and repaints the terminal.

  NOTE: During an auto-scroll drag (AutoScrollTimerTimer) only the anchor
  (SelStart) is shifted and must be clamped — that is handled separately. }
procedure ApplyScrollOffset(NewOffset: Integer);
var
  Delta: Integer;
begin
  if NewOffset < 0           then NewOffset := 0;
  if NewOffset > ScrollCount then NewOffset := ScrollCount;
  Delta        := NewOffset - ScrollOffset;
  ScrollOffset := NewOffset;
  if (Delta <> 0) and HasSelection then
  begin
    Inc(SelStart.Line, Delta);
    Inc(SelEnd.Line,   Delta);
  end;
  FConsole.ScrollBar1.Position := ScrollCount - ScrollOffset;
  if ScrollOffset > 0 then
    FConsole.Caption := 'VT  console (Scroll)'
  else
    FConsole.Caption := 'VT  console';
  FConsole.TextToMon;
end;

procedure TFconsole.FormKeyDown(Sender: TObject;
                                var Key: Word; Shift: TShiftState);
{ Handles cursor keys, Delete, and Ctrl combinations.
  Printable characters are NOT consumed here: Key is left unchanged so that
  Lazarus propagates the event to OnUTF8KeyPress, where the OS delivers the
  correctly translated character. Setting Key=0 for a printable key suppresses
  OnUTF8KeyPress. }
begin
  if ScrollOffset > 0 then
    ApplyScrollOffset(0);
  if HasSelection then
  begin
    HasSelection := False;
    Selecting := False;
    TextToMon;
  end;

  { Ignore bare modifier keys }
  if (Key = 16) or (Key = 17) or (Key = 18) or (Key = 20) then
  begin
    Key := 0 ;
    Exit ;
  end ;

  case Key of
    $27 : Key := $04 ; { →  Ctrl-D }
    $25 : Key := $13 ; { ←  Ctrl-S }
    $26 : Key := $05 ; { ↑  Ctrl-E }
    $28 : Key := $18 ; { ↓  Ctrl-X }
    $2E : Key := $08 ; { Del → BS  }
  end ;

  if ssCtrl in Shift then
    Key := Key - 64 ;

  { Changed Key: it produced a control code — process and consume it }
  if Key < $20 then
  begin
    lastKey      := Chr(Key and $7F) ;
    KeyAvailable := True ;
    if lastKey = Chr(3) then
      VT_Break := True ;
    Key := 0 ; { Prevent OnUTF8KeyPress from also firing }
  end ;
  { Key = OrigKey: printable or unhandled — leave Key intact so
    Lazarus fires OnUTF8KeyPress with the correct character }
end;

procedure TFconsole.FormUTF8KeyPress(Sender: TObject; var UTF8Key: TUTF8Char);
{ Receives the final character after full OS layout resolution — Shift, AltGr,
  dead keys, Caps Lock and accents all applied. Only 7-bit ASCII characters are
  forwarded; multi-byte UTF-8 sequences are outside the terminal's range. }
begin
  if ScrollOffset > 0 then
    ApplyScrollOffset(0);
  if Length(UTF8Key) <> 1 then
    Exit ;
  lastKey      := UTF8Key[1] ;
  KeyAvailable := True ;
  UTF8Key      := '' ; { Mark as consumed }
end;

procedure TFconsole.MColorBackClick(Sender: TObject);
var
  line, row : integer ;
begin
  if ColorDialogFontConsole.Execute
    then
      begin
        BColor :=  ColorDialogFontConsole.Color ;
        for line := 1 to MaxLines do
          for row := 1 to MaxRows do
            begin
              ConsoleBColor[line,row] := BColor ;
           end ;
        Image_Mon1.Canvas.Brush.Color := BColor ;
        Image_Mon2.Canvas.Brush.Color := BColor ;
        Image_Mon1.Canvas.Rectangle(0,0,Image_Mon1.Width + 5,Image_Mon1.Height);
        Image_Mon2.Canvas.Rectangle(0,0,Image_Mon1.Width + 5,Image_Mon1.Height);
      end;
end;

procedure TFconsole.MColorfontClick(Sender: TObject);
var
  line, row : integer ;
begin
  if ColorDialogFontConsole.Execute
    then
      begin
        FColor :=  ColorDialogFontConsole.Color ;
        for line := 1 to MaxLines do
          for row := 1 to MaxRows do
            begin
              ConsoleFColor[line,row] := FColor ;
              ConsoleStyle[line,row] := Cstyle ;
            end ;
      end;
end;

procedure TFconsole.MLFtoCRClick(Sender: TObject);
begin
  {$IFDEF KIM1SIM}
  { GETCH with LF added patch to serial ACIA }
  memory[$1E5A] := $4C ;
  memory[$1E5B] := $0F ;
  memory[$1E5C] := $15 ;
  {$ENDIF}
end;

procedure TFconsole.MNoLFtoCRClick(Sender: TObject);
begin
  {$IFDEF KIM1SIM}
  { GETCH patch to serial ACIA }
  memory[$1E5A] := $4C ;
  memory[$1E5B] := $0C ;
  memory[$1E5C] := $15 ;
  {$ENDIF}
end;

procedure TFconsole.mResetConsoleClick(Sender: TObject);
begin
  FColor := DefaultFColor ;
  BColor := DefaultBColor ;
  Image_Mon1.Canvas.Brush.Color := BColor ;
  Image_Mon1.Canvas.Font.Color  := FColor ;
  Image_Mon2.Canvas.Brush.Color := BColor ;
  Image_Mon2.Canvas.Font.Color  := FColor ;
  Image_Mon1.Canvas.Rectangle(0,0,Image_Mon1.Width + 5,Image_Mon1.Height)  ;
  Image_Mon2.Canvas.Rectangle(0,0,Image_Mon1.Width + 5,Image_Mon1.Height)  ;
  Reset_VT ;
  {$IFDEF KIM1SIM}
  { GETCH patch to serial ACIA }
  memory[$1E5A] := $4C ;
  memory[$1E5B] := $0C ;
  memory[$1E5C] := $15 ;
  {$ENDIF}
end;


procedure TFconsole.CursortimerTimer(Sender: TObject);
{ on timer change char under cursur frOm + to char }
begin
  if ScrollOffset > 0 then Exit;
  Cursortimer.enabled:= false ;
  if MCursor.on_off then
    begin
      ConsoleText[MCursor.line, MCursor.row] := MCursor.character ;
      MCursor.on_off := false ;
    end
  else
    begin
      MCursor.character := ConsoleText[MCursor.line, MCursor.row] ;
      ConsoleText[MCursor.line, MCursor.row] := Ccursor ;
      MCursor.on_off := true ;
    end;
  Cursortimer.Enabled := true ;
end;

procedure TFconsole.FormActivate(Sender: TObject);
begin
  SetFocus ;
end;

{ ---------------------------------------------------------------------------
  Display-line resolution helpers
  ---------------------------------------------------------------------------
  Both helpers translate a display line number (1..MaxLines) to a pointer
  into the appropriate backing buffer.

  When ScrollOffset = 0 every display line maps 1-to-1 to ConsoleText.
  When ScrollOffset > 0 the topmost ScrollOffset screen lines show history
  from the ring buffer; the remaining lines still come from ConsoleText.

  virtualIdx is the 1-based ordinal within the stored history:
    1 = oldest entry (furthest back), ScrollCount = most recently pushed.
  The ring-buffer formula maps that ordinal to an actual array slot via
  ScrollBufIdx (defined above, near PushScrollback).
  --------------------------------------------------------------------------- }

{ Resolve a display line to its text-buffer row pointer only.
  Used by CopySelection and SelectWordAt, which do not need colour/style.
  Returns False when displayLine falls outside the valid buffer range. }
function ResolveTextLine(displayLine: Integer; out pText: PLineBuf): Boolean;
var
  virtualIdx, srcLine: Integer;
begin
  Result := False;
  if (ScrollOffset > 0) and (displayLine <= ScrollOffset) then
  begin
    virtualIdx := ScrollCount - ScrollOffset + displayLine;
    if (virtualIdx < 1) or (virtualIdx > ScrollCount) then Exit;
    pText := @ScrollText[ScrollBufIdx(virtualIdx)];
  end
  else
  begin
    srcLine := displayLine - ScrollOffset;
    if (srcLine < 1) or (srcLine > MaxLines) then Exit;
    pText := @ConsoleText[srcLine];
  end;
  Result := True;
end;

{ Like ResolveTextLine but also returns pointers to the parallel colour and
  style buffers.  Used by TextToMon, which needs all four attributes per cell. }
function ResolveDisplayLine(displayLine: Integer;
  out pText   : PLineBuf;
  out pFColor : PColorBuf;
  out pBColor : PColorBuf;
  out pStyle  : PStyleBuf): Boolean;
var
  virtualIdx, bufIdx, srcLine: Integer;
begin
  Result := False;
  if (ScrollOffset > 0) and (displayLine <= ScrollOffset) then
  begin
    virtualIdx := ScrollCount - ScrollOffset + displayLine;
    if (virtualIdx < 1) or (virtualIdx > ScrollCount) then Exit;
    bufIdx  := ScrollBufIdx(virtualIdx);
    pText   := @ScrollText[bufIdx];
    pFColor := @ScrollFColor[bufIdx];
    pBColor := @ScrollBColor[bufIdx];
    pStyle  := @ScrollStyle[bufIdx];
  end
  else
  begin
    srcLine := displayLine - ScrollOffset;
    if (srcLine < 1) or (srcLine > MaxLines) then Exit;
    pText   := @ConsoleText[srcLine];
    pFColor := @ConsoleFColor[srcLine];
    pBColor := @ConsoleBColor[srcLine];
    pStyle  := @ConsoleStyle[srcLine];
  end;
  Result := True;
end;

{ Convert pixel coordinates to 1-based (Line, Row) cell coordinates.
  Coordinates are clamped to the valid cell range.
  Returns True when the pixel lies inside the terminal drawing area. }
function GetCellAtPixel(PX, PY: Integer; out Line, Row: Integer): Boolean;
begin
  Row  := (PX - border) div row_width  + 1;
  Line := (PY - border) div row_height + 1;
  if Row  < 1        then Row  := 1;
  if Row  > MaxRows  then Row  := MaxRows;
  if Line < 1        then Line := 1;
  if Line > MaxLines then Line := MaxLines;
  Result := (PX >= border) and (PY >= border) and
            (PX <= border + MaxRows  * row_width) and
            (PY <= border + MaxLines * row_height);
end;

{ Normalise the two selection endpoints into stream (row-major) order.
  SelStart and SelEnd may be in any order; this always yields
  (AStartLine, AStartRow) before (AEndLine, AEndRow) in text-stream order.
  Centralising this logic avoids duplication between IsCellSelected and
  CopySelection. }
procedure NormalizeSelStream(out AStartLine, AStartRow, AEndLine, AEndRow: Integer);
begin
  if (SelStart.Line < SelEnd.Line) or
     ((SelStart.Line = SelEnd.Line) and (SelStart.Row <= SelEnd.Row)) then
    begin
      AStartLine := SelStart.Line; AStartRow := SelStart.Row;
      AEndLine   := SelEnd.Line;   AEndRow   := SelEnd.Row;
    end
  else
    begin
      AStartLine := SelEnd.Line;   AStartRow := SelEnd.Row;
      AEndLine   := SelStart.Line; AEndRow   := SelStart.Row;
    end;
end;

{ Return True if the cell at (Line, Row) falls within the current stream-based
  selection.  When the selection spans multiple lines, the start line is
  selected from its start column to the end, intermediate lines are fully
  selected, and the end line is selected from column 1 to its end column. }
function IsCellSelected(Line, Row: Integer): Boolean;
var
  sLine, sRow, eLine, eRow: Integer;
begin
  if not (Selecting or HasSelection) then
    Exit(False);
  NormalizeSelStream(sLine, sRow, eLine, eRow);
  if (Line < sLine) or (Line > eLine) then
    Exit(False);
  if sLine = eLine then
    Result := (Row >= sRow) and (Row <= eRow)
  else if Line = sLine then
    Result := (Row >= sRow)
  else if Line = eLine then
    Result := (Row <= eRow)
  else
    Result := True;
end;

{ Feed one character from the paste queue into LastKey, then advance
  PasteIndex.  Resets the queue when exhausted.
  Characters are delivered one per VT_ReadKey poll so the simulated CPU
  sees them arrive at its natural polling rate rather than all at once. }
procedure FeedNextFromQueue;
begin
  if PasteIndex <= Length(PasteQueue) then
  begin
    lastKey      := PasteQueue[PasteIndex];
    KeyAvailable := True;
    Inc(PasteIndex);
  end
  else
  begin
    PasteQueue := '';
    PasteIndex := 0;
  end;
end;

{ Copy the selected text stream to the clipboard.
  Each row in the selection is right-trimmed before joining, because the
  terminal buffer always pads every line with spaces up to MaxRows; without
  trimming, pasted text would carry long runs of trailing spaces. }
procedure CopySelection;
var
  sLine, sRow, eLine, eRow: Integer;
  line, row: Integer;
  lineStr, s: string;
  pText: PLineBuf;
begin
  if not HasSelection then Exit;
  NormalizeSelStream(sLine, sRow, eLine, eRow);
  s := '';
  for line := sLine to eLine do
  begin
    if not ResolveTextLine(line, pText) then Continue;
    lineStr := '';
    if line = sLine then
      begin
        if sLine = eLine then
          begin
            { Single-line selection }
            for row := sRow to eRow do
              lineStr := lineStr + pText^[row];
          end
        else
          begin
            { First line of multi-line selection: from sRow to end }
            for row := sRow to MaxRows do
              lineStr := lineStr + pText^[row];
          end;
      end
    else if line = eLine then
      begin
        { Last line of multi-line selection: from 1 to eRow }
        for row := 1 to eRow do
          lineStr := lineStr + pText^[row];
      end
    else
      begin
        { Fully selected intermediate line }
        for row := 1 to MaxRows do
          lineStr := lineStr + pText^[row];
      end;
    lineStr := TrimRight(lineStr);
    if line < eLine then
      lineStr := lineStr + sLineBreak;
    s := s + lineStr;
  end;
  Clipboard.AsText := s;
  HasSelection := False;
  Selecting := False;
  FConsole.TextToMon;
end;

{ Extend the selection to cover the whole word that contains (Line, Row).
  A word is a maximal run of characters with ordinal value > Space ($20).
  Clicking on a space yields a zero-width selection on that single cell. }
procedure SelectWordAt(Line, Row: Integer);
var
  r: Integer;
  pText: PLineBuf;
begin
  if not ResolveTextLine(Line, pText) then Exit;
  if pText^[Row] = ' ' then
  begin
    SelStart.Line := Line; SelStart.Row := Row;
    SelEnd        := SelStart;
    Exit;
  end;
  r := Row;
  while (r > 1) and (pText^[r - 1] > ' ') do
    Dec(r);
  SelStart.Line := Line; SelStart.Row := r;
  r := Row;
  while (r < MaxRows) and (pText^[r + 1] > ' ') do
    Inc(r);
  SelEnd.Line := Line; SelEnd.Row := r;
end;

{ Return the highest column index in Line that holds a non-blank character,
  or 0 when the entire line consists of spaces / ClearChar.
  Used by TextToMon so the visual selection highlight does not extend past
  the last actual character on a line. }
function LineLastNonBlank(pText: PLineBuf): Integer;
var
  c: Integer;
begin
  for c := MaxRows downto 1 do
    if pText^[c] > ' ' then
      Exit(c);
  Result := 0;
end;

procedure TFConsole.TextToMon ;
var
  line, row, x, y : integer;
  Textchar        : char ;
  tempF, tempB    : TColor;
  pText           : PLineBuf;
  pFColor, pBColor: PColorBuf;
  pStyle          : PStyleBuf;
  lastNonBlank    : Integer;
begin
  for line := 1 to MaxLines do
    begin
      if not ResolveDisplayLine(line, pText, pFColor, pBColor, pStyle) then
        Continue;
      lastNonBlank := LineLastNonBlank(pText);
      for row := 1 to MaxRows do
        begin
          Textchar := pText^[row];
          tempF := pFColor^[row];
          tempB := pBColor^[row];
          if (Selecting or HasSelection) and (row <= lastNonBlank) and IsCellSelected(line, row) then
            begin
              tempF := pBColor^[row];
              tempB := pFColor^[row];
            end;
          if Image_Mon1.Visible then
            begin
              Image_Mon2.Canvas.Font.Color  := tempF ;
              Image_Mon2.Canvas.Brush.Color := tempB ;
              Image_Mon2.Canvas.Font.Style  := pStyle^[row] ;
              x := row_width*(row-1) + border ;
              y := row_height*(line-1)+ border ;
              Image_Mon2.Canvas.TextOut(x,y, Textchar);
            end
          else
            begin
              Image_Mon1.Canvas.Font.Color  := tempF ;
              Image_Mon1.Canvas.Brush.Color := tempB ;
              Image_Mon1.Canvas.Font.Style  := pStyle^[row] ;
              x := Row_width*(row-1) + border ;
              y := Row_height*(line-1)+ border ;
              Image_mon1.Canvas.TextOut(x,y,Textchar);
            end;
        end;
    end;
  if Image_Mon1.Visible then
    begin
      Image_Mon1.Visible:= false ;
      Image_Mon2.Visible:= true  ;
    end
  else
    begin
      Image_Mon2.Visible:= false ;
      Image_Mon1.Visible:= true  ;
   end;
end;

procedure TFconsole.ScrollBar1Scroll(Sender: TObject; ScrollCode: TScrollCode;
  var ScrollPos: Integer);
begin
  case ScrollCode of
    scTrack, scPosition, scLineUp, scLineDown, scPageUp, scPageDown:
      ApplyScrollOffset(ScrollCount - ScrollPos);
  end;
end;

procedure TFconsole.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
const
  WHEEL_LINES = 3;
var
  NewOffset: Integer;
begin
  if ScrollCount = 0 then Exit;
  if WheelDelta > 0 then
    NewOffset := ScrollOffset + WHEEL_LINES
  else
    NewOffset := ScrollOffset - WHEEL_LINES;
  ApplyScrollOffset(NewOffset);
  Handled := True;
end;

procedure TFconsole.timer_ScreenrefreshTimer(Sender: TObject);
begin
  timer_screenrefresh.enabled := false ;
  FConsole.TextToMon ;
  timer_screenrefresh.enabled := true ;
end;

{ Left-click with multi-click detection:
    1 click  — anchor the start of a drag selection
    2 clicks — select the word under the cursor
    3 clicks — select the entire line
    4+ clicks — select the whole screen; reset counter so the next click
                starts the cycle again }
procedure TFconsole.ImageMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  L, R: Integer;
  Now: DWord;
begin
  if Button = mbLeft then
  begin
    Now := GetTickCount;
    if Now - LastClickTime <= DWord(GetDoubleClickTime) then
      Inc(ClickCount)
    else
      ClickCount := 1;
    LastClickTime := Now;

    { Any click dismisses an existing selection immediately }
    if HasSelection then
    begin
      HasSelection := False;
      Selecting    := False;
      TextToMon;
    end;

    if not GetCellAtPixel(X, Y, L, R) then Exit;

    case ClickCount of
      1:
        begin
          { Anchor the drag at the clicked cell }
          SelStart.Line := L; SelStart.Row := R;
          SelEnd        := SelStart;
          Selecting     := True;
          TextToMon;
        end;
      2:
        begin
          SelectWordAt(L, R);
          HasSelection := True;
          Selecting    := False;
          TextToMon;
        end;
      3:
        begin
          { Whole-line selection: all columns on line L }
          SelStart.Line := L; SelStart.Row := 1;
          SelEnd.Line   := L; SelEnd.Row   := MaxRows;
          HasSelection  := True;
          Selecting     := False;
          TextToMon;
        end;
      else
        begin
          { Select everything and reset so the next click starts fresh }
          SelStart.Line := 1;        SelStart.Row := 1;
          SelEnd.Line   := MaxLines; SelEnd.Row   := MaxRows;
          HasSelection  := True;
          Selecting     := False;
          ClickCount    := 0;
          TextToMon;
        end;
    end;
  end;
end;

{ Extend the in-progress drag selection to the cell under the pointer.
  When the mouse leaves the terminal area during a drag, auto-scroll is
  triggered so the selection can span the entire scrollback buffer. }
procedure TFconsole.ImageMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  L, R: Integer;
  termBottom: Integer;
begin
  if not Selecting then Exit;
  termBottom := border + MaxLines * row_height;
  if GetCellAtPixel(X, Y, L, R) then
  begin
    AutoScrollDir := 0;
    AutoScrollTimer.Enabled := False;
    SelEnd.Line := L;
    SelEnd.Row  := R;
    TextToMon;
  end
  else if Y < border then
  begin
    AutoScrollDir := -1;
    if not AutoScrollTimer.Enabled then
      AutoScrollTimer.Enabled := True;
    SelEnd.Line := 1;
    SelEnd.Row  := 1;
    TextToMon;
  end
  else if Y > termBottom then
  begin
    AutoScrollDir := 1;
    if not AutoScrollTimer.Enabled then
      AutoScrollTimer.Enabled := True;
    SelEnd.Line := MaxLines;
    SelEnd.Row  := MaxRows;
    TextToMon;
  end
  else
  begin
    AutoScrollDir := 0;
    AutoScrollTimer.Enabled := False;
  end;
end;

procedure TFconsole.AutoScrollTimerTimer(Sender: TObject);
var
  OldOffset, Delta: Integer;
begin
  if not Selecting then
  begin
    AutoScrollTimer.Enabled := False;
    Exit;
  end;
  OldOffset := ScrollOffset;
  case AutoScrollDir of
    -1:
      if ScrollOffset < ScrollCount then
        ScrollOffset := ScrollOffset + 1;
    1:
      if ScrollOffset > 0 then
        ScrollOffset := ScrollOffset - 1;
  end;
  Delta := ScrollOffset - OldOffset;
  if Delta <> 0 then
  begin
    Inc(SelStart.Line, Delta);
    if SelStart.Line < 1 then SelStart.Line := 1;
    if SelStart.Line > ScrollOffset + MaxLines then
      SelStart.Line := ScrollOffset + MaxLines;
  end;
  if ScrollOffset = OldOffset then
    AutoScrollTimer.Enabled := False
  else
  begin
    ScrollBar1.Position := ScrollCount - ScrollOffset;
    if ScrollOffset > 0 then
      Caption := 'VT  console (Scroll)'
    else
      Caption := 'VT  console';
    TextToMon;
  end;
end;

{ Finalise the drag: a non-zero extent becomes a confirmed selection;
  a zero-area drag (click without movement) leaves no selection }
procedure TFconsole.ImageMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  AutoScrollDir := 0;
  AutoScrollTimer.Enabled := False;
  if (Button = mbLeft) and Selecting then
  begin
    Selecting    := False;
    HasSelection := (SelStart.Line <> SelEnd.Line) or
                    (SelStart.Row  <> SelEnd.Row);
    TextToMon;
  end;
end;

procedure TFconsole.MCopyClick(Sender: TObject);
begin
  CopySelection;
end;

{ Normalise all newline conventions (CRLF, LF) to bare CR, which is what
  the KIM-1 serial input expects, then enqueue the text for character-by-
  character delivery via FeedNextFromQueue / VT_ReadKey. }
procedure TFconsole.MPasteClick(Sender: TObject);
var
  s: string;
begin
  s := Clipboard.AsText;
  if s = '' then Exit;
  { Collapse CRLF first so the bare-LF pass does not introduce extra CRs }
  s := StringReplace(s, #13#10, #13, [rfReplaceAll]);
  s := StringReplace(s, #10,    #13, [rfReplaceAll]);
  PasteQueue := s;
  PasteIndex := 1;
  FeedNextFromQueue;
end;

procedure TFconsole.PopupMenuConsolePopup(Sender: TObject);
begin
  MCopy.Enabled := HasSelection;
end;

function VT_readKey : char ;
{ get key from keyboard or file, non-blocking }
var
  kar : byte ;
begin
  { reading from text file }
  if LoadTextOpen
    then
      begin
        if eof(LoadTextfile)
          then
            begin
              CloseFile(LoadTextfile) ;
              LoadTextOpen := false ;
              VT_readkey := chr(LF) ;
            end
        else
          begin
            read(LoadTextFile, kar) ;
            { check to see if UNIX style text file with LF endings }
            if (kar = LF)
              then
                begin
                  if CRfound
                    then
                      kar := 0
                    else
                      begin
                        kar := CR ;
                        CRfound := false ;
                      end ;
                end
              else
                if kar = CR
                then
                  CRfound := true ;
            VT_Readkey := chr(kar)
          end ;
        if VT_Break
          then
            begin
              CloseFile(LoadTextfile) ;
              LoadTextOpen := false ;
              VT_readkey := chr(CR) ;
            end ;
      end
  else
    begin
      {if reading from keyboard }
      VT_Readkey := LastKey ;
      KeyAvailable := false ;
      LastKey := chr(0) ;
      if (PasteQueue <> '') and (PasteIndex <= Length(PasteQueue)) then
        FeedNextFromQueue;
    end;
end ;

procedure Reset_VT ;
var
  line, row : integer ;
begin
  FColor := DefaultFColor ;
  BColor := DefaultBColor ;
  for line := 1 to MaxLines do
    for row := 1 to MaxRows do
      begin
         ConsoleText[line,row]   := Clearchar ;
         ConsoleFColor[line,row] := FColor ;
         ConsoleBColor[line,row] := BColor ;
         ConsoleStyle[line,row]  := Cstyle ;
     end ;
  Mcursor.line := 1 ;
  Mcursor.row := 1;
  Mcursor.On_off := false ;
  CSIPar1        := 0;
  CSIPar2        := 0;
  FConsole.Cursortimer.enabled := true ;
  LastKey := chr(0) ;
  KeyAvailable := false ;
  SavedCursorLine := 0 ;
  SavedCursorRow  := 0 ;
  TerminalState  := NormalTerminalState ;
  Selecting := False ;
  HasSelection := False ;
  PasteQueue := '' ;
  PasteIndex := 0 ;
  LastClickTime := 0 ;
  ClickCount := 0 ;
  AutoScrollDir := 0 ;
  AutoScrollTimer.Enabled := False ;
  ScrollCount := 0 ;
  ScrollStart := 1 ;
  ScrollOffset := 0 ;
  FConsole.ScrollBar1.Max := 0 ;
  FConsole.ScrollBar1.Position := 0 ;
  FConsole.Caption := 'VT  console' ;
end ;

end.

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
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
}

{
  Based upon ideas in EMUZ80 by Roland Daleske
  Translated, restricted to real VT TTY, cleaned up, ANSI control codes

  Version for KIM-1 simulator
  V1.0 June  2019  initial version
  V1.1 April 2021  some bugs removed, callable from KIM-1
  V1.2 February 2022  VT100 subset handling
  V1.3 Usable as unit, KIM-1 and TIM Simulator uses.

  Public API (interface section):
    procedure VT_ShowChar(kar: char)    show char at current cursor position
    function  VT_Readkey: char          last typed key (non-blocking)
    procedure Reset_VT                  initialise terminal; call first

  The calling unit must expose:
    LoadTextFile : file of byte
    LoadTextOpen : boolean
  (see umainkim1sim)

  Font: Hack VT100 (embedded as RCDATA resource CONSOLE_FONT).
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls,
  Graphics, Dialogs, ExtCtrls, Menus, DateUtils,
  LclIntf, LclType, Clipbrd, StdCtrls,
  EasyLazFreeType, LazFreeTypeFontCollection,
  BGRABitmap, BGRABitmapTypes, BGRAFreeType;

type
  { TFconsole }
  TFconsole = class(TForm)
    ColorDialogFontConsole : TColorDialog;
    ConsoleBox             : TPaintBox;
    MColorfont             : TMenuItem;
    MColorBack             : TMenuItem;
    MNoLFtoCR              : TMenuItem;
    MLFtoCR                : TMenuItem;
    MCopy                  : TMenuItem;
    MPaste                 : TMenuItem;
    mResetConsole          : TMenuItem;
    PopupMenuConsole       : TPopupMenu;
    timer_Screenrefresh    : TTimer;
    Cursortimer            : TTimer;
    ScrollBar1             : TScrollBar;
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
    procedure ConsoleBoxPaint(Sender: TObject);
  private
    procedure TextToMon;
    procedure AutoScrollTimerTimer(Sender: TObject);
    procedure WheelTimerTimer(Sender: TObject);
  public
    destructor Destroy; override;
  end;

var
  Fconsole     : TFconsole;
  lastKey      : Char;
  KeyAvailable : Boolean;
  CRfound      : Boolean;    { prevents double CR on DOS text files }
  VT_Break     : Boolean;    { set to True when Ctrl-C is in LastKey }
  LoadTextfile : file of Byte;
  LoadTextOpen : Boolean;

procedure VT_ShowChar(kar: Char);
function  VT_Readkey: Char;
procedure Reset_VT;
procedure SetConsoleConfig(AFColor, ABColor: TColor);

implementation
{$R *.lfm}

{$IFDEF KIM1SIM}
uses ukim1;
{$ELSE}
uses utim;
{$ENDIF}

const
  MaxLines       = 24;
  MaxRows        = 80;
  ScrollLines    = 1000;
  ScrollBarWidth = 24;
  RowHeight      = 24;
  RowWidth       = 12;
  Border         = 10;
  ConsoleWidth   = (MaxRows  * RowWidth)  + (2 * Border);
  ConsoleHeight  = (MaxLines * RowHeight) + (2 * Border);
  ClearChar      = ' ';
  CR             = $0D;
  LF             = $0A;
  FF             = $0C;
  BS             = $08;
  ESC            = $1B;
  DEL            = $7F;
  TB             = $09;
  SO             = $0E;
  SI             = $0F;
  CCursor        = '_';
  InitFColor     = TColor($89FDAF);
  InitBColor     = clBlack;
  FontName       = 'Hack VT100';
  FontSize       = 15;

type
  TCharset       = (csASCII, csGraphics, csUK);
  TTerminalState = (NormalTerminalState, EscapeTerminalState,
                    CSITerminalState, CSITerminalStateParameter,
                    CharSetDesignateState);

  TCellCoord = record
    Line, Row : Integer;
  end;

  TMCursor = record
    On_Off    : Boolean;
    Row, Line : Integer;
    Character : Char;
  end;

  TConsoleStyle  = (csBold, csBlink, csUnderline, csReverseVideo, csStrikeOut);
  TConsoleStyles = set of TConsoleStyle;
  
  TCText       = array[1..MaxLines, 1..MaxRows] of Char;
  TCColor      = array[1..MaxLines, 1..MaxRows] of TColor;
  TCStyle      = array[1..MaxLines, 1..MaxRows] of TConsoleStyles;
  TCharSetGrid = array[1..MaxLines, 1..MaxRows] of TCharset;

  TLineBuf    = array[1..MaxRows] of Char;
  TColorBuf   = array[1..MaxRows] of TColor;
  TStyleBuf    = array[1..MaxRows] of TConsoleStyles;
  TCharSetBuf = array[1..MaxRows] of TCharset;
  PLineBuf    = ^TLineBuf;
  PColorBuf   = ^TColorBuf;
  PStyleBuf   = ^TStyleBuf;
  PCharSetBuf = ^TCharSetBuf;

var
  { Active terminal state }
  MCursor        : TMCursor;
  TerminalState  : TTerminalState;
  CStyle         : TConsoleStyles;
  FColor, BColor : TColor;
  DefaultFColor  : TColor;
  DefaultBColor  : TColor;

  { Screen buffers }
  ConsoleText    : TCText;
  ConsoleFColor  : TCColor;
  ConsoleBColor  : TCColor;
  ConsoleStyle   : TCStyle;
  ConsoleCharSet : TCharSetGrid;

  { CSI / escape-sequence parser state }
  CSIParams      : array[1..16] of Integer;
  CSIParamCount  : Integer;
  DECPrivate     : Boolean;
  CursorVisible  : Boolean;
  BlinkOn        : Boolean;  { current blink phase, in sync with cursor }
  BlinkRedraw    : Boolean;  { set by cursor timer when phase toggles }
  ScrollTop      : Integer;
  ScrollBottom   : Integer;
  DECOriginMode  : Boolean;
  SavedCursorLine,
  SavedCursorRow : Integer;

  { Character-set state }
  CharsetG0     : TCharset;
  CharsetG1     : TCharset;
  InvokingG1    : Boolean;
  UseGraphics   : Boolean;
  DesignatingG0 : Boolean;

  { Scrollback ring-buffer }
  ScrollText    : array[1..ScrollLines] of TLineBuf;
  ScrollFColor  : array[1..ScrollLines] of TColorBuf;
  ScrollBColor  : array[1..ScrollLines] of TColorBuf;
  ScrollStyle   : array[1..ScrollLines] of TStyleBuf;
  ScrollCharSet : array[1..ScrollLines] of TCharSetBuf;
  ScrollCount   : Integer;
  ScrollStart   : Integer;
  ScrollOffset  : Integer;
  SelScrollOffset : Integer;
  WheelPending  : Integer;
  WheelTimer    : TTimer;

  { Mouse selectionc}
  Selecting     : Boolean;
  HasSelection  : Boolean;
  SelStart, SelEnd : TCellCoord;
  LastClickTime : DWord;
  ClickCount    : Integer;

  { Paste queue }
  PasteQueue : string;
  PasteIndex : Integer;

  { Auto-scroll (mouse-drag past terminal edge) }
  AutoScrollTimer : TTimer;
  AutoScrollDir   : Integer;

  { VT100 Special Graphics character map }
  GGraphicsMap : array[AnsiChar] of string;

  { BGRABitmap rendering surfaces }
  FFontFace  : TFreeTypeFont;
  FDrawer    : TBGRAFreeTypeDrawer;
  FBitmap    : TBGRABitmap;
  CellDirty  : array[1..MaxLines, 1..MaxRows] of Boolean;
  FullRedraw : Boolean;

procedure BuildGraphicsMap;     forward;


{ Fill a rectangle on the shared BGRABitmap back-buffer. }
procedure BGRAFillRect(X, Y, W, H: Integer; AColor: TColor); inline;
begin
  FBitmap.FillRect(X, Y, X + W, Y + H, ColorToBGRA(ColorToRGB(AColor)), dmSet);
end;

procedure LoadConsoleFont;
var
  RegStream: TResourceStream;
begin
  try
    if not Assigned(FontCollection) then
    begin
      FontCollection := TFreeTypeFontCollection.Create;
      SetDefaultFreeTypeFontCollection(FontCollection);
    end;

    RegStream := TResourceStream.Create(HInstance, 'HACK-VT100-REGULAR', RT_RCDATA);

    { True means thst FontCollection manages and frees RegStream }
    FontCollection.AddStream(RegStream, True);

    FFontFace                  := TFreeTypeFont.Create;
    FFontFace.Collection       := FontCollection;
    FFontFace.Name             := FontName;
    FFontFace.SizeInPoints     := FontSize;
    FFontFace.Hinted           := False;
    FFontFace.ClearType        := True;
    FFontFace.Quality          := grqHighQuality;
    FFontFace.SmallLinePadding := False;

  except
    on E: Exception do
    begin
      FreeAndNil(FFontFace);
      ShowMessage('Error loading font: ' + E.Message);
    end;
  end;
end;

procedure TFconsole.FormCreate(Sender: TObject);
begin
  LoadConsoleFont;

  Scaled        := True;
  ShowInTaskBar := stAlways;
  BorderIcons   := [biSystemMenu];
  BorderStyle   := bsSingle;
  KeyPreview    := True;
  CStyle        := [];

  Width  := ConsoleWidth  + 10 + ScrollBarWidth;
  Height := ConsoleHeight + 10;

  ConsoleBox.Left   := 5;
  ConsoleBox.Top    := 5;
  ConsoleBox.Width  := ConsoleWidth;
  ConsoleBox.Height := ConsoleHeight;

  FBitmap := TBGRABitmap.Create(ConsoleWidth, ConsoleHeight);
  FBitmap.FillTransparent;
  FDrawer := TBGRAFreeTypeDrawer.Create(FBitmap);
  
  FullRedraw := True;

  ScrollBar1.Left        := ConsoleBox.Left + ConsoleBox.Width + 2;
  ScrollBar1.Top         := ConsoleBox.Top;
  ScrollBar1.Height      := ConsoleBox.Height;
  ScrollBar1.Width       := 20;
  ScrollBar1.Min         := 0;
  ScrollBar1.Max         := 0;
  ScrollBar1.Position    := 0;
  ScrollBar1.SmallChange := 1;
  ScrollBar1.LargeChange := MaxLines;
  ScrollBar1.Kind        := sbVertical;
  ScrollBar1.TabStop     := False;

  ScrollCount  := 0;
  ScrollStart  := 1;
  ScrollOffset := 0;

  AutoScrollTimer          := TTimer.Create(Self);
  AutoScrollTimer.Interval := 100;
  AutoScrollTimer.Enabled  := False;
  AutoScrollTimer.OnTimer  := @AutoScrollTimerTimer;

  WheelTimer          := TTimer.Create(Self);
  WheelTimer.Interval := 16;   { ~1 frame }
  WheelTimer.Enabled  := False;
  WheelTimer.OnTimer  := @WheelTimerTimer;

  Visible   := False;
  VT_Break  := False;
  LoadTextOpen := False;

  Reset_VT;
  SetConsoleConfig(InitFColor, InitBColor);
  BuildGraphicsMap;
end;

{ Scrollback ring-buffer index helper

  Returns the 1-based ring-buffer slot for a given 1-based virtual history
  line index (1 = oldest stored line, ScrollCount = most recently pushed).
  Standard circular-buffer formula:
    slot = ((head - 1 + (virtualIdx - 1)) mod capacity) + 1 }
function ScrollBufIdx(virtualIdx: Integer): Integer; inline;
begin
  Result := ((ScrollStart - 1 + virtualIdx - 1) mod ScrollLines) + 1;
end;

destructor TFconsole.Destroy;
begin
  if Assigned(FDrawer) then FreeAndNil(FDrawer);
  if Assigned(FBitmap) then FreeAndNil(FBitmap);
  inherited Destroy;
end;

{ terminal character processor

  All escape-sequence parsing, cursor movement and screen editing is
  implemented as local (nested) procedures here.  They have direct access to
  the outer parameter 'kar' and to all unit-level variables without needing
  extra parameters. }
procedure VT_ShowChar(kar: Char);

  { Cursor flash helpers — briefly stop the timer, update the cell text, then
    restart.  Stopping the timer prevents a race between the main render and
    the blink tick. }
  procedure TurnOffCursor;
  begin
    with FConsole do
    begin
      Cursortimer.Enabled := False;
      ConsoleText[MCursor.Line, MCursor.Row] := MCursor.Character;
      CellDirty[MCursor.Line, MCursor.Row]   := True;
      Cursortimer.Enabled := True;
    end;
  end;

  procedure TurnOnCursor;
  begin
    with FConsole do
    begin
      Cursortimer.Enabled := False;
      MCursor.Character := ConsoleText[MCursor.Line, MCursor.Row];
      Cursortimer.Enabled := True;
    end;
  end;

  { PushScrollback — save the top scroll-region line into the ring buffer
    before it is overwritten by an upward scroll. }
  procedure PushScrollback;
  var
    Row, Idx: Integer;
  begin
    { Occupied slots span [ScrollStart .. ScrollStart+ScrollCount-1] (mod
      ScrollLines), where ScrollStart points to the oldest entry. }
    if ScrollCount < ScrollLines then
    begin
      Inc(ScrollCount);
      Idx := ScrollBufIdx(ScrollCount);
    end
    else
    begin
      { Buffer full: recycle the oldest slot and advance the head. }
      Idx         := ScrollStart;
      ScrollStart := (ScrollStart mod ScrollLines) + 1;
    end;

    with FConsole do
    begin
      for Row := 1 to MaxRows do
      begin
        ScrollText[Idx][Row]    := ConsoleText[ScrollTop, Row];
        ScrollFColor[Idx][Row]  := ConsoleFColor[ScrollTop, Row];
        ScrollBColor[Idx][Row]  := ConsoleBColor[ScrollTop, Row];
        ScrollStyle[Idx][Row]   := ConsoleStyle[ScrollTop, Row];
        ScrollCharSet[Idx][Row] := ConsoleCharSet[ScrollTop, Row];
      end;
      ScrollBar1.Max := ScrollCount;
      { Keep the scrollbar thumb at the bottom only when not scrolled back. }
      if ScrollOffset = 0 then
        ScrollBar1.Position := ScrollCount;
    end;
  end;

  { scroll_up — push the top scroll-region line into the scrollback buffer,
    shift the region up one row, and blank the bottom line. }
  procedure scroll_up;
  var
    Line, Row: Integer;
  begin
    PushScrollback;
    with FConsole do
    begin
      FullRedraw := True;
      for Line := ScrollTop to ScrollBottom - 1 do
      begin
        ConsoleText[Line]    := ConsoleText[Line + 1];
        ConsoleFColor[Line]  := ConsoleFColor[Line + 1];
        ConsoleBColor[Line]  := ConsoleBColor[Line + 1];
        ConsoleStyle[Line]   := ConsoleStyle[Line + 1];
        ConsoleCharSet[Line] := ConsoleCharSet[Line + 1];
      end;
      for Row := 1 to MaxRows do
      begin
        ConsoleText[ScrollBottom, Row]    := ClearChar;
        ConsoleFColor[ScrollBottom, Row]  := FColor;
        ConsoleBColor[ScrollBottom, Row]  := BColor;
        ConsoleStyle[ScrollBottom, Row]   := CStyle;
        ConsoleCharSet[ScrollBottom, Row] := csASCII;
      end;
      MCursor.Line := ScrollBottom;
      MCursor.Row  := 1;
    end;
  end;

  procedure ClearScreen;
  var
    Line, Row: Integer;
  begin
    FullRedraw  := True;
    BlinkOn     := True;
    BlinkRedraw := False;
    for Line := 1 to MaxLines do
      for Row := 1 to MaxRows do
      begin
        ConsoleText[Line, Row]    := ClearChar;
        ConsoleFColor[Line, Row]  := FColor;
        ConsoleBColor[Line, Row]  := BColor;
        ConsoleStyle[Line, Row]   := CStyle;
        ConsoleCharSet[Line, Row] := csASCII;
      end;
    MCursor.Line := 1;
    MCursor.Row  := 1;
  end;

  procedure Text_On_Console(kar: Char);
  begin
    { Guard: only printable 7-bit ASCII enters the screen buffer. }
    if (Ord(kar) < 32) or (Ord(kar) > 127) then
      Exit;
    ConsoleText[MCursor.Line, MCursor.Row]    := kar;
    ConsoleFColor[MCursor.Line, MCursor.Row]  := FColor;
    ConsoleBColor[MCursor.Line, MCursor.Row]  := BColor;
    ConsoleStyle[MCursor.Line, MCursor.Row]   := CStyle;
    CellDirty[MCursor.Line, MCursor.Row]      := True;
    if UseGraphics then
      ConsoleCharSet[MCursor.Line, MCursor.Row] := csGraphics
    else
      ConsoleCharSet[MCursor.Line, MCursor.Row] := csASCII;

    Inc(MCursor.Row);
    if MCursor.Row > MaxRows then
    begin
      MCursor.Row := 1;
      if (MCursor.Line >= ScrollTop) and (MCursor.Line <= ScrollBottom) then
      begin
        Inc(MCursor.Line);
        if MCursor.Line > ScrollBottom then
          scroll_up;
      end
      else if MCursor.Line < MaxLines then
        Inc(MCursor.Line);
    end;
  end;

  procedure CarriageReturn;
  begin
    MCursor.Row := 1;
  end;

  procedure CursorUp;
  begin
    if MCursor.Line > 1 then Dec(MCursor.Line);
  end;

  procedure CursorDown;
  begin
    if MCursor.Line < MaxLines then Inc(MCursor.Line);
  end;

  procedure CursorRight;
  begin
    if MCursor.Row < MaxRows then Inc(MCursor.Row);
  end;

  procedure CursorLeft;
  begin
    if MCursor.Row > 1 then Dec(MCursor.Row);
  end;

  procedure CursorHome;
  begin
    if DECOriginMode then MCursor.Line := ScrollTop else MCursor.Line := 1;
    MCursor.Row  := 1;
  end;

  procedure DeleteToEndOfLine;
  var
    Row: Integer;
  begin
    for Row := MCursor.Row to MaxRows do
    begin
      ConsoleText[MCursor.Line, Row]   := ClearChar;
      ConsoleFColor[MCursor.Line, Row] := FColor;
      ConsoleBColor[MCursor.Line, Row] := BColor;
      ConsoleStyle[MCursor.Line, Row]  := CStyle;
      CellDirty[MCursor.Line, Row]     := True;
    end;
  end;

  procedure DeleteToBeginOfLine;
  var
    Row: Integer;
  begin
    for Row := 1 to MCursor.Row - 1 do
    begin
      ConsoleText[MCursor.Line, Row]   := ClearChar;
      ConsoleFColor[MCursor.Line, Row] := FColor;
      ConsoleBColor[MCursor.Line, Row] := BColor;
      ConsoleStyle[MCursor.Line, Row]  := CStyle;
      CellDirty[MCursor.Line, Row]     := True;
    end;
  end;

  procedure DeleteLine;
  var
    Row: Integer;
  begin
    for Row := 1 to MaxRows do
    begin
      ConsoleText[MCursor.Line, Row]   := ClearChar;
      ConsoleFColor[MCursor.Line, Row] := FColor;
      ConsoleBColor[MCursor.Line, Row] := BColor;
      ConsoleStyle[MCursor.Line, Row]  := CStyle;
      CellDirty[MCursor.Line, Row]     := True;
    end;
    MCursor.Row := 1;
  end;

  procedure Backspace;
  begin
    if MCursor.Row > 1 then
    begin
      ConsoleText[MCursor.Line, MCursor.Row]   := ClearChar;
      ConsoleFColor[MCursor.Line, MCursor.Row] := FColor;
      ConsoleBColor[MCursor.Line, MCursor.Row] := BColor;
      ConsoleStyle[MCursor.Line, MCursor.Row]  := CStyle;
      CellDirty[MCursor.Line, MCursor.Row]     := True;
      Dec(MCursor.Row);
    end;
  end;

  procedure DeleteCharacter;
  var
    Row: Integer;
  begin
    for Row := MCursor.Row to MaxRows - 1 do
    begin
      ConsoleText[MCursor.Line, Row]   := ConsoleText[MCursor.Line, Row + 1];
      ConsoleFColor[MCursor.Line, Row] := ConsoleFColor[MCursor.Line, Row + 1];
      ConsoleBColor[MCursor.Line, Row] := ConsoleBColor[MCursor.Line, Row + 1];
      ConsoleStyle[MCursor.Line, Row]  := ConsoleStyle[MCursor.Line, Row + 1];
    end;
  end;

  procedure DeleteToEndOfScreen;
  var
    Line, Row: Integer;
  begin
    DeleteToEndOfLine;
    if MCursor.Line < ScrollBottom then
      for Line := MCursor.Line + 1 to ScrollBottom do
        for Row := 1 to MaxRows do
        begin
          ConsoleText[Line, Row]   := ClearChar;
          ConsoleFColor[Line, Row] := FColor;
          ConsoleBColor[Line, Row] := BColor;
          ConsoleStyle[Line, Row]  := CStyle;
        end;
  end;

  procedure CursorDeleteToBeginOfScreen;
  var
    Line, Row: Integer;
  begin
    DeleteToBeginOfLine;
    if MCursor.Line > ScrollTop then
      for Line := ScrollTop to MCursor.Line - 1 do
        for Row := 1 to MaxRows do
        begin
          ConsoleText[Line, Row]   := ClearChar;
          ConsoleFColor[Line, Row] := FColor;
          ConsoleBColor[Line, Row] := BColor;
          ConsoleStyle[Line, Row]  := CStyle;
        end;
  end;

  procedure LineFeed;
  begin
    if (MCursor.Line >= ScrollTop) and (MCursor.Line <= ScrollBottom) then
    begin
      if MCursor.Line = ScrollBottom then
        scroll_up
      else
        Inc(MCursor.Line);
    end
    else if MCursor.Line < MaxLines then
      Inc(MCursor.Line);
  end;

  procedure InsertCharacterRight;
  var
    Row: Integer;
  begin
    for Row := MaxRows downto MCursor.Row + 1 do
    begin
      ConsoleText[MCursor.Line, Row]   := ConsoleText[MCursor.Line, Row - 1];
      ConsoleFColor[MCursor.Line, Row] := ConsoleFColor[MCursor.Line, Row - 1];
      ConsoleBColor[MCursor.Line, Row] := ConsoleBColor[MCursor.Line, Row - 1];
      ConsoleStyle[MCursor.Line, Row]  := ConsoleStyle[MCursor.Line, Row - 1];
    end;
    ConsoleText[MCursor.Line, MCursor.Row]   := ClearChar;
    ConsoleFColor[MCursor.Line, MCursor.Row] := FColor;
    ConsoleBColor[MCursor.Line, MCursor.Row] := BColor;
    ConsoleStyle[MCursor.Line, MCursor.Row]  := CStyle;
  end;

  procedure InsertLineScrollDown;
  var
    Line, Row: Integer;
  begin
    for Line := ScrollBottom downto MCursor.Line + 1 do
    begin
      ConsoleText[Line]   := ConsoleText[Line - 1];
      ConsoleFColor[Line] := ConsoleFColor[Line - 1];
      ConsoleBColor[Line] := ConsoleBColor[Line - 1];
      ConsoleStyle[Line]  := ConsoleStyle[Line - 1];
    end;
    for Row := 1 to MaxRows do
    begin
      ConsoleText[MCursor.Line, Row]   := ClearChar;
      ConsoleFColor[MCursor.Line, Row] := FColor;
      ConsoleBColor[MCursor.Line, Row] := BColor;
      ConsoleStyle[MCursor.Line, Row]  := CStyle;
    end;
  end;

  procedure InsertLineScrollUp;
  var
    Line, Row: Integer;
  begin
    for Line := MCursor.Line to ScrollBottom - 1 do
    begin
      ConsoleText[Line]   := ConsoleText[Line + 1];
      ConsoleFColor[Line] := ConsoleFColor[Line + 1];
      ConsoleBColor[Line] := ConsoleBColor[Line + 1];
      ConsoleStyle[Line]  := ConsoleStyle[Line + 1];
    end;
    for Row := 1 to MaxRows do
    begin
      ConsoleText[ScrollBottom, Row]   := ClearChar;
      ConsoleFColor[ScrollBottom, Row] := FColor;
      ConsoleBColor[ScrollBottom, Row] := BColor;
      ConsoleStyle[ScrollBottom, Row]  := CStyle;
    end;
  end;

  procedure SetCursorPosition(Line, Row: Integer);
  begin
    if DECOriginMode then
    begin
      MCursor.Line := ScrollTop + Line - 1;
      if MCursor.Line > ScrollBottom then
        MCursor.Line := ScrollBottom;
    end
    else
      MCursor.Line := Line;
    MCursor.Row := Row;
    if MCursor.Line > MaxLines then MCursor.Line := MaxLines;
    if MCursor.Row  > MaxRows  then MCursor.Row  := MaxRows;
  end;

  { Scroll primitives — used by ESC D / ESC M (IND / RI) and CursorDownScroll
    / CursorUpScroll. }
  procedure ScrollUp;
  var
    Line, Row: Integer;
  begin
    FullRedraw := True;
    for Line := ScrollTop to ScrollBottom - 1 do
    begin
      ConsoleText[Line]   := ConsoleText[Line + 1];
      ConsoleFColor[Line] := ConsoleFColor[Line + 1];
      ConsoleBColor[Line] := ConsoleBColor[Line + 1];
      ConsoleStyle[Line]  := ConsoleStyle[Line + 1];
    end;
    for Row := 1 to MaxRows do
    begin
      ConsoleText[ScrollBottom, Row]   := ClearChar;
      ConsoleFColor[ScrollBottom, Row] := FColor;
      ConsoleBColor[ScrollBottom, Row] := BColor;
      ConsoleStyle[ScrollBottom, Row]  := CStyle;
    end;
    MCursor.Row  := 1;
    MCursor.Line := ScrollBottom;
  end;

  procedure ScrollDown;
  var
    Line, Row: Integer;
  begin
    FullRedraw := True;
    for Line := ScrollBottom downto ScrollTop + 1 do
    begin
      ConsoleText[Line]   := ConsoleText[Line - 1];
      ConsoleFColor[Line] := ConsoleFColor[Line - 1];
      ConsoleBColor[Line] := ConsoleBColor[Line - 1];
      ConsoleStyle[Line]  := ConsoleStyle[Line - 1];
    end;
    for Row := 1 to MaxRows do
    begin
      ConsoleText[ScrollTop, Row]   := ClearChar;
      ConsoleFColor[ScrollTop, Row] := FColor;
      ConsoleBColor[ScrollTop, Row] := BColor;
      ConsoleStyle[ScrollTop, Row]  := CStyle;
    end;
    MCursor.Row  := 1;
    MCursor.Line := ScrollTop;
  end;

  procedure CursorDownScroll;
  begin
    if MCursor.Line < MaxLines then Inc(MCursor.Line) else ScrollUp;
  end;

  procedure CursorUpScroll;
  begin
    if MCursor.Line > 1 then Dec(MCursor.Line) else ScrollDown;
  end;

  procedure Tab;
  begin
    MCursor.Row := 8 * ((MCursor.Row div 8) + 1);
    if MCursor.Row > MaxRows then MCursor.Row := MaxRows;
  end;


  { Reset the escape-sequence parser to its ground state. }
  procedure BackToNormalState;
  begin
    TerminalState := NormalTerminalState;
    CSIParamCount := 0;
    DECPrivate    := False;
    DesignatingG0 := False;
  end;

  { Handles the character immediately following ESC.
    ESC [  → CSI introducer
    ESC (  → designate G0 character set
    ESC )  → designate G1 character set
    ESC D  → IND: move down one line (scroll if at bottom)
    ESC E  → NEL: next line with carriage return
    ESC M  → RI:  move up one line (scroll if at top) }
  procedure DoESCTerminalState;
  begin
    case kar of
      '[' : TerminalState := CSITerminalState;
      '(' : begin
              DesignatingG0 := True;
              TerminalState := CharSetDesignateState;
            end;
      ')' : begin
              DesignatingG0 := False;
              TerminalState := CharSetDesignateState;
            end;
      'D' : begin CursorDownScroll; BackToNormalState; end;
      'E' : begin CursorDownScroll; CarriageReturn; BackToNormalState; end;
      'M' : begin CursorUpScroll;   BackToNormalState; end;
      else  BackToNormalState;
    end;
  end;

  { Handles the final character in a charset designation sequence.
    ESC ( Ps  → designate G0 with charset Ps
    ESC ) Ps  → designate G1 with charset Ps }
  procedure DoCharSetDesignateState;
  begin
    case kar of
      'B' : if DesignatingG0 then CharsetG0 := csASCII    else CharsetG1 := csASCII;
      '0' : if DesignatingG0 then CharsetG0 := csGraphics else CharsetG1 := csGraphics;
      'A' : if DesignatingG0 then CharsetG0 := csUK       else CharsetG1 := csUK;
      '1', '2' : { Alternate ROM — treated as ASCII, no action needed. } ;
    end;
    UseGraphics := (InvokingG1 and (CharsetG1 = csGraphics))
               or (not InvokingG1 and (CharsetG0 = csGraphics));
    BackToNormalState;
  end;

  { Handles the first character of a CSI parameter field (after ESC [).
    Single-byte final bytes that take no parameters are dispatched here with
    their default values. }
  procedure DoCSITerminalState;
  begin
    case kar of
      '0'..'9' : begin
                   CSIParamCount := 1;
                   CSIParams[1]  := Ord(kar) - $30;
                   TerminalState := CSITerminalStateParameter;
                 end;
      '?'      : begin
                   DECPrivate    := True;
                   CSIParamCount := 1;
                   CSIParams[1]  := 0;
                   TerminalState := CSITerminalStateParameter;
                 end;
      'H', 'f' : begin CursorHome;           BackToNormalState; end;
      'J'      : begin DeleteToEndOfScreen;  BackToNormalState; end;
      'K'      : begin DeleteToEndOfLine;    BackToNormalState; end;
      'M'      : begin InsertLineScrollUp;   BackToNormalState; end;
      'c'      : begin Reset_VT;             BackToNormalState; end;
      's'      : begin
                   SavedCursorLine := MCursor.Line;
                   SavedCursorRow  := MCursor.Row;
                   BackToNormalState;
                 end;
      'u'      : begin
                   MCursor.Line := SavedCursorLine;
                   MCursor.Row  := SavedCursorRow;
                   BackToNormalState;
                 end;
      'm'      : begin
                   { SGR with no args: reset all attributes }
                   FColor := DefaultFColor;
                   BColor := DefaultBColor;
                   CStyle := [];
                   BackToNormalState;
                 end;
      'r'      : begin
                   { DECSTBM with no params: reset scroll region to full screen }
                   ScrollTop    := 1;
                   ScrollBottom := MaxLines;
                   CursorHome;
                   BackToNormalState;
                 end;
      else BackToNormalState;
    end;
  end;

  { Accumulates CSI parameter digits/separators and dispatches on the final
    byte.  Parameters are stored in CSIParams[1..CSIParamCount] (1-based).
    A missing or zero parameter is treated as 1 by the relevant commands. }
  procedure DoCSIParameterTerminalState;
  var
    SColor    : TColor;
    ReportLine: Integer;
    i         : Integer;
  begin
    case kar of
      '0'..'9' :
        begin
          CSIParams[CSIParamCount] :=
            CSIParams[CSIParamCount] * 10 + (Ord(kar) - $30);
          if CSIParams[CSIParamCount] > 999 then
            BackToNormalState
          else
            TerminalState := CSITerminalStateParameter;
        end;

      ';' :
        begin
          Inc(CSIParamCount);
          if CSIParamCount > 16 then
            BackToNormalState
          else
          begin
            CSIParams[CSIParamCount] := 0;
            TerminalState := CSITerminalStateParameter;
          end;
        end;

      { CUP / HVP: move cursor to (line, column) }
      'H', 'f' :
        begin
          SetCursorPosition(CSIParams[1], CSIParams[2]);
          BackToNormalState;
        end;

      { CUU: cursor up n lines }
      'A' :
        begin
          MCursor.Line := MCursor.Line - CSIParams[1];
          if MCursor.Line < 1 then MCursor.Line := 1;
          BackToNormalState;
        end;

      { CUD: cursor down n lines }
      'B' :
        begin
          MCursor.Line := MCursor.Line + CSIParams[1];
          if MCursor.Line > MaxLines then MCursor.Line := MaxLines;
          BackToNormalState;
        end;

      { CUF: cursor forward n columns }
      'C' :
        begin
          MCursor.Row := MCursor.Row + CSIParams[1];
          if MCursor.Row > MaxRows then MCursor.Row := MaxRows;
          BackToNormalState;
        end;

      { CUB: cursor backward n columns }
      'D' :
        begin
          MCursor.Row := MCursor.Row - CSIParams[1];
          if MCursor.Row < 1 then MCursor.Row := 1;
          BackToNormalState;
        end;

      { EL: erase in line }
      'K' :
        begin
          case CSIParams[1] of
            0 : DeleteToEndOfLine;
            1 : DeleteToBeginOfLine;
            2 : DeleteLine;
          end;
          BackToNormalState;
        end;

      { ED: erase in display }
      'J' :
        begin
          case CSIParams[1] of
            0 : DeleteToEndOfScreen;
            1 : CursorDeleteToBeginOfScreen;
            2 : begin ClearScreen; CursorHome; end;
          end;
          BackToNormalState;
        end;

      { SGR: select graphic rendition — colours and text attributes.
        Multiple parameters may be chained with ';', applied in order. }
      'm' :
        begin
          for i := 1 to CSIParamCount do
            case CSIParams[i] of
              { Attribute reset / styles }
              0  : begin FColor := DefaultFColor; BColor := DefaultBColor;
                         CStyle := []; end;
              1  : Include(CStyle, csBold);
              4  : Include(CStyle, csUnderline);
              5  : Include(CStyle, csBlink);
              7  : Include(CStyle, csReverseVideo);
              9  : Include(CStyle, csStrikeOut);
              22 : Exclude(CStyle, csBold);
              24 : Exclude(CStyle, csUnderline);
              25 : Exclude(CStyle, csBlink);
              27 : Exclude(CStyle, csReverseVideo);
              29 : Exclude(CStyle, csStrikeOut);
              { Standard foreground colours (30-37) }
              30 : FColor := RGBToColor(  0,   0,   0);
              31 : FColor := RGBToColor(187,   0,   0);
              32 : FColor := RGBToColor(  0, 187,   0);
              33 : FColor := RGBToColor(229, 229,  16);
              34 : FColor := RGBToColor(  0,   0, 187);
              35 : FColor := RGBToColor(187,   0, 187);
              36 : FColor := RGBToColor(  0, 187, 187);
              37 : FColor := RGBToColor(229, 229, 229);
              { Standard background colours (40-47) }
              40 : BColor := RGBToColor(  0,   0,   0);
              41 : BColor := RGBToColor(187,   0,   0);
              42 : BColor := RGBToColor(  0, 187,   0);
              43 : BColor := RGBToColor(229, 229,  16);
              44 : BColor := RGBToColor(  0,   0, 187);
              45 : BColor := RGBToColor(187,   0, 187);
              46 : BColor := RGBToColor(  0, 187, 187);
              47 : BColor := RGBToColor(229, 229, 229);
              { Bright foreground colours (90-97) }
              90 : FColor := RGBToColor( 85,  85,  85);
              91 : FColor := RGBToColor(255,   0,   0);
              92 : FColor := RGBToColor(  0, 255,   0);
              93 : FColor := RGBToColor(255, 255,   0);
              94 : FColor := RGBToColor(  0,   0, 255);
              95 : FColor := RGBToColor(255,   0, 255);
              96 : FColor := RGBToColor(  0, 255, 255);
              97 : FColor := RGBToColor(255, 255, 255);
              { Bright background colours (100-107) }
              100 : BColor := RGBToColor( 85,  85,  85);
              101 : BColor := RGBToColor(255,   0,   0);
              102 : BColor := RGBToColor(  0, 255,   0);
              103 : BColor := RGBToColor(255, 255,   0);
              104 : BColor := RGBToColor(  0,   0, 255);
              105 : BColor := RGBToColor(255,   0, 255);
              106 : BColor := RGBToColor(  0, 255, 255);
              107 : BColor := RGBToColor(255, 255, 255);
            end;
          BackToNormalState;
        end;

      { DEC private mode set }
      'h' :
        begin
          if DECPrivate then
            case CSIParams[1] of
               6 : DECOriginMode := True;
              25 : CursorVisible := True;
            end;
          BackToNormalState;
        end;

      { DEC private mode reset }
      'l' :
        begin
          if DECPrivate then
            case CSIParams[1] of
               6 : DECOriginMode := False;
              25 : CursorVisible := False;
            end;
          BackToNormalState;
        end;

      { DECSTBM: set top and bottom margins }
      'r' :
        begin
          if CSIParamCount >= 2 then
          begin
            ScrollTop    := CSIParams[1];
            ScrollBottom := CSIParams[2];
          end
          else
          begin
            ScrollTop    := 1;
            ScrollBottom := MaxLines;
          end;
          if ScrollTop    < 1         then ScrollTop    := 1;
          if ScrollBottom > MaxLines  then ScrollBottom := MaxLines;
          if ScrollTop    > ScrollBottom then
          begin
            ScrollTop    := 1;
            ScrollBottom := MaxLines;
          end;
          if DECOriginMode then SetCursorPosition(1, 1) else CursorHome;
          BackToNormalState;
        end;

      { IL: insert n lines }
      'L' :
        begin
          for i := 1 to CSIParams[1] do InsertLineScrollDown;
          BackToNormalState;
        end;

      { DCH: delete n characters at cursor, shifting line left }
      'P' :
        begin
          for i := 1 to CSIParams[1] do DeleteCharacter;
          BackToNormalState;
        end;

      { ICH: insert n blank characters at cursor, shifting line right }
      '@' :
        begin
          for i := 1 to CSIParams[1] do InsertCharacterRight;
          BackToNormalState;
        end;

      { DL: delete n lines at cursor, scrolling region up }
      'M' :
        begin
          for i := 1 to CSIParams[1] do InsertLineScrollUp;
          BackToNormalState;
        end;

      { DSR: device status report }
      'n' :
        begin
          if (not DECPrivate) and (CSIParamCount >= 1) then
            case CSIParams[1] of
              5 : begin
                    { Answer: "terminal OK" }
                    PasteQueue := #$1B + '[0n';
                    PasteIndex := 2;
                    lastKey    := PasteQueue[1];
                    KeyAvailable := True;
                  end;
              6 : begin
                    { Answer: current cursor position.
                      In DECOriginMode the row is reported relative to the scroll region. }
                    if DECOriginMode then
                      ReportLine := MCursor.Line - ScrollTop + 1
                    else
                      ReportLine := MCursor.Line;
                    PasteQueue := #$1B + '[' + IntToStr(ReportLine)
                                  + ';' + IntToStr(MCursor.Row) + 'R';
                    PasteIndex   := 2;
                    lastKey      := PasteQueue[1];
                    KeyAvailable := True;
                  end;
            end;
          BackToNormalState;
        end;

      else BackToNormalState;
    end;
  end;

{ VT_ShowChar body }
begin
  with FConsole do
  begin
    TurnOffCursor;

    if TerminalState = NormalTerminalState then
    begin
      if (Ord(kar) > $1F) and (Ord(kar) <> DEL) then
        Text_On_Console(kar)
      else
        case Ord(kar) of
          $01 : CursorHome;
          $04 : CursorRight;
          $05 : CursorUp;
          BS  : Backspace;
          TB  : Tab;
          LF  : LineFeed;
          FF  : ClearScreen;
          CR  : CarriageReturn;
          $13 : CursorLeft;
          $16 : DeleteToEndOfLine;
          $18 : CursorDown;
          SO  : begin
                  { Invoke G1 character set into GL. }
                  InvokingG1  := True;
                  UseGraphics := CharsetG1 = csGraphics;
                end;
          SI  : begin
                  { Invoke G0 character set into GL. }
                  InvokingG1  := False;
                  UseGraphics := CharsetG0 = csGraphics;
                end;
          ESC : begin
                  { Begin a new escape sequence; reset all parser state so a
                    previous incomplete sequence cannot interfere. }
                  TerminalState := EscapeTerminalState;
                  CSIParamCount := 0;
                  DECPrivate    := False;
                end;
          DEL : Backspace;
        end;
    end
    else if TerminalState = EscapeTerminalState         then DoESCTerminalState
    else if TerminalState = CSITerminalState            then DoCSITerminalState
    else if TerminalState = CSITerminalStateParameter   then DoCSIParameterTerminalState
    else if TerminalState = CharSetDesignateState       then DoCharSetDesignateState;

    TurnOnCursor;
  end;
end;


{ Set the viewport scroll offset to NewOffset, clamped to [0..ScrollCount].
  Both selection endpoints are shifted by the change in offset so that
  highlighted text stays at the same visual rows during a manual scroll.
  Updates the scrollbar thumb, window caption, and repaints the terminal.

  NOTE: During an auto-scroll drag (AutoScrollTimerTimer) only the anchor
  (SelStart) is shifted — that is handled separately. }
procedure ApplyScrollOffset(NewOffset: Integer);
var
  Delta: Integer;
begin
  if NewOffset < 0           then NewOffset := 0;
  if NewOffset > ScrollCount then NewOffset := ScrollCount;
  Delta        := NewOffset - ScrollOffset;
  ScrollOffset := NewOffset;
  FConsole.ScrollBar1.Position := ScrollCount - ScrollOffset;
  if ScrollOffset > 0 then
    FConsole.Caption := 'VT  console (Scroll)'
  else
    FConsole.Caption := 'VT  console';
  FullRedraw := True;
end;

{ Display-line resolution helpers

  Both helpers translate a display line number (1..MaxLines) to a pointer
  into the appropriate backing buffer.

  When ScrollOffset = 0 every display line maps 1-to-1 to ConsoleText.
  When ScrollOffset > 0 the topmost ScrollOffset screen lines show history
  from the ring buffer; the remaining lines still come from ConsoleText.

  virtualIdx is the 1-based ordinal within the stored history:
    1 = oldest entry, ScrollCount = most recently pushed. }
function ResolveTextLine(displayLine: Integer; out pText: PLineBuf;
                         AOffset: Integer = -1): Boolean;
var
  SO, virtualIdx, srcLine: Integer;
begin
  if AOffset < 0 then SO := ScrollOffset else SO := AOffset;
  Result := False;
  if (SO > 0) and (displayLine <= SO) then
  begin
    virtualIdx := ScrollCount - SO + displayLine;
    if (virtualIdx < 1) or (virtualIdx > ScrollCount) then Exit;
    pText := @ScrollText[ScrollBufIdx(virtualIdx)];
  end
  else
  begin
    srcLine := displayLine - SO;
    if (srcLine < 1) or (srcLine > MaxLines) then Exit;
    pText := @ConsoleText[srcLine];
  end;
  Result := True;
end;

{ Like ResolveTextLine but also returns pointers to the parallel colour,
  style and charset buffers.  Used by TextToMon. }
function ResolveDisplayLine(displayLine: Integer;
  out pText   : PLineBuf;
  out pFColor : PColorBuf;
  out pBColor : PColorBuf;
  out pStyle  : PStyleBuf;
  out pCharSet: PCharSetBuf): Boolean;
var
  virtualIdx, bufIdx, srcLine: Integer;
begin
  Result := False;
  if (ScrollOffset > 0) and (displayLine <= ScrollOffset) then
  begin
    virtualIdx := ScrollCount - ScrollOffset + displayLine;
    if (virtualIdx < 1) or (virtualIdx > ScrollCount) then Exit;
    bufIdx   := ScrollBufIdx(virtualIdx);
    pText    := @ScrollText[bufIdx];
    pFColor  := @ScrollFColor[bufIdx];
    pBColor  := @ScrollBColor[bufIdx];
    pStyle   := @ScrollStyle[bufIdx];
    pCharSet := @ScrollCharSet[bufIdx];
  end
  else
  begin
    srcLine := displayLine - ScrollOffset;
    if (srcLine < 1) or (srcLine > MaxLines) then Exit;
    pText    := @ConsoleText[srcLine];
    pFColor  := @ConsoleFColor[srcLine];
    pBColor  := @ConsoleBColor[srcLine];
    pStyle   := @ConsoleStyle[srcLine];
    pCharSet := @ConsoleCharSet[srcLine];
  end;
  Result := True;
end;

{ Convert pixel coordinates to 1-based (Line, Row) cell coordinates.
  Returns True when the pixel lies inside the terminal drawing area. }
function GetCellAtPixel(PX, PY: Integer; out Line, Row: Integer): Boolean;
begin
  Row  := (PX - Border) div RowWidth  + 1;
  Line := (PY - Border) div RowHeight + 1;
  if Row  < 1       then Row  := 1;
  if Row  > MaxRows  then Row  := MaxRows;
  if Line < 1       then Line := 1;
  if Line > MaxLines then Line := MaxLines;
  Result := (PX >= Border) and (PY >= Border) and
            (PX <= Border + MaxRows  * RowWidth) and
            (PY <= Border + MaxLines * RowHeight);
end;

{ Normalise the two selection endpoints into stream (row-major) order.
  SelStart and SelEnd may be in any order; this always yields
  (AStartLine, AStartRow) before (AEndLine, AEndRow). }
procedure NormalizeSelStream(out AStartLine, AStartRow, AEndLine, AEndRow: Integer);
begin
  if (SelStart.Line < SelEnd.Line) or
     ((SelStart.Line = SelEnd.Line) and (SelStart.Row <= SelEnd.Row)) then
  begin
    AStartLine := SelStart.Line;  AStartRow := SelStart.Row;
    AEndLine   := SelEnd.Line;    AEndRow   := SelEnd.Row;
  end
  else
  begin
    AStartLine := SelEnd.Line;    AStartRow := SelEnd.Row;
    AEndLine   := SelStart.Line;  AEndRow   := SelStart.Row;
  end;
end;

{ Return True when cell (Line, Row) falls within the current selection. }
function IsCellSelected(Line, Row: Integer): Boolean;
var
  sLine, sRow, eLine, eRow, AdjLine: Integer;
begin
  if not (Selecting or HasSelection) then Exit(False);
  { When in an active drag (Selecting), coords are always of the current viewport.
    With a selection (HasSelection), convert to the saved coordinate system. }
  if HasSelection and not Selecting then
    AdjLine := Line + SelScrollOffset - ScrollOffset
  else
    AdjLine := Line;
  NormalizeSelStream(sLine, sRow, eLine, eRow);
  if (AdjLine < sLine) or (AdjLine > eLine) then Exit(False);
  if sLine = eLine then
    Result := (Row >= sRow) and (Row <= eRow)
  else if AdjLine = sLine then Result := Row >= sRow
  else if AdjLine = eLine then Result := Row <= eRow
  else Result := True;
end;

{ Feed one character from the paste queue into lastKey, then advance
  PasteIndex.  Resets the queue when exhausted.
  Characters are delivered one per VT_ReadKey poll so the simulated CPU
  sees them arrive at its natural polling rate. }
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
  Each row is right-trimmed before joining because the terminal buffer always
  pads every line with spaces up to MaxRows. }
procedure CopySelection;
var
  sLine, sRow, eLine, eRow : Integer;
  Line, Row                : Integer;
  LineStr, S               : string;
  pText                    : PLineBuf;
begin
  if not HasSelection then Exit;
  NormalizeSelStream(sLine, sRow, eLine, eRow);
  S := '';
  for Line := sLine to eLine do
  begin
    if not ResolveTextLine(Line, pText, SelScrollOffset) then Continue;
    LineStr := '';
    if Line = sLine then
    begin
      if sLine = eLine then
        for Row := sRow to eRow do       LineStr := LineStr + pText^[Row]
      else
        for Row := sRow to MaxRows do    LineStr := LineStr + pText^[Row];
    end
    else if Line = eLine then
      for Row := 1 to eRow do            LineStr := LineStr + pText^[Row]
    else
      for Row := 1 to MaxRows do         LineStr := LineStr + pText^[Row];

    LineStr := TrimRight(LineStr);
    if Line < eLine then LineStr := LineStr + sLineBreak;
    S := S + LineStr;
  end;
  Clipboard.AsText := S;
  HasSelection := False;
  Selecting    := False;
  FullRedraw := True;
end;

{ Extend the selection to cover the whole word that contains (Line, Row).
  A "word" is a maximal run of characters with ordinal value > Space ($20).
  Clicking on a space yields a zero-width selection on that single cell. }
procedure SelectWordAt(Line, Row: Integer);
var
  R    : Integer;
  pText: PLineBuf;
begin
  if not ResolveTextLine(Line, pText) then Exit;
  if pText^[Row] = ' ' then
  begin
    SelStart.Line := Line; SelStart.Row := Row;
    SelEnd        := SelStart;
    Exit;
  end;
  R := Row;
  while (R > 1) and (pText^[R - 1] > ' ') do Dec(R);
  SelStart.Line := Line; SelStart.Row := R;
  R := Row;
  while (R < MaxRows) and (pText^[R + 1] > ' ') do Inc(R);
  SelEnd.Line := Line; SelEnd.Row := R;
end;

{ Return the highest column index in Line that holds a non-blank character,
  or 0 when the entire line is spaces. }
function LineLastNonBlank(pText: PLineBuf): Integer;
var
  C: Integer;
begin
  for C := MaxRows downto 1 do
    if pText^[C] > ' ' then Exit(C);
  Result := 0;
end;

{ VT100 Special Graphics character map }
procedure BuildGraphicsMap;
var
  C: AnsiChar;
begin
  { Default: every character maps to itself (pass-through). }
  for C := Low(AnsiChar) to High(AnsiChar) do
    GGraphicsMap[C] := C;

  { VT100 Special Graphics — UTF-8 multi-byte sequences. }
  GGraphicsMap['_'] := #$C2#$A0;      { NBSP  U+00A0 }
  GGraphicsMap['`'] := #$E2#$97#$86;  { ◆     U+25C6 }
  GGraphicsMap['a'] := #$E2#$96#$92;  { ▒     U+2592 }
  GGraphicsMap['b'] := #$E2#$90#$89;  { ␉     U+2409 }
  GGraphicsMap['c'] := #$E2#$90#$8C;  { ␌     U+240C }
  GGraphicsMap['d'] := #$E2#$90#$8D;  { ␍     U+240D }
  GGraphicsMap['e'] := #$E2#$90#$8A;  { ␊     U+240A }
  GGraphicsMap['f'] := #$C2#$B0;      { °     U+00B0 }
  GGraphicsMap['g'] := #$C2#$B1;      { ±     U+00B1 }
  GGraphicsMap['h'] := #$E2#$90#$A4;  { ␤     U+2424 }
  GGraphicsMap['i'] := #$E2#$90#$8B;  { ␋     U+240B }
  GGraphicsMap['j'] := #$E2#$94#$98;  { ┘     U+2518 }
  GGraphicsMap['k'] := #$E2#$94#$90;  { ┐     U+2510 }
  GGraphicsMap['l'] := #$E2#$94#$8C;  { ┌     U+250C }
  GGraphicsMap['m'] := #$E2#$94#$94;  { └     U+2514 }
  GGraphicsMap['n'] := #$E2#$94#$BC;  { ┼     U+253C }
  GGraphicsMap['o'] := #$E2#$8E#$BA;  { ⎺     U+23BA }
  GGraphicsMap['p'] := #$E2#$8E#$BB;  { ⎻     U+23BB }
  GGraphicsMap['q'] := #$E2#$94#$80;  { ─     U+2500 }
  GGraphicsMap['r'] := #$E2#$8E#$BC;  { ⎼     U+23BC }
  GGraphicsMap['s'] := #$E2#$8E#$BD;  { ⎽     U+23BD }
  GGraphicsMap['t'] := #$E2#$94#$9C;  { ├     U+251C }
  GGraphicsMap['u'] := #$E2#$94#$A4;  { ┤     U+2524 }
  GGraphicsMap['v'] := #$E2#$94#$B4;  { ┴     U+2534 }
  GGraphicsMap['w'] := #$E2#$94#$AC;  { ┬     U+252C }
  GGraphicsMap['x'] := #$E2#$94#$82;  { │     U+2502 }
  GGraphicsMap['y'] := #$E2#$89#$A4;  { ≤     U+2264 }
  GGraphicsMap['z'] := #$E2#$89#$A5;  { ≥     U+2265 }
  GGraphicsMap['{'] := #$CF#$80;      { π     U+03C0 }
  GGraphicsMap['|'] := #$E2#$89#$A0;  { ≠     U+2260 }
  GGraphicsMap['}'] := #$C2#$A3;      { £     U+00A3 }
  GGraphicsMap['~'] := #$C2#$B7;      { ·     U+00B7 }
end;



{ Rendering routine }
procedure TFConsole.TextToMon;
var
  Line, Row               : Integer;
  X, Y                    : Integer;
  TextChar                : AnsiChar;
  OutStr                  : string;
  TempF, TempB            : TColor;
  SwapColor               : TColor;
  pText                   : PLineBuf;
  pFColor, pBColor        : PColorBuf;
  pStyle                  : PStyleBuf;
  pCharSet                : PCharSetBuf;
  LastNonBlank            : Integer;
  HasSelCheck             : Boolean;
  FgBGRA                  : TBGRAPixel;
  Baseline                : Single;
  HasChanges              : Boolean;
begin
  HasChanges := False;
  if FullRedraw then
  begin
    FBitmap.FillRect(0, 0, FBitmap.Width, FBitmap.Height,
                     ColorToBGRA(ColorToRGB(BColor)), dmSet);
    HasChanges := True;
  end
  else
  begin
    for Line := 1 to MaxLines do
      for Row := 1 to MaxRows do
        if CellDirty[Line, Row] or (BlinkRedraw and (csBlink in ConsoleStyle[Line, Row])) then
        begin
          HasChanges := True;
          Break;
        end;
    if not HasChanges then Exit;
  end;

  HasSelCheck := Selecting or HasSelection;

    for Line := 1 to MaxLines do
    begin
      if not ResolveDisplayLine(Line, pText, pFColor, pBColor, pStyle, pCharSet) then
        Continue;

      LastNonBlank := LineLastNonBlank(pText);
      Y := RowHeight * (Line - 1) + Border;
      X := Border;

      for Row := 1 to MaxRows do
      begin
        if not (FullRedraw or CellDirty[Line, Row] or
                  (BlinkRedraw and (csBlink in pStyle^[Row]))) then
        begin
          Inc(X, RowWidth);
          Continue;
        end;

        CellDirty[Line, Row] := False;

        TextChar := pText^[Row];
        if (pCharSet^[Row] = csGraphics) and
           (TextChar >= '_') and (TextChar <= '~') then
          OutStr := GGraphicsMap[TextChar]
        else
          OutStr := TextChar;

        if csReverseVideo in pStyle^[Row] then
        begin
          TempB := pFColor^[Row];
          TempF := pBColor^[Row];
        end
        else
        begin
          TempF := pFColor^[Row];
          TempB := pBColor^[Row];
        end;

        if HasSelCheck and (Row <= LastNonBlank) and IsCellSelected(Line, Row) then
        begin
          { Invert whatever colours are currently active, so selection is always
            distinguishable even on cells that already carry csReverseVideo. }
          SwapColor := TempF;
          TempF     := TempB;
          TempB     := SwapColor;
        end;

        { Blink: on the 'off' phase render the char in background colour. }
        if (csBlink in pStyle^[Row]) and not BlinkOn and (ScrollOffset = 0) then
        begin
          OutStr := '';
          TempB  := BColor;
        end;

        { Background fill }
        FBitmap.FillRect(X, Y, X + RowWidth, Y + RowHeight,
                         ColorToBGRA(ColorToRGB(TempB)), dmSet);

        { Glyph }
        if OutStr <> '' then
        begin
          Baseline := Y + FFontFace.Ascent;
          FgBGRA   := ColorToBGRA(ColorToRGB(TempF));

          FDrawer.DrawText(OutStr, FFontFace, X, Baseline, FgBGRA);

          { Bold: re-draw shifted one pixel right }
          if csBold in pStyle^[Row] then
            FDrawer.DrawText(OutStr, FFontFace, X + 1, Baseline, FgBGRA);

          { Underline }
          if csUnderline in pStyle^[Row] then
            FBitmap.FillRect(X, Round(Baseline) + 1, X + RowWidth,
                             Round(Baseline) + 2, FgBGRA, dmSet);

          { Strikethrough }
          if csStrikeOut in pStyle^[Row] then
            FBitmap.FillRect(X, Y + RowHeight div 2, X + RowWidth,
                             Y + RowHeight div 2 + 1, FgBGRA, dmSet);
        end;

        Inc(X, RowWidth);
      end;
    end;

  FBitmap.InvalidateBitmap;
  FullRedraw := False;
  BlinkRedraw := False;
  ConsoleBox.Invalidate;
end;

procedure TFconsole.ConsoleBoxPaint(Sender: TObject);
begin
  FBitmap.Draw(ConsoleBox.Canvas, 0, 0, False);
end;

procedure TFconsole.timer_ScreenrefreshTimer(Sender: TObject);
begin
  timer_Screenrefresh.Enabled := False;
  TextToMon;
  timer_Screenrefresh.Enabled := True;
end;

{ Blink the cursor and characters with blink attribute }
procedure TFconsole.CursortimerTimer(Sender: TObject);
begin
  if ScrollOffset > 0 then Exit;

  Cursortimer.Enabled := False;

  { Always restore the previous character before toggling. }
  if MCursor.On_Off then
  begin
    ConsoleText[MCursor.Line, MCursor.Row] := MCursor.Character;
    CellDirty[MCursor.Line, MCursor.Row]   := True;
    MCursor.On_Off := False;
  end
  else
  begin
    { Only draw the cursor glyph if cursor is visible. }
    if CursorVisible then
    begin
      MCursor.Character := ConsoleText[MCursor.Line, MCursor.Row];
      ConsoleText[MCursor.Line, MCursor.Row] := CCursor;
      CellDirty[MCursor.Line, MCursor.Row]   := True;
    end;
    MCursor.On_Off := True;
  end;

  { Blink phase follows On_Off regardless of cursor visibility. }
  BlinkOn     := MCursor.On_Off;
  BlinkRedraw := True;

  Cursortimer.Enabled := True;
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
    -1 : if ScrollOffset < ScrollCount then Inc(ScrollOffset);
     1 : if ScrollOffset > 0           then Dec(ScrollOffset);
  end;
  Delta := ScrollOffset - OldOffset;
  if Delta <> 0 then
  begin
    Inc(SelStart.Line, Delta);
    if SelStart.Line < 1 then
      SelStart.Line := 1;
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
    FullRedraw := True;
  end;
end;

{ Scrollbar and mouse-wheel handlers }

procedure TFconsole.ScrollBar1Scroll(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  case ScrollCode of
    scTrack, scPosition, scLineUp, scLineDown, scPageUp, scPageDown:
      ApplyScrollOffset(ScrollCount - ScrollPos);
  end;
end;

procedure TFconsole.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
const
  WheelLines = 3;
var
  Ticks: Integer;
begin
  if ScrollCount = 0 then begin Handled := True; Exit; end;
  { In GTK, WheelDelta comes in as ±1 without scaling; on Windows/macOS it
    comes in as ±120.  We normalize it to 120‑tick units with a minimum of 1. }
  Ticks := Abs(WheelDelta) div 120;
  if Ticks < 1 then Ticks := 1;
  if WheelDelta > 0 then
    Inc(WheelPending, Ticks * WheelLines)
  else
    Dec(WheelPending, Ticks * WheelLines);
  WheelTimer.Enabled := True;
  Handled := True;
end;

procedure TFconsole.WheelTimerTimer(Sender: TObject);
begin
  WheelTimer.Enabled := False;
  if WheelPending = 0 then Exit;
  ApplyScrollOffset(ScrollOffset + WheelPending);
  WheelPending := 0;
end;

{ Mouse selection handlers

  Left-click with multi-click detection:
    1 click  — anchor the start of a drag selection
    2 clicks — select the word under the cursor
    3 clicks — select the entire line
    4+ clicks — select the whole screen; reset counter }
procedure TFconsole.ImageMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  L, R : Integer;
  Now  : DWord;
begin
  if Button <> mbLeft then Exit;

  Now := GetTickCount;
  if Now - LastClickTime <= DWord(GetDoubleClickTime) then
    Inc(ClickCount)
  else
    ClickCount := 1;
  LastClickTime := Now;

  { Any click dismisses an existing selection immediately. }
  if HasSelection then
  begin
    HasSelection := False;
    Selecting    := False;
    FullRedraw   := True;
  end;

  if not GetCellAtPixel(X, Y, L, R) then Exit;

  case ClickCount of
    1 :
      begin
        SelStart.Line := L; SelStart.Row := R;
        SelEnd        := SelStart;
        Selecting     := True;
        FullRedraw    := True;
      end;
    2 :
      begin
        SelectWordAt(L, R);
        HasSelection := True;
        Selecting    := False;
        FullRedraw   := True;
      end;
    3 :
      begin
        SelStart.Line := L; SelStart.Row := 1;
        SelEnd.Line   := L; SelEnd.Row   := MaxRows;
        HasSelection  := True;
        Selecting     := False;
        FullRedraw    := True;
      end;
    else
      begin
        SelStart.Line := 1;        SelStart.Row := 1;
        SelEnd.Line   := MaxLines; SelEnd.Row   := MaxRows;
        HasSelection  := True;
        Selecting     := False;
        ClickCount    := 0;
        FullRedraw    := True;
      end;
  end;
end;

{ Extend the in-progress drag selection to the cell under the pointer.
  When the mouse leaves the terminal area, auto-scroll is triggered. }
procedure TFconsole.ImageMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  L, R       : Integer;
  TermBottom : Integer;
begin
  if not Selecting then Exit;
  TermBottom := Border + MaxLines * RowHeight;
  if GetCellAtPixel(X, Y, L, R) then
  begin
    AutoScrollDir := 0;
    AutoScrollTimer.Enabled := False;
    SelEnd.Line := L;
    SelEnd.Row  := R;
    FullRedraw  := True;
  end
  else if Y < Border then
  begin
    AutoScrollDir := -1;
    if not AutoScrollTimer.Enabled then AutoScrollTimer.Enabled := True;
    SelEnd.Line := 1;
    SelEnd.Row  := 1;
    FullRedraw  := True;
  end
  else if Y > TermBottom then
  begin
    AutoScrollDir := 1;
    if not AutoScrollTimer.Enabled then AutoScrollTimer.Enabled := True;
    SelEnd.Line := MaxLines;
    SelEnd.Row  := MaxRows;
    FullRedraw  := True;
  end
  else
  begin
    AutoScrollDir := 0;
    AutoScrollTimer.Enabled := False;
  end;
end;

{ Finalise the drag: a non-zero extent becomes a confirmed selection;
  a zero-area drag (click without movement) leaves no selection. }
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
    if HasSelection then SelScrollOffset := ScrollOffset;

    FullRedraw   := True;
  end;
end;

{ Handles cursor keys, Delete, and Ctrl combinations.
  Printable characters are NOT consumed here so that Lazarus propagates the
  event to OnUTF8KeyPress, where the OS delivers the correctly translated
  character.  Setting Key=0 suppresses OnUTF8KeyPress. }
procedure TFconsole.FormKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if ScrollOffset > 0 then ApplyScrollOffset(0);
  if HasSelection then
  begin
    HasSelection := False;
    Selecting    := False;
    FullRedraw   := True;
  end;

  { Ignore bare modifier keys (Shift, Ctrl, Alt, CapsLock). }
  if Key in [16, 17, 18, 20] then
  begin
    Key := 0;
    Exit;
  end;

  { Map navigation keys to the WordStar-style control codes the KIM-1 expects. }
  case Key of
    $27 : Key := $04;  { →   → Ctrl-D }
    $25 : Key := $13;  { ←   → Ctrl-S }
    $26 : Key := $05;  { ↑   → Ctrl-E }
    $28 : Key := $18;  { ↓   → Ctrl-X }
    $2E : Key := $08;  { Del → BS     }
  end;

  if ssCtrl in Shift then
    Key := Key - 64;

  { Changed Key produces a control code — process and consume it. }
  if Key < $20 then
  begin
    if (PasteQueue <> '') and (PasteIndex <= Length(PasteQueue)) then
      PasteQueue := PasteQueue + Chr(Key and $7F)
    else
    begin
      lastKey      := Chr(Key and $7F);
      KeyAvailable := True;
    end;
    if Chr(Key and $7F) = Chr(3) then VT_Break := True;
    Key := 0;  { Prevent OnUTF8KeyPress from also firing. }
  end;
end;

{ Receives the final character after full OS layout resolution — Shift, AltGr,
  dead keys, Caps Lock and accents all applied.  Only 7-bit ASCII is forwarded. }
procedure TFconsole.FormUTF8KeyPress(Sender: TObject; var UTF8Key: TUTF8Char);
begin
  if ScrollOffset > 0 then ApplyScrollOffset(0);
  if Length(UTF8Key) <> 1 then Exit;
  if (PasteQueue <> '') and (PasteIndex <= Length(PasteQueue)) then
    PasteQueue := PasteQueue + UTF8Key[1]
  else
  begin
    lastKey      := UTF8Key[1];
    KeyAvailable := True;
  end;
  UTF8Key := '';  { Mark as consumed. }
end;

{ Menu handlers }

procedure TFconsole.FormActivate(Sender: TObject);
begin
  SetFocus;
end;

procedure TFconsole.MColorBackClick(Sender: TObject);
begin
  if ColorDialogFontConsole.Execute then
    SetConsoleConfig(FColor, ColorDialogFontConsole.Color);
end;

procedure TFconsole.MColorfontClick(Sender: TObject);
begin
  if ColorDialogFontConsole.Execute then
    SetConsoleConfig(ColorDialogFontConsole.Color, BColor);
end;

procedure TFconsole.MLFtoCRClick(Sender: TObject);
begin
  {$IFDEF KIM1SIM}
  { GETCH with LF-added patch to serial ACIA }
  memory[$1E5A] := $4C;
  memory[$1E5B] := $0F;
  memory[$1E5C] := $15;
  {$ENDIF}
end;

procedure TFconsole.MNoLFtoCRClick(Sender: TObject);
begin
  {$IFDEF KIM1SIM}
  { GETCH patch to serial ACIA }
  memory[$1E5A] := $4C;
  memory[$1E5B] := $0C;
  memory[$1E5C] := $15;
  {$ENDIF}
end;

procedure TFconsole.mResetConsoleClick(Sender: TObject);
begin

  SetConsoleConfig(DefaultFColor, DefaultBColor);
  Reset_VT;
  {$IFDEF KIM1SIM}
  { GETCH patch to serial ACIA }
  memory[$1E5A] := $4C;
  memory[$1E5B] := $0C;
  memory[$1E5C] := $15;
  {$ENDIF}
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
  S: string;
begin
  S := Clipboard.AsText;
  if S = '' then Exit;
  { Collapse CRLF first so the bare-LF pass does not introduce extra CRs. }
  S := StringReplace(S, #13#10, #13, [rfReplaceAll]);
  S := StringReplace(S, #10,    #13, [rfReplaceAll]);
  PasteQueue := S;
  PasteIndex := 1;
  FeedNextFromQueue;
end;

procedure TFconsole.PopupMenuConsolePopup(Sender: TObject);
begin
  MCopy.Enabled := HasSelection;
end;

{ Public API }

{ Get key from keyboard or file, non-blocking. }
function VT_Readkey: Char;
var
  Kar: Byte;
begin
  if LoadTextOpen then
  begin
    if Eof(LoadTextfile) then
    begin
      CloseFile(LoadTextfile);
      LoadTextOpen := False;
      VT_Readkey   := Chr(LF);
    end
    else
    begin
      Read(LoadTextFile, Kar);
      { Normalise UNIX-style LF-only text files to CR. }
      if Kar = LF then
      begin
        if CRfound then
          Kar := 0
        else
        begin
          Kar     := CR;
          CRfound := False;
        end;
      end
      else if Kar = CR then
        CRfound := True;
      VT_Readkey := Chr(Kar);
    end;

    if VT_Break then
    begin
      CloseFile(LoadTextfile);
      LoadTextOpen := False;
      VT_Readkey   := Chr(CR);
    end;
  end
  else
  begin
    VT_Readkey   := lastKey;
    KeyAvailable := False;
    lastKey      := Chr(0);
    if (PasteQueue <> '') and (PasteIndex <= Length(PasteQueue)) then
      FeedNextFromQueue;
  end;
end;

{ Initialise all terminal state and restart the cursor blink timer. }
procedure Reset_VT;
var
  Line, Row: Integer;
begin
  FColor := DefaultFColor;
  BColor := DefaultBColor;

  for Line := 1 to MaxLines do
    for Row := 1 to MaxRows do
    begin
      ConsoleText[Line, Row]    := ClearChar;
      ConsoleFColor[Line, Row]  := FColor;
      ConsoleBColor[Line, Row]  := BColor;
      ConsoleStyle[Line, Row]   := CStyle;
      ConsoleCharSet[Line, Row] := csASCII;
      CellDirty[Line, Row]      := True;
    end;

  FullRedraw := True;

  MCursor.Line   := 1;
  MCursor.Row    := 1;
  MCursor.On_Off := False;

  CSIParamCount  := 0;
  DECPrivate     := False;
  CursorVisible  := True;
  ScrollTop      := 1;
  ScrollBottom   := MaxLines;
  DECOriginMode  := False;

  FConsole.Cursortimer.Enabled := True;

  lastKey      := Chr(0);
  KeyAvailable := False;

  SavedCursorLine := 0;
  SavedCursorRow  := 0;
  TerminalState   := NormalTerminalState;

  Selecting    := False;
  HasSelection := False;
  PasteQueue   := '';
  PasteIndex   := 0;

  LastClickTime := 0;
  ClickCount    := 0;

  CharsetG0     := csASCII;
  CharsetG1     := csASCII;
  InvokingG1    := False;
  UseGraphics   := False;
  DesignatingG0 := False;

  AutoScrollDir := 0;
  AutoScrollTimer.Enabled := False;

  ScrollCount  := 0;
  ScrollStart  := 1;
  ScrollOffset := 0;

  FConsole.ScrollBar1.Max      := 0;
  FConsole.ScrollBar1.Position := 0;
  FConsole.Caption := 'VT  console';
end;

{ Update the default and per-cell colours, then redraw.
  Cells that were already using the inverse of the old default colours (i.e.
  reverse-video cells) have their colours swapped to maintain the inversion. }
procedure SetConsoleConfig(AFColor, ABColor: TColor);
var
  Line, Row       : Integer;
  Idx, virtualIdx : Integer;
  OldF, OldB      : TColor;
begin
  DefaultFColor := AFColor;
  DefaultBColor := ABColor;
  OldF   := FColor;
  OldB   := BColor;
  FColor := AFColor;
  BColor := ABColor;

  for Line := 1 to MaxLines do
    for Row := 1 to MaxRows do
    begin
      if (ConsoleFColor[Line, Row] = OldB) and
         (ConsoleBColor[Line, Row] = OldF) then
      begin
        { This was a reverse-video cell — keep it inverted. }
        ConsoleFColor[Line, Row] := BColor;
        ConsoleBColor[Line, Row] := FColor;
      end
      else
      begin
        ConsoleFColor[Line, Row] := FColor;
        ConsoleBColor[Line, Row] := BColor;
      end;
    end;

  { Update scrollback buffer colors too }
  for virtualIdx := 1 to ScrollCount do
  begin
    Idx := ScrollBufIdx(virtualIdx);
    for Row := 1 to MaxRows do
    begin
      if (ScrollFColor[Idx][Row] = OldB) and
         (ScrollBColor[Idx][Row] = OldF) then
      begin
        ScrollFColor[Idx][Row] := BColor;
        ScrollBColor[Idx][Row] := FColor;
      end
      else
      begin
        ScrollFColor[Idx][Row] := FColor;
        ScrollBColor[Idx][Row] := BColor;
      end;
    end;
  end;

  FullRedraw := True;
end;

finalization
  { Free module-level objects that have no owning form component. }
  if Assigned(FDrawer)  then FreeAndNil(FDrawer);
  if Assigned(FFontFace) then FreeAndNil(FFontFace);
  if Assigned(FBitmap)  then FreeAndNil(FBitmap);

end.

unit u6502CPU;

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
{
Implements MOS Technology 6502 and Rockwell/WDC 65C02
 Cycle correct

 Hans Otten
 2019           V1.0 basic 6502
 March 2021     V1.1 all 65C02
 September 2021 V1.2 error checked, ADC SBC tests, 65c02 ADC SBC = 6502
}

{$mode objfpc}{$H+}

{ programming model

7         0   7         0      7   6   5   4   3   2   1   0
 ---------    -----------     -------------------------------
|         |  |     A     |   | N | V | 1 | B | D | I | Z | C |
 ---------    -----------     -------------------------------
     Accumulator A              Processor status Register P
  7         0
 -----------
|     X     |   Index register X
 -----------

 7         0
 -----------
|     Y     |   Index register Y
 -----------

15        8   7         0
 ---------     -----------
|  PCH     |  |    PCL    |   Program counter
 ---------     -----------
          8   7         0
       ---    -----------
      | 1 |  |     SP    |
       ---    -----------

C Carry    1  true
Z Zero     1  result is zero
I IRQ      1 if disabled
D          1 if decimal mode
B BRK      1 if BRK instruction
V Overflow 1 if true
N Negative 1 if negative

Caller must supply
function ReadMem(address : word) : byte ;
procedure writeMem(address : word ; data: byte) ;e, address)
}

interface

uses
  Classes, SysUtils;

const
{ Processor  Status bits
  N V c B D I Z C }
  Negativebit = $80;
  Overflowbit = $40;
  Constantbit = $20;
  Breakbit = $10;
  Decimalbit = $08;
  Interruptbit = $04;
  Zerobit = $02;
  Carrybit = $01;

  { Vectors       }
  IRQVectorH: word = $FFFF;
  IRQVectorL: word = $FFFE;
  RSTVectorH: word = $FFFD;
  RSTVectorL: word = $FFFC;
  NMIVectorH: word = $FFFB;
  NMIVectorL: word = $FFFA;
  {reserved bit in Status register, always 1}
  PS_reserved = $30 ;

var
  { Program counter }
  PC: word;
  { registers }
  A: byte; // accumulator
  X: byte; // X-index
  Y: byte; // Y-index

  {  stack pointer }
  SP: byte;
  { cycles elapsed }
  cycles  : integer ;
  { Processor status register
     N V c B D I Z C           }
  Processor_Status: byte ;
  Is65C02: boolean = False ;
  Opcode: byte;

procedure Reset6502;
procedure OneStep65 ;
procedure Onestep6502;
procedure Onestep65C02;
procedure NMI6502;
procedure IRQ;
procedure SetZero(const Value: boolean);
procedure SetNegative(const Value: boolean);
implementation

uses
  utim ;

var
  pageboundary: integer ;
  ea: word; { effective address of addressing mode   }

procedure SetNegative(const Value: boolean);
begin
  if Value then
    Processor_Status := Processor_Status or Negativebit
  else
    Processor_Status := Processor_Status and (not Negativebit);
end ;

procedure SetOverflow(const Value: boolean);
begin
  if Value then
    Processor_Status := Processor_Status or Overflowbit
  else
    Processor_Status := Processor_Status and (not Overflowbit);
end ;

procedure SetConstant(const Value: boolean);
begin
  if Value then
    Processor_Status := Processor_Status or Constantbit
  else
    Processor_Status := Processor_Status and (not Constantbit);
end ;

procedure SetBreak(const Value: boolean);
begin
  if Value then
    Processor_Status := Processor_Status or Breakbit
  else
    Processor_Status := Processor_Status and (not Breakbit);

end ;

procedure SetDecimal(const Value: boolean);
begin
  if Value then
    Processor_Status := Processor_Status or Decimalbit
  else
    Processor_Status := Processor_Status and (not Decimalbit);

end ;

procedure SetInterrupt(const Value: boolean);

begin
  if Value then
    Processor_Status := Processor_Status or Interruptbit
  else
    Processor_Status := Processor_Status and (not Interruptbit);

end ;

procedure SetZero(const Value: boolean);

begin
  if Value then
    Processor_Status := Processor_Status or Zerobit
  else
    Processor_Status := Processor_Status and (not Zerobit);
end ;

procedure SetCarry(const Value: boolean);

begin
  if Value then
    Processor_Status := Processor_Status or Carrybit
  else
    Processor_Status := Processor_Status and (not Carrybit);
end ;

function IsNegative: boolean;

begin
  IsNegative := ((Processor_Status and Negativebit) <> 0);

end ;

function IsOverflowSet: boolean;

begin
  IsOverflowSet := ((Processor_Status and Overflowbit) <> 0);

end ;

function IsConstant: boolean;

begin
  IsConstant := ((Processor_Status and Constantbit) <> 0);
end ;

function IsBreakSet: boolean;

begin
  IsBreakSet := ((Processor_Status and Breakbit) <> 0);
end ;

function IsDecimal: boolean;

begin
  isDecimal := ((Processor_Status and Decimalbit) <> 0);
end ;

function IsInterruptSet: boolean;

begin
  IsInterruptSet := ((Processor_Status and Interruptbit) <> 0);
end ;

function IsZeroSet: boolean;

begin
  IsZeroSet := ((Processor_Status and Zerobit) <> 0);
end ;

function Carryvalue: byte ;

begin
   if (Processor_Status and Carrybit) <> 0
     then
       Carryvalue := 1
     else
       Carryvalue := 0;
end ;

{
  Adddressing modes


  A	Accumulator 	    OPC A	operand is AC (implied single byte instruction)
  abs	absolute	    OPC $LLHH	operand is address $HHLL *
  abs,X	absolute, X-indexed OPC $LLHH,X	operand is address;
                                        effective address is address incremented by X
  abs,Y	absolute, Y-indexed OPC $LLHH,Y	operand is address;
                                        effective address is address incremented by Y
  #	immediate	    OPC #$BB	operand is byte BB
  impl	implied	            OPC	        operand implied
  ind	indirect	    OPC ($LLHH)	operand is address;
                                        effective address is contents of word at address
  indexed indexed           OPC ($LL)   operand is zeropage address;
                                        effective address is word in (LL, LL + 1),
  X,ind	X-indexed, indirect OPC ($LL,X)	operand is zeropage address;
                                        effective address is word in (LL + X, LL + X + 1),
  ind,Y	indirect, Y-indexed OPC ($LL),Y	operand is zeropage address;
                                        effective address is word in (LL, LL + 1)
                                        incremented by Y with carry: C.w($00LL) + Y
  rel	relative	    OPC $BB	branch target is PC + signed offset BB ***
  zpg	zeropage	    OPC $LL	operand is zeropage address
                                        (hi-byte is zero, address = $00LL)
  zpg,X	zeropage, X-indexed OPC $LL,X	operand is zeropage address;
                                        effective address is address incremented
                                        by X without carry **
  zpg,Y	zeropage, Y-indexed OPC $LL,Y	operand is zeropage address;
                                        effective address is address incremented
                                        by Y without carry **

  Accumulator
  With Accumulator addressing the operand is implied as the Accumulator and
  therefore only a single byte forms the instruction.
  The 'address' is A, no generic EAroutine required for the xxxA instructions

  Implied
  Implied addressing uses a single byte instruction.
  The operand is implicitly defined by the instruction.

  Stack
  The Stack may use memory from 0100 to 01FF and the effective address of the
  Stack address mode will always be within this range.

  Immediate                 imm = #$00
  Zeropage                  zp = $00
  ZeropageRelatieve         zpr = $00,$00 (PC-relative)
  Zeropage                  zpx = $00,X
  ZeropageIndexedY          zpy = $00,Y
  ZeropageIndirect          izp = ($00)
  ZeropageIndirectIndexedX  izx = ($00,X)
  ZeropageIndirectIndexedY  izy = ($00),Y
  absolute                  abs = $0000
  absoluteIndexedX          abx = $0000,X
  absoluteIndexedX          aby = $0000,Y
  indirect                  ind = ($0000)
  absoluteIndirectindexedX  iax = ($0000,X)
  PCrelative                rel = $0000 (PC-relative)
}

procedure EAabsolute ;
  { With Absolute addressing the second and third bytes of the instruction
    form the 16-bit address.

    absolute a          $1234
    -------------------------
    Byte    0     1      2
         Opcode  ADL    ADH
    ea        =  ADL    ADH
 }
begin
  ea :=  ReadMem(PC) + (ReadMem(PC + 1) shl 8);
  inc(PC);
  inc(PC);
end ;

procedure EAabsoluteIndexedX ;
  {With the Absolute Indexed with X addressing mode,
   the X Index Register is added to the second and third bytes of the
   instruction to form the 16-bits of the effective address.

   absolute Indexed with X  a,X
   ----------------------------
    Byte    0     1      2
         Opcode  ADL    ADH
                 + X
   ea = ADL + ADH + X
   }
begin
  ea :=  ReadMem(PC) + (ReadMem(PC + 1) shl 8) + X;
  if (ea and $FF00) <> (PC and $FF00) then
    pageboundary := 1
  else
    pageboundary := 0;
  inc(PC);
  inc(PC);
end ;

procedure EAabsoluteIndexedY ;
  { With the Absolute Indexed with Y addressing mode,
    the Y Index Register is added to the second and third bytes of the
    instruction to form the 16-bit effective address.

   absolute Indexed with Y $1234,Y
   -------------------------------
   Byte    0     1      2
        Opcode  ADL    ADH
               + Y
   ea = ADL + ADH + Y
  }
begin
  ea :=  ReadMem(PC) + (ReadMem(PC + 1) shl 8) + Y ;
  if (ea and $FF00) <> (PC and $FF00) then
    pageboundary := 1
  else
    pageboundary := 0;
  inc(PC);
  inc(PC);
end ;


procedure EAabsoluteIndirect6502 ;
  {With the Absolute Indirect addressing mode, the second and third bytes
  of the instruction form an address to a pointer.
  This address mode is only used with the JMP instruction and the
  Program Counter is loaded with the first and second bytes at this pointer.

   absolute Indirect (a)  JMP only
   -------------------------
   Byte    0     1      2
        Opcode  ADL    ADH

   ea =  addresss at (ADL  +   ADH)
   }
  { replicate 6502 page-boundary wraparound bug
   An indirect JMP (xxFF) will fail because the MSB
   will be fetched from  address xx00 instead of page xx+1}

begin
  ea := ReadMem(PC) + (ReadMem(PC + 1) shl 8) ;
  if ea <> $FF then
    ea := ReadMem(ea) + (ReadMem(ea + 1) shl 8)
  else
    ea := ReadMem(ea) + ReadMem(ea and $FF00) shl 8;
end ;

procedure EAabsoluteIndirect65C02 ;
  {With the Absolute Indirect addressing mode, the second and third bytes
  of the instruction form an address to a pointer.
  This address mode is only used with the JMP instruction and the
  Program Counter is loaded with the first and second bytes at this pointer.
   absolute Indirect (a)  JMP only
   -------------------------
   Byte    0     1      2
        Opcode  ADL    ADH

   ea =  addresss at (ADL  +   ADH)
   }

begin
  ea := ReadMem(PC) + (ReadMem(PC + 1) shl 8) ;
  ea := ReadMem(ea) + (ReadMem(ea + 1) shl 8) ;
end ;


{ Accumulator requires no ea calculation }

procedure EAimmediate ;
  {With Immediate Addressing the operand is the second byte of the instruction.

  immediate Addressing #
  -------------------------
   Byte   0     1
        Opcode  Operand

  ea = address of byte following opcode
  }
begin
  ea := PC;
  inc(PC);
end ;

{ implied does not require ea calculation }

procedure EAPCrelative ;
  { The Program Counter relative addressing mode, sometimes referred to as
  Relative Addressing, is used with the Branch instructions.
  If the condition being tested is met, the second byte of the instruction is
  added to the Program Counter and program control is transferred to
  this new memory location.

  Program Counter relative r
  -------------------------
   Byte    0     1
        Opcode  offset
  ea = PC  + offset (2's complement)
  }
begin
  ea := ReadMem(PC);
  inc(PC);
  { 2's complement negative branch, sign extend }
  if (ea and $80) <> 0
    then
      ea := ea or $FF00;
  { check if branch to same page, cycles correction }
  ea := PC + ea ;
  if (ea and $FF00) <> (PC and $FF00)
    then
      pageboundary := 2
    else
      pageboundary := 1;
end ;

{ Stack does not require ea calculation }

procedure EAzeropage ;
  {With Zero Page (zp) addressing the second byte of the instruction
  is the address of the operand in page zero.

  Zeropage (zp)
  -------------------------
   Byte    0     1
        Opcode  zp

  ea = zp
  }
begin
  ea := ReadMem(PC);
  inc(PC);
end ;

procedure EAabsoluteIndexedIndirectX ;
  {With the Absolute Indexed Indirect addressing mode,
  the X Index Register is added to the second and third bytes of the
  instruction to form an address to a pointer.
  This address mode is only used with the JMP instruction and the program
  Counter is loaded with the first and second bytes at this pointer.
  65C02 only

   absolute Indirect (a,x)  JMP only
   -------------------------
   Byte    0     1      2
        Opcode  ADL    ADH

   ea =  addresss at (ADL  +   ADH + X)
   }


begin
  ea := ReadMem(PC) + X + (ReadMem(PC + 1) shl 8) ;
  ea := ReadMem(ea) + (ReadMem(ea + 1) shl 8) ;
end ;

procedure EAzeropageIndexedIndirectX ;
  {The Zero Page Indexed Indirect addressing mode is often referred to as
  Indirect,X. The second byte of the instruction is the zero page address
  to which the X Index Register is added and the result points to the
  low byte of the indirect address.

  Zero Page Indexed Indirect (zp,x)
  ---------------------------------
   Byte    0     1
        Opcode  zp
                +X
  ea address pointed at by ZP + X   }
begin
  ea := (ReadMem(PC) + X) and $00FF;
  ea := (ReadMem(ea) + (ReadMem(ea + 1) shl 8));
  inc(PC);
end ;

procedure EAzeropageIndexedX ;
  {With Zero Page Indexed with X addressing mode, the X Index Register is
  added to the second byte of instruction to form the effective address.

  Zero Page Indexed with X zp,x
  -----------------------------
   Byte    0     1
        Opcode  zp
                +X
  ea = ZP + X
  }
begin
  ea := (ReadMem(PC) + X) and $00FF;
  inc(PC);
end ;

procedure EAzeropageIndexedY ;
  {With Zero Page Indexed with Y addressing, the second byte of the instruction
  is the zero page address to which the Y Index Register is added to form
  the page zero effective address.

  Zero Page Indexed with X zp,y
  -------------------------
   Byte    0     1
        Opcode  zp
                +Y
  ea = ZP + Y    }
begin
  ea := (ReadMem(PC) + Y) and $00FF ;
  inc(PC);
end ;

procedure EAZeropageIndirect;
  {
  Zero Page Indirect (zp)
  -----------------------
   Byte    0     1
        Opcode  zp
  ea = ZP
  }
begin
  ea := ReadMem(PC) and $00FF ;
  ea := ReadMem(ea) + (ReadMem(ea + 1) shl 8) ;
  inc(PC);
end ;

procedure EAzeropageindirectindexedY ;
  { The Zero Page Indirect Indexed with Y addressing mode is often referred
  to as Indirect Y.
  The second byte of the instruction points to the low byte of a two byte
  (16-bit) base address in page zero.
  Y Index Register is added to the base address to form the effective address.

  Zero Page Indirect Indexed with Y (zp), y
  -------------------------
   Byte    0     1
        Opcode  zp
  ea = address at ZP + Y  }
begin
  begin
    ea := ReadMem(PC) and $00FF ;
    ea := ReadMem(ea) + (ReadMem(ea + 1) shl 8) + Y ;
    inc(PC);
  end ;
end ;

procedure stackpushbyte(Value: byte);

begin
  WriteMem($0100 + SP, Value);
  { wrap around on stack page }
  if SP = $00 then
    SP := $FF
  else
    dec(SP);
end ;

function stackpullbyte: byte;

begin
  { wrap around on stack page }
  if Sp = $FF then
    SP := $00
  else
    inc(SP);
  stackpullbyte := ReadMem($0100 + SP);
end ;

procedure Reset6502;

begin
  if IS65C02
    then
      SetDecimal(false) ;
  PC := (ReadMem(RSTVECTORH) shl 8) + ReadMem(RSTVECTORL) ;
  cycles := cycles + 7 ;
end ;

procedure NMI6502;

begin
  SetBreak(false) ;
  StackPushByte((Pc shr 8) and $FF) ;
  StackPushByte(Pc and $FF) ;
  StackPushByte(Processor_Status) ;
  SetInterrupt(True) ;
  Pc := (ReadMem(NMIVECTORH) shl 8) + ReadMem(NMIVECTORL) ;
  cycles := cycles + 7 ;
end ;


procedure IRQ;

begin
  SetBreak(False) ;
  StackPushByte((Pc shr 8) and $FF) ;
  StackPushByte(Pc and $FF) ;
  StackPushByte(Processor_status) ;
  SetInterrupt(True) ;
  Pc := (ReadMem(IRQVECTORH) shl 8) + ReadMem(IRQVECTORL);
  cycles := cycles + 7 ;
end ;

{
In decimal mode, like binary mode, the carry (the C flag) affects the ADC and SBC instructions.

Specifically:

- When the carry is clear, ADC NUM performs the calculation A = A + NUM
- When the carry is set, ADC NUM performs the calculation A = A + NUM + 1
- When the carry is clear, SBC NUM performs the calculation A = A - NUM - 1
- When the carry is set, SBC NUM performs the calculation A = A - NUM
The only difference is that ADC and SBC perform a binary calculation in binary mode,
and perform a BCD calculation in decimal mode.

The ADC and SBC instructions affect the accumulator and the C, N, V, and Z flags.
In decimal mode, the accumulator contains the result of the addition or subtraction, as expected.
In binary mode, after an ADC, the carry is set if the result was greater than 255 ($FF)
and clear otherwise, and after a SBC, the carry is clear if the result was less than 0
and set otherwise.
By contrast, in decimal mode, after an ADC, the carry is set if the result was greater than 99 ($99)
and clear otherwise, and after a SBC, the carry is clear if the result was less than 0 and set otherwise

In binary mode, subtraction has a wraparound effect. For example $00 - $01 = $FF (and the carry is clear).
In decimal mode, there is a similar wraparound effect: $00 - $01 = $99, and the carry is clear.

THE N, V, AND Z FLAGS

ADC and SBC not only affect the carry, but also affect the N, V, and Z flags, even in decimal mode.
In binary mode, the Z flag simply indicates where the result of the instruction is non-zero
(Z flag clear) or zero (Z flag set).
In decimal mode, the Z flag has the same meaning.

In binary mode, the 6502 directly supports the addition and subtraction of twos complement numbers
using the ADC and SBC instructions.
In twos complement representation, $00 to $7F represents 0 to 127 and $80 to $FF represents -128 to -1.

After an ADC or SBC instruction, the N flag is clear when the result is non-negative
(0 to 127) and set when the result is negative (-128 to -1),
and the V flag is clear when the result is in the range -128 to 127 inclusive and set
when the result is outside that range.

On the 6502, only the C flag is valid. The 65C02 and 65816 datasheets state
that the N, V, and Z flags are valid as well as the C flag, but ironically,
given the same inputs (carry flag, accumulator, and operand of the ADC or SBC instruction),
the resulting V flag will be the same on the 6502, 65C02, and 65816
}

procedure OP_ADC_6502 ;
(*

copied from

 Vice 6502

*)
var
  tmp, tmp_value : word ;

begin
  tmp_value := ReadMem(ea) ;
  if IsDecimal
    then
      begin
        tmp := (A and $0F) + (tmp_value and $0F) + CarryValue ;
        if tmp > $09
          then
            tmp := tmp + $06 ;
        if tmp <= $0F
          then
            tmp := (tmp and $0F) + (A and $F0) + (tmp_value and $F0)
          else
            tmp := (tmp and $0F) + (A and $F0) + (tmp_value and $F0) + $10 ;
        SetOverflow( ((A xor tmp) and $80) and not((A Xor tmp_value) and $80) <> 0 ) ;
        if (tmp and $1F0) > $90
	  then
            tmp := tmp + $60;
        SetZero((tmp and $FF) = 0) ;
        SetNegative((tmp and $80) <> 0);
        SetCarry((tmp and $FF0) > $F0) ;
        A := tmp and $FF ;
      end
    else
      begin
        tmp := A + tmp_value + CarryValue ;
         SetCarry(tmp > $FF);
         SetOverflow( ((A xor tmp) and $80) and not((A Xor tmp_value) and $80) <> 0 ) ;
         A := tmp and $FF ;
         SetNegative((A and $80) <> 0);
         SetZero(A = 0) ;
      end ;
end ;

procedure OP_ADC_65C02 ;
(*
  Copied from VICE 65C02
*)

var
  tmp,
  tmp_value : word ;

begin
  tmp_value := ReadMem(ea) ;
  if IsDecimal
    then
      begin
        tmp := (A and $0F) + (tmp_value and $0F) + CarryValue ;
        if tmp > $09
          then
            tmp := tmp + $06 ;
        if tmp <= $0F
          then
            tmp := (tmp and $0F) + (A and $F0) + (tmp_value and $F0)
          else
            tmp := (tmp and $0F) + (A and $F0) + (tmp_value and $F0) + $10 ;
        SetOverflow( ((A xor tmp) and $80) and not((A Xor tmp_value) and $80) <> 0 ) ;
        if (tmp and $1F0) > $90
	  then
            tmp := tmp + $60;
        SetZero((tmp and $FF) = 0) ;
        SetNegative((tmp and $80) <> 0);
        SetCarry((tmp and $FF0) > $F0) ;
        A := tmp and $FF ;
      end
  else
    begin
      tmp := tmp_value + A + Carryvalue ;
      SetOverflow(not (((A xor tmp_value) and $80) and
                        ((A xor tmp) and $80) <> 0 ) ) ;
      SetNegative((tmp and $80) <> 0);
      SetZero((tmp and $FF) = 0) ;
      SetCarry(tmp > $FF)
    end ;
  A := tmp and $FF;
end ;

{ VICE version  }

procedure OP_SBC_6502 ;
var
  src, tmp, tmp_a : word ;

begin
  src  := ReadMem(ea);
  tmp := A - src - (1 - CarryValue) ;
  if IsDecimal
    then
      begin
        tmp_a := (A and $0F) - (src and $0F) - (1 - CarryValue) ;
        if (tmp_a and $10) <> 0
          then
            tmp_a := ((tmp_a - 6) and $0F) or ((A and $F0) - (src and $F0) - $10)
          else
            tmp_a := (tmp_a and $0F) or ((A and $F0) - (src and $F0))  ;
        if (tmp_a and $100) <> 0
          then
            tmp_a := tmp_a - $60;
        setCarry(tmp < $100) ;
        SetZero((tmp and $FF) = 0) ;
        SetNegative( (tmp and $FF) and $80 <> 0 ) ;
        SetOverflow((((A XOR tmp) and $80) and ((A XOR src) and $80)) <> 0 ) ;
        A := tmp_a and $FF ;
      end
    else
      begin
        setCarry(tmp < $100) ;
        SetZero((tmp and $FF) = 0) ;
        SetNegative( (tmp and $FF) and $80 <> 0 ) ;
        SetOverflow((((A XOR tmp) and $80) and ((A XOR src) and $80)) <> 0 ) ;
        A := tmp and $FF ;
      end ;
end ;


{ VICE version }
procedure OP_SBC_65C02 ;
var
  src, tmp, tmp_a : word ;

begin
  src  := ReadMem(ea);
  tmp := A - src - (1 - CarryValue) ;
  if IsDecimal
    then
      begin
        tmp_a := (A and $0F) - (src and $0F) - (1 - CarryValue) ;
        if (tmp_a and $10) <> 0
          then
            tmp_a := ((tmp_a - 6) and $0F) or ((A and $F0) - (src and $F0) - $10)
          else
            tmp_a := (tmp_a and $0F) or ((A and $F0) - (src and $F0))  ;
        if (tmp_a and $100) <> 0
          then
            tmp_a := tmp_a - $60;
        setCarry(tmp < $100) ;
        SetZero((tmp and $FF) = 0) ;
        SetNegative( (tmp and $FF) and $80 <> 0 ) ;
        SetOverflow((((A XOR tmp) and $80) and ((A XOR src) and $80)) <> 0 ) ;
        A := tmp_a and $FF ;
      end
    else
      begin
        setCarry(tmp < $100) ;
        SetZero((tmp and $FF) = 0) ;
        SetNegative( (tmp and $FF) and $80 <> 0 ) ;
        SetOverflow((((A XOR tmp) and $80) and ((A XOR src) and $80)) <> 0 ) ;
        A := tmp and $FF ;
      end ;
end ;
{
var
  src, tmp, tmp2 : word ;

begin
  src := ReadMem(ea);
  tmp := A - src - (1 - CarryValue) ;
  SetOverflow( (((A xor tmp) and $80) and ((A xor src) and $80)) <> 0) ;
  if IsDecimal then
    begin
      if tmp > $FF
        then
          tmp := tmp - $60;
      tmp2 := (A and $0F) - (src and $0F) - (1 - CarryValue) ;
      if tmp2 > $FF
        then
          tmp := tmp -$06 ;
      inc(cycles) ;
    end ;
  SetCarry((A - (1 - CarryValue)) > src) ;
  (*
  setCarry(tmp < $100) ;
  *)
  SetZero((tmp and $FF) = 0) ;
  A := tmp and $FF ;
end ;
}

procedure OP_AND ;
begin
  A := ReadMem(ea) and A;
  SetNegative((A and $80) <> 0);
  SetZero(A = 0);
end ;

procedure OP_ASL ;
var
  M: byte;
begin
  M := ReadMem(ea);
  SetCarry((M and $80) <> 0);
  M := (M shl 1) ;
  SetNegative((M and $80) <> 0);
  SetZero(M = 0);
  WriteMem(ea, M);
end ;

procedure OP_ASLA ;

begin
   SetCarry((A and $80) <> 0);
  A := (A shl 1) ;
  SetNegative((A and $80) <> 0);
  SetZero(A = 0);
end ;

procedure OP_BBR(mask : byte) ;
   {
    Zero Page Relative         BBR
    ---------------------------
    Byte  0      1         2
         Opcode Zeropage Offset

   The second byte of the instruction is the zero page address, and the third byte is the signed branch displacement.
  }
begin
  { get zeropage address }
  ea := ReadMem(pc) ;
  { check mask } ;
  inc(pc) ;
  if (ReadMem(ea) and mask) = 0
    then
      begin
        EAPCrelative ;
        pc := ea ;
      end
    else
      inc(pc) ;
end ;

procedure OP_BBS(mask : byte) ;
   {
    Zero Page Relative
    ---------------------------
    Byte  0      1         2
         Opcode Zeropage Offset

   The second byte of the instruction is the zero page address, and the third byte is the signed branch displacement.
  }
begin
   { get zeropage address }
  ea := ReadMem(pc) ;
  { check mask } ;
  inc(pc) ;
  if (ReadMem(ea) and mask) = 0
    then
      inc(pc)
    else
      begin
        EAPCrelative ;
        PC := ea ;
      end
end ;

procedure OP_BCC ;
begin
  if Carryvalue = 0
    then
      PC := ea ;
end ;

procedure OP_BCS ;
begin
  if Carryvalue = 1
    then
      PC := ea ;
end ;

procedure OP_BEQ ;

begin
  if IsZeroSet
    then
      pc := ea ;
end ;

procedure OP_BIT ;
var
  M: byte;
begin
  M := Readmem(ea) ;
  SetNegative((M and $80) <> 0);
  SetOverflow((M and $40) <> 0);
  SetZero((M and A) = 0) ;
end ;

procedure OP_BMI ;
begin
  if IsNegative
    then
      PC := ea ;
end ;

procedure OP_BRA ;
begin
  PC := ea ;
end ;

procedure OP_BNE ;
begin
  if not (IsZeroSet)
    then
      PC := ea ;
end ;

procedure OP_BPL ;
begin
  if not IsNegative
    then
      PC := ea ;
end ;

procedure OP_BRK ;
begin
  { push PC +2 on stack, requires byte after BRK for RTI }
  inc(PC);
  StackPushByte((PC shr 8) and $FF);
  StackPushByte(PC and $FF);
  StackPushByte(Processor_status or breakbit or PS_reserved);
  SetInterrupt(True);
  if Is65C02
    then
      SetDecimal(false) ;
  PC := (ReadMem(IRQVECTORH) shl 8) + ReadMem(IRQVECTORL);
  cycles := cycles + 7 ;
end ;

procedure OP_BVC ;
begin
  if not IsOverflowSet
    then
      PC := ea ;
end ;

procedure OP_BVS ;
begin
  if IsOverflowSet
    then
      PC := ea;
end ;

procedure OP_CLC  ;
begin
  SetCarry(False);
end ;

procedure OP_CLD  ;
begin
  SetDecimal(False);
end ;

procedure OP_CLV ;
begin
 SetOverflow(False);
end ;

procedure OP_CLI ;
begin
  SetInterrupt(False);
end ;

procedure OP_CMP ;
var
  Tmp : integer;
begin
  Tmp := A - ReadMem(ea);
  SetCarry(not(Tmp < 0));
  SetNegative((Tmp and $80) <> 0);
  SetZero((Tmp and $FF) = 0);
end ;

procedure OP_CPY ;
var
  Tmp: integer;
begin
  Tmp := Y - ReadMem(ea);
  SetCarry(not(Tmp < 0));
  SetNegative((Tmp and $80) <> 0);
  SetZero((Tmp and $FF) = 0);
end ;

procedure OP_CPX ;
var
  Tmp: integer;
begin
  Tmp := X - ReadMem(ea);
  SetCarry(not(Tmp < 0));
  SetNegative((Tmp and $80) <> 0);
  SetZero((Tmp and $FF) = 0);
end ;

procedure OP_DEC ;
var
  M: byte;
begin
  M := ReadMem(ea);
  dec(M);
  SetNegative((M and $80) <> 0);
  SetZero(M = 0);
  WriteMem(ea, M);
end ;

procedure OP_DEC_A ;
begin
  dec(A);
  SetNegative((A and $80) <> 0);
  SetZero(A = 0);
end ;

procedure OP_DEX ;
begin
  dec(X);
  SetNegative((X and $80) <> 0);
  SetZero(X = 0);
end ;

procedure OP_DEY ;
begin
  dec(Y);
  SetNegative((Y and $80) <> 0);
  SetZero(Y = 0);
end ;

procedure OP_EOR ;
begin
  A := A xor ReadMem(ea);
  SetNegative((A and $80) <> 0);
  SetZero(A = 0);
end ;

procedure OP_INC ;
var
  M: byte;
begin
  M := ReadMem(ea);
  inc(M);
  SetNegative((M and $80) <> 0);
  SetZero(M = 0);
  WriteMem(ea, M);
end ;

procedure OP_INX ;
begin
  inc(X);
  SetNegative((X and $80) <> 0);
  SetZero(X = 0);
end ;

procedure OP_INC_A ;
begin
  inc(A);
  SetNegative((A and $80) <> 0);
  SetZero(A = 0);
end ;

procedure OP_INY ;
begin
  inc(Y);
  SetNegative((Y and $80) <> 0);
  SetZero(Y = 0);
end ;

procedure OP_JSR ;
begin
  dec(Pc);
  StackPushbyte((PC shr 8) and $FF);
  StackPushbyte(PC and $FF);
  PC := ea;
end ;

procedure OP_LDA ;
begin
  A := ReadMem(ea);
  SetNegative((A and $80) <> 0);
  SetZero(A = 0);
end ;

procedure OP_LDX ;
begin
  X := ReadMem(ea);
  SetNegative((X and $80) <> 0);
  SetZero(X = 0);
end ;

procedure OP_LDY ;
begin
  Y := ReadMem(ea);
  SetNegative((Y and $80) <> 0);
  SetZero(Y = 0);
end ;

procedure OP_LSR ;
var
  M: byte;
begin
  M := ReadMem(ea);
  SetCarry((M and $01) <> 0);
  M := M shr 1;
  SetNegative(False);
  SetZero(M = 0);
  WriteMem(ea, M);
end ;

procedure OP_LSRA ;
begin
  SetCarry((A and $01) <> 0);
  A := A shr 1;
  SetNegative(False);
  SetZero(A = 0);
end ;

procedure OP_ORA ;
begin
  A := ReadMem(ea) or A ;
  SetNegative((A and $80) <> 0);
  SetZero(A = 0);
end ;

procedure OP_PHA ;
begin
  StackPushByte(A);
end ;

procedure OP_PHX ;
begin
  StackPushByte(X);
end ;

procedure OP_PHY ;
begin
  StackPushByte(Y);
end ;

procedure OP_PHP ;
begin
  StackPushByte(Processor_status OR PS_reserved);
end ;

procedure OP_PLA ;
begin
  A := StackPullByte;
  SetNegative((A and $80) <> 0);
  SetZero(A = 0);
end ;

procedure OP_PLX ;
begin
  X := StackPullByte;
  SetNegative((X and $80) <> 0);
  SetZero(X = 0);
end ;

procedure OP_PLY ;
begin
  Y := StackPullByte;
  SetNegative((Y and $80) <> 0);
  SetZero(Y = 0);
end ;

procedure OP_PLP ;
begin
  Processor_status := StackPullByte;
end ;

procedure OP_RMB0;
begin
   WriteMem(ea, ReadMem(ea) and %11111110) ;
end ;

procedure OP_RMB1;
begin
  WriteMem(ea, ReadMem(ea) and %11111101) ;
end ;

procedure OP_RMB2;
begin
  WriteMem(ea, ReadMem(ea) and %11111011) ;
end ;

procedure OP_RMB3;
begin
  WriteMem(ea, ReadMem(ea) and %11110111) ;
end ;

procedure OP_RMB4;

begin
  WriteMem(ea, ReadMem(ea) and %11101111) ;
end ;

procedure OP_RMB5;

begin
  WriteMem(ea, ReadMem(ea) and %11011111) ;
end ;

procedure OP_RMB6;

begin
  WriteMem(ea, ReadMem(ea) and %10111111) ;
end ;

procedure OP_RMB7;

begin
  WriteMem(ea, ReadMem(ea) and %01111111) ;
end ;

procedure OP_ROL ;
var
  M: word;
begin
  M := ReadMem(ea);
  M := M shl 1;
  if Carryvalue = 1
    then
      M := M or $01;
  SetCarry(M > $FF);
  M := M and $FF;
  SetNegative((M and $80) <> 0);
  SetZero(M = 0);
  WriteMem(ea, M);
end ;

procedure OP_ROL_ACC ;
var
  M: word;
begin
  M := A;
  M := M shl 1;
  if Carryvalue = 1
    then
      M := M or $01;
  SetCarry(M > $FF);
  M := M and $FF;
  SetNegative((M and $80) <> 0);
  SetZero(M = 0);
  A := M;
end ;

procedure OP_ROR ;
var
  M: word;
begin
  M := ReadMem(ea);
  if Carryvalue = 1
    then
      M := M or $100;
  SetCarry((M and $01) <> 0);
  M := M shr 1;
  M := M and $FF;
  SetNegative((M and $80) <> 0);
  SetZero(M = 0);
  WriteMem(ea, M);
end ;

procedure OP_RORA ;
var
  M: word;
begin
  M := A;
  if Carryvalue = 1
    then
      M := M or $100;
  SetCarry((M and $01) <> 0);
  M := M shr 1;
  M := M and $FF;
  SetNegative((M and $80) <> 0);
  SetZero(M = 0);
  A := M;
end ;

procedure OP_RTI ;

var
  HighPC, LowPC: byte;

begin
  Processor_Status := StackPullbyte;
  LowPC := StackPullbyte;
  HighPC := StackPullbyte;
  PC := (HighPC shl 8) or LowPC;
end ;

procedure OP_RTS ;
var
  HighPC, LowPC: byte;

begin
  LowPC := StackPullbyte;
  HighPC := StackPullbyte;
  PC := ((HighPC shl 8) or LowPC) + 1;
end ;


procedure OP_SEC ;

begin
  SetCarry(True);
end ;

procedure OP_SED ;

begin
  SetDecimal(True);
end ;

procedure OP_SEI ;

begin
  SetInterrupt(True);
end ;

procedure OP_STA ;

begin
  WriteMem(ea, A);
end ;

procedure OP_STX ;

begin
  WriteMem(ea, X);
end ;

procedure OP_STY ;
begin
  WriteMem(ea, Y);
end ;

procedure OP_STZ ;
begin
  WriteMem(ea, 0);
end ;

procedure OP_STP;
begin

end ;

procedure OP_WAIT;
begin

end ;

procedure OP_TRB  ;
var
  M: byte;
  Res: byte;
begin
  M := ReadMem(ea);
  Res := M AND NOT A;
  SetZero(Res = 0);
  WriteMem(ea, Res);
end ;

procedure OP_TSB;
var
  M: byte;
  Res: byte;
begin
  M := ReadMem(ea);
  Res := M or A;
  SetZero(Res = 0);
  WriteMem(ea, Res);
end ;

procedure OP_TAX ;
begin
  X := A;
  SetNegative((X and $80) <> 0);
  SetZero(X = 0);
end ;

procedure OP_TAY ;

begin
  Y := A;
  SetNegative((Y and $80) <> 0);
  SetZero(Y = 0);
end ;

procedure OP_TSX ;

begin
  begin
    X := SP;
    SetNegative((X and $80) <> 0);
    SetZero(X = 0);
  end ;
end ;

procedure OP_TXA ;

begin
  A := X ;
  SetNegative((A and $80) <> 0);
  SetZero(A = 0);
end ;

procedure OP_TYA ;

begin
  A := Y ;
  SetNegative((A and $80) <> 0);
  SetZero(A = 0);
end ;

procedure OP_TXS ;

begin
  SP := X;
end ;

procedure OP_SMB0 ;

begin
  WriteMem(ea, ReadMem(ea) or %00000001) ;
end ;

procedure OP_SMB1 ;

begin
  WriteMem(ea, ReadMem(ea) or %00000010) ;
end ;

procedure OP_SMB2 ;

begin
  WriteMem(ea, ReadMem(ea) or %00000100) ;
end ;

procedure OP_SMB3 ;

begin
  WriteMem(ea, ReadMem(ea) or %00001000) ;
end ;

procedure OP_SMB4 ;

begin
  WriteMem(ea, ReadMem(ea) or %00010000) ;
end ;

procedure OP_SMB5 ;

begin
  WriteMem(ea, ReadMem(ea) or %00100000) ;
end ;

procedure OP_SMB6 ;

begin
  WriteMem(ea, ReadMem(ea) or %01000000) ;
end ;

procedure OP_SMB7 ;

begin
  WriteMem(ea, ReadMem(ea) or %10000000) ;
end ;

procedure OP_illegal ;

begin
  { do nothing for now, will be reset }
end ;

procedure onestep6502;
{ execute one 6502 instruction at current PC                      }
{ on return PC points to next instruction in memory               }
{ cycles are number of cycles spent in executing this instruction }

{ execute one instruction at current PC                           }
    { returns
         PC pointing to next instruction
         flags result of instruction execution
         cycles number of machine cycles executed }

    { effective address and cycle based upon addressing mode
      timing cpu dependent 6502 or 65c02                              }

begin
  cycles := 0 ;
  opcode := Readmem(PC);
  inc(PC);
  case opcode of
    $00:  begin       { BRK implied                   }
            OP_BRK;
            cycles := cycles + 7;
          end ;
    $01:  begin       { ORA ZeropageIndexedIndirectX  }
            EAzeropageIndexedIndirectX;
            OP_ORA;
            cycles := cycles + 6;
          end ;
    $02:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $03:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $04:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $05:  begin       { ORA Zeropage                  }
            EAZeropage;
            OP_ORA;
            cycles := cycles + 3;
          end ;
    $06:  begin       { ASL Zeropage                  }
            EAzeropage;
            OP_ASL;
            cycles := cycles + 5;
          end ;
    $07:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $08:  begin       { PHP Stack                     }
            OP_PHP;
            cycles := cycles + 3;
          end ;
    $09:  begin       { ORA immediate                 }
            EAimmediate;
            OP_ORA ;
            cycles := cycles + 2;
          end ;
    $0A:  begin       { ASL Accumulator               }
            OP_ASLA ;
            cycles := cycles + 2;
          end ;
    $0B:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $0C:  begin       { ??? implied                   }
            OP_illegal;
           end ;
    $0D:  begin       { ORA absolute                  }
            EAabsolute;
            OP_ORA;
            cycles := cycles + 4;
          end ;
    $0E:  begin       { ASL absolute                  }
            EAabsolute;
            OP_ASL;
            cycles := cycles + 6;
          end ;
    $0F:  begin       { ??? implied                   }
             OP_illegal;
          end ;
    $10:  begin       { BPL ProgramCounterRelative    }
            EAPCrelative;
            OP_BPL;
            cycles := cycles + 2 + pageboundary;
           end ;
    $11:  begin       { ORA ZeropageIndirectIndexedY  }
            EAzeropageIndirectIndexedY;
            OP_ORA;
            cycles := cycles + 5 + pageboundary;
          end ;
    $12:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $13:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $14:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $15:  begin       { ORA ZeroPageIndexedX          }
            EAzeroPageIndexedX;
            OP_ORA;
            cycles := cycles + 4;
          end ;
    $16:  begin       { ASL ZeroPageIndexedX          }
            EAzeroPageIndexedX;
            OP_ASL;
            cycles := cycles + 6;
          end ;
    $17:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $18:  begin       { CLC implied                   }
            OP_CLC;
            cycles := cycles + 2;
          end ;
    $19:  begin       { ORA absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_ORA;
            cycles := cycles + 4;
          end ;
    $1A:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $1B:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $1C:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $1D:  begin       { ORA absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_ORA;
            cycles := cycles + 4 + pageboundary;
          end ;
    $1E:  begin       { ASL absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_ASL;
            cycles := cycles + 7;
          end ;
    $1F:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $20:  begin       { JSR absolute                  }
            EAabsolute;
            OP_JSR;
            cycles := cycles + 6;
          end ;
    $21:  begin       { AND ZeropageIndexedIndirectX  }
            EAZeropageIndexedIndirectX;
            OP_AND;
            cycles := cycles + 6;
          end ;
    $22:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $23:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $24:  begin       { BIT Zeropage                  }
            EAzeropage;
            OP_BIT;
            cycles := cycles + 3;
          end ;
    $25:  begin       { AND Zeropage                  }
            EAzeropage;
            OP_AND;
            cycles := cycles + 3;
          end ;
    $26:  begin       { ROL Zeropage                  }
            EAzeropage;
            OP_ROL;
            cycles := cycles + 5;
          end ;
    $27:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $28:  begin       { PLP Stack                     }
            OP_PLP;
            cycles := cycles + 4;
          end ;
    $29:  begin       { AND immediate                 }
            EAimmediate;
            OP_AND;
            cycles := cycles + 2;
          end ;
    $2A:  begin       { ROL Accumulator               }
            OP_ROL_ACC;
            cycles := cycles + 2;
          end ;
    $2B:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $2C:  begin       { BIT absolute                  }
            EAabsolute;
            OP_BIT;
            cycles := cycles + 4;
          end ;
    $2D:  begin       { AND absolute                  }
            EAabsolute;
            OP_AND;
            cycles := cycles + 4;
          end ;
    $2E:  begin       { ROL absolute                  }
            EAabsolute;
            OP_ROL;
            cycles := cycles + 6;
          end ;
    $2F:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $30:  begin       { BMI ProgramCounterRelative    }
            EAPCrelative;
            OP_BMI;
            cycles := cycles + 2 + pageboundary;
          end ;
    $31:  begin       { AND ZeropageIndirectIndexedY  }
            EAZeropageIndirectIndexedY;
            OP_AND;
            cycles := cycles + 5 + pageboundary;
          end ;
    $32:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $33:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $34:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $35:  begin       { AND ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_AND;
            cycles := cycles + 4;
          end ;
    $36:  begin       { ROL ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_ROL;
            cycles := cycles + 6;
          end ;
    $37:  begin       { ??? implied                   }
            OP_illegal;
           end ;
    $38:  begin       { SEC implied                   }
            OP_SEC;
            cycles := cycles + 2;
          end ;
    $39:  begin       { AND absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_AND;
            cycles := cycles + 4 + pageboundary;
          end ;
    $3A:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $3B:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $3C:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $3D:  begin       { AND absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_AND;
            cycles := cycles + 4 + pageboundary;
          end ;
    $3E:  begin       { ROL absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_ROL;
            cycles := cycles + 6 + pageboundary;
          end ;
    $3F:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $40:  begin       { RTI implied                   }
            OP_RTI;
           cycles := cycles + 6;
          end ;
    $41:  begin       { EOR ZeropageIndexedIndirectX  }
            EAZeropageIndexedIndirectX;
            OP_EOR;
            cycles := cycles + 6;
          end ;
    $42:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $43:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $44:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $45:  begin       { EOR Zeropage                  }
            EAZeropage ;
            OP_EOR;
            cycles := cycles + 3;
          end ;
    $46:  begin       { LSR Zeropage                  }
            EAZeropage;
            OP_LSR;
            cycles := cycles + 5;
          end ;
    $47:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $48:  begin       { PHA Stack                     }
            OP_PHA;
            cycles := cycles + 3;
          end ;
    $49:  begin       { EOR immediate                 }
            EAimmediate;
            OP_EOR;
            cycles := cycles + 2;
          end ;
    $4A:  begin       { LSR Accumulator               }
            OP_LSRA;
            cycles := cycles + 2;
          end ;
    $4B:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $4C:  begin       { JMP absolute                  }
            EAabsolute;
            PC := ea;
            cycles := cycles + 3;
          end ;
    $4D:  begin       { EOR absolute                  }
            EAabsolute;
            OP_EOR;
            cycles := cycles + 4;
          end ;
    $4E:  begin       { LSR absolute                  }
            EAabsolute;
            OP_LSR;
            cycles := cycles + 6;
          end ;
    $4F:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $50:  begin       { BVC ProgramCounterRelative    }
            EAPCrelative;
            OP_BVC;
            cycles := cycles + 2 + pageboundary;
          end ;
    $51:  begin       { EOR ZeropageIndirectIndexedY  }
            EAZeropageIndirectIndexedY;
            OP_EOR;
            cycles := cycles + 5 + pageboundary;
          end ;
    $52:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $53:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $54:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $55:  begin       { EOR ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_EOR;
            cycles := cycles + 4;
          end ;
    $56:  begin       { LSR ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_LSR;
            cycles := cycles + 6;
          end ;
    $57:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $58:  begin       { CLI implied                   }
            OP_CLI;
            cycles := cycles + 2;
          end ;
    $59:  begin       { EOR absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_EOR;
            cycles := cycles + 4 + pageboundary;
          end ;
    $5A:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $5B:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $5C:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $5D:  begin       { EOR absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_EOR;
            cycles := cycles + 4 + pageboundary;
          end ;
    $5E:  begin       { LSR absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_LSR;
            cycles := cycles + 7;
          end ;
    $5F:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $60:  begin       { RTS Stack                     }
            OP_RTS;
            cycles := cycles + 6;
          end ;
    $61:  begin       { ADC ZeropageIndexedIndirectX  }
            EAZeropageIndexedIndirectX;
            OP_ADC_6502;
            cycles := cycles + 6;
          end ;
    $62:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $63:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $64:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $65:  begin       { ADC Zeropage                  }
            EAzeropage;
            OP_ADC_6502;
            cycles := cycles + 3;
          end ;
    $66:  begin       { ROR Zeropage                  }
            EAzeropage;
            OP_ROR;
            cycles := cycles + 5;
          end ;
    $67:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $68:  begin       { PLA Stack                     }
            OP_PLA;
            cycles := cycles + 4;
          end ;
    $69:  begin       { ADC immediate                 }
            EAimmediate;
            OP_ADC_6502;
            cycles := cycles + 2;
          end ;
    $6A:  begin       { ROR Accumulator               }
            OP_RORA;
            cycles := cycles + 2;
          end ;
    $6B:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $6C:  begin       { JMP AbsoluteIndirect          }
            EAAbsoluteIndirect6502;
            PC := ea;
            cycles := cycles + 5;
          end ;
    $6D:  begin       { ADC Absolute                  }
            EAabsolute;
            OP_ADC_6502;
            cycles := cycles + 4;
          end ;
    $6E:  begin       { ROR absolute                  }
            EAabsolute;
            OP_ROR;
            cycles := cycles + 6;
          end ;
    $6F:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $70:  begin       { BVS ProgramCounterRelative    }
            EAPCrelative;
            OP_BVS;
            cycles := cycles + 2 + pageboundary;
          end ;
    $71:  begin       { ADC ZeropageIndirectIndexedY  }
            EAZeropageIndirectIndexedY;
            OP_ADC_6502;
            cycles := cycles + 5 + pageboundary;
          end ;
    $72:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $73:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $74:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $75:  begin       { ADC ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_ADC_6502;
            cycles := cycles + 4;
          end ;
    $76:  begin       { ROR ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_ROR;
            cycles := cycles + 6;
          end ;
    $77:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $78:  begin       { SEI implied                   }
            OP_SEI;
            cycles := cycles + 2;
          end ;
    $79:  begin       { ADC absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_ADC_6502;
            cycles := cycles + 4 + pageboundary;
          end ;
    $7A:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $7B:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $7C:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $7D:  begin       { ADC absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_ADC_6502;
            cycles := cycles + 4 + pageboundary;
          end ;
    $7E:  begin       { ROR absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_ROR;
            cycles := cycles + 7;
          end ;
    $7F:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $80:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $81:  begin       { STA ZeropageIndexedIndirectX  }
            EAZeropageIndexedIndirectX;
            OP_STA;
            cycles := cycles + 6;
          end ;
    $82:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $83:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $84:  begin       { STY Zeropage                  }
            EAzeropage;
            OP_STY;
            cycles := cycles + 3;
          end ;
    $85:  begin       { STA Zeropage                  }
            EAzeropage;
            OP_STA;
            cycles := cycles + 3;
          end ;
    $86:  begin       { STX Zeropage                  }
            EAzeropage;
            OP_STX;
            cycles := cycles + 3;
          end ;
    $87:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $88:  begin       { DEY implied                   }
            OP_DEY;
            cycles := cycles + 2;
          end ;
    $89:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $8A:  begin       { TXA implied                   }
            OP_TXA;
            cycles := cycles + 2;
          end ;
    $8B:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $8C:  begin       { STY absolute                  }
            EAabsolute;
            OP_STY;
            cycles := cycles + 4;
          end ;
    $8D:  begin       { STA absolute                  }
            EAabsolute;
            OP_STA;
            cycles := cycles + 4;
          end ;
    $8E:  begin       { STX absolute                  }
            EAabsolute;
            OP_STX;
            cycles := cycles + 4;
          end ;
    $8F:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $90:  begin       { BCC ProgramCounterRelative    }
            EAPCrelative;
            OP_BCC;
            cycles := cycles + 2 + pageboundary;
          end ;
    $91:  begin       { STA ZeropageIndirectIndexedY  }
            EAZeropageIndirectIndexedY;
            OP_STA;
            cycles := cycles + 6;
          end ;
    $92:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $93:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $94:  begin       { STY ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_STY;
            cycles := cycles + 4;
          end ;
    $95:  begin       { STA ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_STA;
            cycles := cycles + 4;
          end ;
    $96:  begin       { STX ZeroPageIndexedY          }
            EAZeroPageIndexedY;
            OP_STX;
            cycles := cycles + 4;
          end ;
    $97:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $98:  begin       { TYA implied                   }
            OP_TYA;
            cycles := cycles + 2;
          end ;
    $99:  begin       { STA absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_STA;
            cycles := cycles + 5;
          end ;
    $9A:  begin       { TXS implied                   }
            OP_TXS;
            cycles := cycles + 2;
          end ;
    $9B:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $9C:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $9D:  begin       { STA absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_STA;
            cycles := cycles + 5;
          end ;
    $9E:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $9F:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $A0:  begin       { LDY immediate                 }
            EAimmediate;
            OP_LDY;
            cycles := cycles + 2;
          end ;
    $A1:  begin       { LDA ZeropageIndexedIndirectX  }
            EAZeropageIndexedIndirectX;
            OP_LDA;
            cycles := cycles + 6;
          end ;
    $A2:  begin       { LDX immediate                 }
            EAimmediate;
            OP_LDX;
            cycles := cycles + 2;
          end ;
    $A3:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $A4:  begin       { LDY Zeropage                  }
            EAzeropage;
            OP_LDY;
            cycles := cycles + 3;
          end ;
    $A5:  begin       { LDA Zeropage                  }
            EAzeropage;
            OP_LDA;
            cycles := cycles + 3;
          end ;
    $A6:  begin       { LDX Zeropage                  }
            EAzeropage;
            OP_LDX;
            cycles := cycles + 3;
          end ;
    $A7:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $A8:  begin       { TAY implied                   }
            OP_TAY;
            cycles := cycles + 2;
          end ;
    $A9:  begin       { LDA immediate                 }
            EAimmediate;
            OP_LDA;
            cycles := cycles + 2;
          end ;
    $AA:  begin       { TAX implied                   }
            OP_TAX;
            cycles := cycles + 2;
          end ;
    $AB:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $AC:  begin       { LDY absolute                  }
            EAabsolute;
            OP_LDY;
            cycles := cycles + 4;
          end ;
    $AD:  begin       { LDA absolute                  }
            EAabsolute;
            OP_LDA;
            cycles := cycles + 4;
          end ;
    $AE:  begin       { LDX absolute                  }
            EAabsolute;
            OP_LDX;
            cycles := cycles + 4;
          end ;
    $AF:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $B0:  begin       { BCS ProgramCounterRelative    }
            EAPCrelative;
            OP_BCS;
            cycles := cycles + 2 + pageboundary;
          end ;
    $B1:  begin       { LDA ZeropageIndirectIndexedY  }
            EAZeropageIndirectIndexedY;
            OP_LDA;
            cycles := cycles + 5 + pageboundary;
          end ;
    $B2:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $B3:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $B4:  begin       { LDY ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_LDY;
            cycles := cycles + 4;
          end ;
    $B5:  begin       { LDA ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_LDA;
            cycles := cycles + 4;
          end ;
    $B6:  begin       { LDX ZeroPageIndexedY          }
            EAZeroPageIndexedY;
            OP_LDX;
            cycles := cycles + 4;
          end ;
    $B7:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $B8:  begin       { CLV implied                   }
            OP_CLV;
            cycles := cycles + 2;
          end ;
    $B9:  begin       { LDA absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_LDA;
            cycles := cycles + 4 + pageboundary;
          end ;
    $BA:  begin       { TSX implied                   }
            OP_TSX;
            cycles := cycles + 2;
          end ;
    $BB:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $BC:  begin       { LDY absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_LDY;
            cycles := cycles + 4 + pageboundary;
          end ;
    $BD:  begin       { LDA absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_LDA;
            cycles := cycles + 4 + pageboundary;
          end ;
    $BE:  begin       { LDX absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_LDX;
            cycles := cycles + 4 + pageboundary;
          end ;
    $BF:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $C0:  begin       { CPY immediate                 }
            EAimmediate;
            OP_CPY;
            cycles := cycles + 2;
          end ;
    $C1:  begin       { CMP ZeropageIndexedIndirectX  }
            EAZeropageIndexedIndirectX;
            OP_CMP;
            cycles := cycles + 6;
          end ;
    $C2:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $C3:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $C4:  begin       { CPY Zeropage                  }
            EAZeropage;
            OP_CPY;
            cycles := cycles + 3;
          end ;
    $C5:  begin       { CMP Zeropage                  }
            EAZeropage;
            OP_CMP;
            cycles := cycles + 3;
          end ;
    $C6:  begin       { DEC Zeropage                  }
            EAZeropage;
            OP_DEC;
            cycles := cycles + 5;
          end ;
    $C7:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $C8:  begin       { INY implied                   }
            OP_INY;
            cycles := cycles + 2;
          end ;
    $C9:  begin       { CMP immediate                 }
            EAimmediate;
            OP_CMP;
            cycles := cycles + 2;
          end ;
    $CA:  begin       { DEX implied                   }
            OP_DEX;
            cycles := cycles + 2;
          end ;
    $CB:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $CC:  begin       { CPY absolute                  }
            EAabsolute;
            OP_CPY;
            cycles := cycles + 4;
          end ;
    $CD:  begin       { CMP absolute                  }
            EAabsolute;
            OP_CMP;
            cycles := cycles + 4;
          end ;
    $CE:  begin       { DEC absolute                  }
            EAabsolute;
            OP_DEC;
            cycles := cycles + 6;
          end ;
    $CF:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $D0:  begin       { BNE ProgramCounterRelative    }
            EAPCrelative;
            OP_BNE;
            cycles := cycles + 2 + pageboundary;
          end ;
    $D1:  begin       { CMP ZeropageIndirectIndexedY  }
            EAZeropageIndirectIndexedY;
            Op_CMP;
            cycles := cycles + 5 + pageboundary;
          end ;
    $D2:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $D3:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $D4:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $D5:  begin       { CMP ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_CMP;
            cycles := cycles + 4;
          end ;
    $D6:  begin       { DEC ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_DEC;
            cycles := cycles + 6;
          end ;
    $D7:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $D8:  begin       { CLD implied                   }
            OP_CLD;
            cycles := cycles + 2;
          end ;
    $D9:  begin       { CMP absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_CMP;
            cycles := cycles + 4 + pageboundary;
          end ;
    $DA:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $DB:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $DC:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $DD:  begin       { CMP absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_CMP;
            cycles := cycles + 4 + pageboundary;
          end ;
    $DE:  begin       { DEC absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_DEC;
            cycles := cycles + 7;
          end ;
    $DF:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $E0:  begin       { CPX immediate                 }
            EAimmediate;
            OP_CPX;
            cycles := cycles + 2;
          end ;
    $E1:  begin       { SBC ZeropageIndexedIndirectX  }
            EAZeropageIndexedIndirectX;
            OP_SBC_6502;
            cycles := cycles + 6;
          end ;
    $E2:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $E3:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $E4:  begin       { CPX Zeropage                  }
            EAzeropage;
            OP_CPX;
            cycles := cycles + 3;
          end ;
    $E5:  begin       { SBC Zeropage                  }
            EAzeropage;
            OP_SBC_6502;
            cycles := cycles + 3;
          end ;
    $E6:  begin       { INC Zeropage                  }
            EAzeropage;
            OP_INC;
            cycles := cycles + 5;
          end ;
    $E7:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $E8:  begin       { INX implied                   }
            OP_INX;
            cycles := cycles + 2;
          end ;
    $E9:  begin       { SBC immediate                 }
            EAimmediate;
            OP_SBC_6502;
            cycles := cycles + 2;
          end ;
    $EA:  begin       { NOP implied                   }
            cycles := cycles + 2;
          end ;
    $EB:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $EC:  begin       { CPX absolute                  }
            EAabsolute;
            OP_CPX;
            cycles := cycles + 4;
          end ;
    $ED:  begin       { SBC absolute                  }
            EAabsolute;
            OP_SBC_6502;
            cycles := cycles + 4;
          end ;
    $EE:  begin       { INC absolute                  }
            EAabsolute;
            OP_INC;
            cycles := cycles + 6;
          end ;
    $EF:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $F0:  begin       { BEQ ProgramCounterRelative    }
            EAPCrelative;
            OP_BEQ;
            cycles := cycles + 2 + pageboundary;
          end ;
    $F1:  begin       { SBC ZeropageIndirectIndexedY  }
            EAZeropageIndirectIndexedY;
            OP_SBC_6502;
            cycles := cycles + 5 + pageboundary;
          end ;
    $F2:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $F3:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $F4:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $F5:  begin       { SBC ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_SBC_6502;
            cycles := cycles + 4;
          end ;
    $F6:  begin       { INC ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_INC;
            cycles := cycles + 6;
          end ;
    $F7:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $F8:  begin       { SED implied                   }
            OP_SED;
            cycles := cycles + 2;
          end ;
    $F9:  begin       { SBC absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_SBC_6502;
            cycles := cycles + 4 + pageboundary;
          end ;
    $FA:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $FB:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $FC:  begin       { ??? implied                   }
            OP_illegal;
          end ;
    $FD:  begin       { SBC absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_SBC_6502;
            cycles := cycles + 4 + pageboundary;
          end ;
    $FE:  begin       { INC absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_INC;
            cycles := cycles + 7;
          end ;
    $FF:  begin       { ??? implied                   }
            OP_illegal;
          end ;
  end ;
end ; { Onestep6502 }

procedure Onestep65C02;

begin
  cycles := 0 ;
  opcode := Readmem(PC);
  inc(PC);
  case opcode of
    $00:  begin       { BRK implied                   }
            OP_BRK;
            cycles := cycles + 7;
          end ;
    $01:  begin       { ORA ZeropageIndexedIndirectX  }
            EAzeropageIndexedIndirectX;
            OP_ORA;
            cycles := cycles + 6;
          end ;
    $02:  begin       {  NOP 2 bytes                  }
            EAimmediate;
            cycles := cycles + 2;
          end ;
    $03:  begin       {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $04:  begin       {  TSB Zeropage                 }
            EAZeropage;
            OP_TSB;
            cycles := cycles + 5;
          end ;
    $05:  begin       { ORA Zeropage                  }
            EAZeropage;
            OP_ORA;
            cycles := cycles + 3;
          end ;
    $06:  begin       { ASL Zeropage                  }
            EAzeropage;
            OP_ASL;
            cycles := cycles + 5;
          end ;
    $07:  begin       { RMB0 zeropage                 }
            EAzeropage;
            OP_RMB0;
            cycles := cycles + 5;
          end ;
    $08:  begin       { PHP Stack                     }
            OP_PHP;
            cycles := cycles + 3;
          end ;
    $09:  begin       { ORA immediate                 }
            EAimmediate;
            OP_ORA;
            cycles := cycles + 2;
          end ;
    $0A:  begin       { ASL Accumulator               }
            OP_ASLA;
            cycles := cycles + 2;
          end ;
    $0B:  begin       { NOP implied                   }
            cycles := cycles + 1;
           end ;
    $0C:  begin       { TSB absolute                  }
            EAabsolute;
            OP_TSB;
            cycles := cycles + 6;
           end ;
    $0D:  begin       { ORA absolute                  }
            EAabsolute;
            OP_ORA;
            cycles := cycles + 4;
          end ;
    $0E:  begin       { ASL absolute                  }
            EAabsolute;
            OP_ASL;
            cycles := cycles + 6;
          end ;
    $0F:  begin       { BBR0 implied                  }
            OP_BBR($01) ;
            cycles := cycles + 5 ;
          end ;
    $10:  begin       { BPL ProgramCounterRelative    }
            EAPCrelative;
            OP_BPL;
            cycles := cycles + 2 + pageboundary;
          end ;
    $11:  begin       { ORA ZeropageIndirectIndexedY  }
            EAzeropageIndirectIndexedY;
            OP_ORA;
            cycles := cycles + 5 + pageboundary;
          end ;
    $12:  begin       { ORA ZeropageIndirect          }
            EAzeropageIndirect;
            OP_ORA;
            cycles := cycles + 5 ;
          end ;
    $13:  begin       {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $14:  begin       { TRB Zeropage                  }
            EAZeropage;
            OP_TRB;
            cycles := cycles + 5;
          end ;
    $15:  begin       { ORA ZeroPageIndexedX          }
            EAzeroPageIndexedX;
            OP_ORA;
            cycles := cycles + 4;
          end ;
    $16:  begin       { ASL ZeroPageIndexedX          }
            EAzeroPageIndexedX;
            OP_ASL;
            cycles := cycles + 6;
          end ;
    $17:  begin       { RMB1 zeropage                 }
            EAzeropage;
            OP_RMB1;
            cycles := cycles + 5;
          end ;
    $18:  begin       { CLC implied                   }
            OP_CLC;
            cycles := cycles + 2;
          end ;
    $19:  begin       { ORA absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_ORA;
            cycles := cycles + 4;
          end ;
    $1A:  begin       { INC implied                   }
            OP_INC_A;
            cycles := cycles + 2;
          end ;
    $1B: begin  {  NOP 1 bytes                        }
            cycles := cycles + 1;
          end ;
    $1C:  begin       { ??? implied                   }
            EAAbsolute;
            OP_TRB;
            cycles := cycles + 6;
          end ;
    $1D:  begin       { ORA absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_ORA;
            cycles := cycles + 4 + pageboundary;
          end ;
    $1E:  begin       { ASL absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_ASL;
            cycles := cycles + 7 ;
          end ;
    $1F:  begin       { BBR1 implied                  }
            OP_BBR($02) ;
            cycles := cycles + 5 ;
          end ;
    $20:  begin       { JSR absolute                  }
            EAabsolute;
            OP_JSR;
            cycles := cycles + 6;
          end ;
    $21:  begin       { AND ZeropageIndexedIndirectX  }
            EAZeropageIndexedIndirectX;
            OP_AND;
            cycles := cycles + 6;
          end ;
    $22:  begin       {  NOP 2 bytes                  }
            EAimmediate;
            cycles := cycles + 2;
          end ;
    $23: begin        {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $24:  begin       { BIT Zeropage                  }
            EAzeropage;
            OP_BIT;
            cycles := cycles + 3;
          end ;
    $25:  begin       { AND Zeropage                  }
            EAzeropage;
            OP_AND;
            cycles := cycles + 3;
          end ;
    $26:  begin       { ROL Zeropage                  }
            EAzeropage;
            OP_ROL;
            cycles := cycles + 5;
          end ;
    $27:  begin       { RMB2 zeropage                 }
            EAzeropage;
            OP_RMB2;
            cycles := cycles + 5;
          end ;
    $28:  begin       { PLP Stack                     }
            OP_PLP;
            cycles := cycles + 4;
          end ;
    $29:  begin       { AND immediate                 }
            EAimmediate;
            OP_AND;
            cycles := cycles + 2;
          end ;
    $2A:  begin       { ROL Accumulator               }
            OP_ROL_ACC;
            cycles := cycles + 2;
          end ;
    $2B: begin        {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $2C:  begin       { BIT absolute                  }
            EAabsolute;
            OP_BIT;
            cycles := cycles + 4;
          end ;
    $2D:  begin       { AND absolute                  }
            EAabsolute;
            OP_AND;
            cycles := cycles + 4;
          end ;
    $2E:  begin       { ROL absolute                  }
            EAabsolute;
            OP_ROL;
            cycles := cycles + 6;
          end ;
    $2F:  begin       { BBR2 implied                  }
            OP_BBR($04) ;
            cycles := cycles + 5 ;
          end ;
    $30:  begin       { BMI ProgramCounterRelative    }
            EAPCrelative;
            OP_BMI;
            cycles := cycles + 2 + pageboundary;
          end ;
    $31:  begin       { AND ZeropageIndirectIndexedY  }
            EAZeropageIndirectIndexedY;
            OP_AND;
            cycles := cycles + 5 + pageboundary;
          end ;
    $32:  begin       { AND ZeropageIndirect          }
            EAzeropageIndirect;
            OP_AND;
            cycles := cycles + 5 ;
          end ;
    $33: begin        {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $34:  begin       { BIT ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_BIT ;
            cycles := cycles + 4;
          end ;
    $35:  begin       { AND ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_AND ;
            cycles := cycles + 3;
          end ;
    $36:  begin       { ROL ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_ROL;
            cycles := cycles + 6;
         end ;
    $37:  begin       { RMB3 zeropage                 }
            EAzeropage;
            OP_RMB3;
            cycles := cycles + 5;
          end ;
    $38:  begin       { SEC implied                   }
            OP_SEC;
            cycles := cycles + 2;
          end ;
    $39:  begin       { AND absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_AND;
            cycles := cycles + 4 + pageboundary;
          end ;
    $3A:  begin       { DEC implied                   }
            OP_DEC_A;
            cycles := cycles + 2;
          end ;
    $3B:  begin       {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $3C:  begin       {  absoluteIndexedX             }
            EAabsoluteIndexedX ;
            OP_BIT ;
            cycles := cycles + 4;
          end ;
    $3D:  begin       { AND absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_AND;
            cycles := cycles + 4 + pageboundary;
          end ;
    $3E:  begin       { ROL absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_ROL;
            cycles := cycles + 6 + pageboundary ;
          end ;
    $3F:  begin       { BBR3 implied                  }
            OP_BBR($08) ;
            cycles := cycles + 5 ;
          end ;
    $40:  begin       { RTI implied                   }
            OP_RTI;
            cycles := cycles + 6;
          end ;
    $41:  begin       { EOR ZeropageIndexedIndirectX  }
            EAZeropageIndexedIndirectX;
            OP_EOR;
            cycles := cycles + 6;
          end ;
    $42:  begin       {  NOP 2 bytes                  }
            EAimmediate;
            cycles := cycles + 2;
          end ;
    $43:  begin  {  NOP 1 bytes                       }
            cycles := cycles + 1;
          end ;
    $44:  begin       { NOP zeropage                  }
                cycles := cycles + 3;
          end ;
    $45:  begin       { EOR Zeropage                  }
            EAZeropage;
            OP_EOR;
            cycles := cycles + 3;
          end ;
    $46:  begin       { LSR Zeropage                  }
            EAZeropage;
            OP_LSR;
            cycles := cycles + 5;
          end ;
    $47:  begin { RMB4 zeropage                       }
            EAzeropage;
            OP_RMB4;
            cycles := cycles + 5;
          end ;
    $48:  begin       { PHA Stack                     }
            OP_PHA;
            cycles := cycles + 3;
          end ;
    $49:  begin       { EOR immediate                 }
            EAimmediate;
            OP_EOR;
            cycles := cycles + 2;
          end ;
    $4A:  begin       { LSR Accumulator               }
            OP_LSRA;
            cycles := cycles + 2;
          end ;
    $4B: begin        {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $4C:  begin       { JMP absolute                  }
            EAabsolute;
            PC := ea;  ;
            cycles := cycles + 3;
          end ;
    $4D:  begin       { EOR absolute                  }
            EAabsolute;
            OP_EOR;
            cycles := cycles + 4;
          end ;
    $4E:  begin       { LSR absolute                  }
            EAabsolute;
            OP_LSR;
            cycles := cycles + 6;
          end ;
    $4F:  begin       { BBR4 implied                  }
            OP_BBR($10) ;
            cycles := cycles + 5 ;
          end ;
    $50:  begin       { BVC ProgramCounterRelative    }
            EAPCrelative;
            OP_BVC;
            cycles := cycles + 2 + pageboundary;
          end ;
    $51:  begin       { EOR ZeropageIndirectIndexedY  }
            EAZeropageIndirectIndexedY;
            OP_EOR;
            cycles := cycles + 5 + pageboundary;
          end ;
    $52:  begin       { EOR ZeropageIndirect          }
            EAzeropageIndirect;
            OP_EOR;
            cycles := cycles + 5 ;
          end ;
    $53: begin        {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $54:  begin       { NOP ZeroPageIndexed           }
            EAZeroPageIndexedX;
            cycles := cycles + 4;
          end ;
    $55:  begin       { EOR ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_EOR;
            cycles := cycles + 4;
          end ;
    $56:   begin      { LSR ZeroPageIndexedX          }
             EAZeroPageIndexedX;
             OP_LSR;
             cycles := cycles + 6;
           end ;
    $57:  begin       { RMB5 zeropage                 }
            EAzeropage;
            OP_RMB5;
            cycles := cycles + 5;
          end ;
    $58:  begin       { CLI implied                   }
            OP_CLI;
            cycles := cycles + 2;
          end ;
    $59:  begin       { EOR absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_EOR;
            cycles := cycles + 4 + pageboundary;
          end ;
    $5A:  begin       { PHY Stack                     }
            OP_PHY;
            cycles := cycles + 3;
          end ;
    $5B: begin        {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $5C:  begin       { ??? implied                   }
            cycles := cycles + 8;
          end ;
    $5D:  begin       { EOR absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_EOR;
            cycles := cycles + 4 + pageboundary;
          end ;
    $5E:  begin       { LSR absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_LSR;
            cycles := cycles + 6 + pageboundary;
          end ;
    $5F:  begin       { BBR5 implied                  }
            OP_BBR($20) ;
            cycles := cycles + 5 ;
          end ;
    $60:  begin       { RTS Stack                     }
            OP_RTS;
            cycles := cycles + 6;
          end ;
    $61:  begin       { ADC ZeropageIndexedIndirectX  }
            EAZeropageIndexedIndirectX;
            OP_ADC_65C02;
            cycles := cycles + 6;
          end ;
    $62:  begin       {  NOP 2 bytes                  }
            EAimmediate;
            cycles := cycles + 2;
          end ;
    $63: begin        {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $64:  begin       { STZ zeropage                  }
            EAZeropage;
            OP_STZ;
            cycles := cycles + 3;
          end ;
    $65:  begin       { ADC Zeropage                  }
            EAzeropage;
            OP_ADC_65C02;
            cycles := cycles + 3;
          end ;
    $66:  begin       { ROR Zeropage                  }
            EAzeropage;
            OP_ROR;
            cycles := cycles + 5;
          end ;
    $67:  begin       { RMB6 zeropage                 }
            EAzeropage;
            OP_RMB6;
            cycles := cycles + 5;
          end ;
    $68:  begin       { PLA Stack                     }
            OP_PLA;
            cycles := cycles + 4;
          end ;
    $69:  begin       { ADC immediate                 }
            EAimmediate;
            OP_ADC_65C02;
            cycles := cycles + 2;
          end ;
    $6A:  begin       { ROR Accumulator               }
            OP_RORA;
            cycles := cycles + 2;
          end ;
    $6B: begin        {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $6C:  begin       { JMP AbsoluteIndirect          }
            EAAbsoluteIndirect65C02;
            PC := ea;  ;
            cycles := cycles + 6;
          end ;
    $6D:  begin       { ADC Absolute                  }
            EAabsolute;
            OP_ADC_65C02;
            cycles := cycles + 4 + pageboundary ;
          end ;
    $6E:  begin       { ROR absolute                  }
            EAabsolute;
            OP_ROR;
            cycles := cycles + 6  + pageboundary;
          end ;
    $6F:  begin       { BBR6 implied                  }
            OP_BBR($40) ;
            cycles := cycles + 5 ;
          end ;
    $70:  begin       { BVS ProgramCounterRelative    }
            EAPCrelative;
            OP_BVS;
            cycles := cycles + 2 + pageboundary;
          end ;
    $71:  begin       { ADC ZeropageIndirectIndexedY  }
            EAZeropageIndirectIndexedY;
            OP_ADC_65C02;
            cycles := cycles + 5 + pageboundary;
          end ;
    $72:  begin       { ADC ZeropageIndirect          }
            EAzeropageIndirect;
            OP_ADC_65C02;
            cycles := cycles + 5 ;
          end ;
    $73: begin        {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $74:  begin       { STZ ZeroPageIndexed           }
            EAZeroPageIndexedX;
            OP_STZ;
            cycles := cycles + 4;
          end ;
    $75:  begin       { ADC ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_ADC_65C02;
            cycles := cycles + 4;
          end ;
    $76:  begin       { ROR ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_ROR;
            cycles := cycles + 6;
          end ;
    $77:  begin       { RMB7 zeropage                 }
            EAzeropage;
            OP_RMB7;
            cycles := cycles + 5;
          end ;
    $78:  begin       { SEI implied                   }
            OP_SEI;
            cycles := cycles + 2;
          end ;
    $79:  begin       { ADC absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_ADC_65C02;
            cycles := cycles + 4 + pageboundary;
          end ;
    $7A:  begin       { PLY Stack                     }
            OP_PLY;
            cycles := cycles + 4;
          end ;
    $7B: begin        {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $7C:  begin       { JMP absoluteindirectindexedX  }
            EAabsoluteIndexedIndirectX ;
            PC := ea;   ;
            cycles := cycles + 6;
           end ;
    $7D:  begin       { ADC absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_ADC_65C02;
            cycles := cycles + 4 + pageboundary;
          end ;
    $7E:  begin       { ROR absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_ROR;
            cycles := cycles + 6 + pageboundary ;
          end ;
    $7F:  begin       { BBR7 implied                  }
            OP_BBR($80) ;
            cycles := cycles + 5 ;
          end ;
    $80:  begin       { BRA ProgramCounterRelative    }
            EAPCrelative;
            OP_BRA;
            cycles := cycles + 3 + pageboundary;
          end ;
    $81:  begin       { STA ZeropageIndexedIndirectX  }
            EAZeropageIndexedIndirectX;
            OP_STA;
            cycles := cycles + 6;
          end ;
    $82:  begin       {  NOP 2 bytes                  }
            EAimmediate;
            cycles := cycles + 2;
          end ;
    $83: begin        {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $84:  begin       { STY Zeropage                  }
            EAzeropage;
            OP_STY;
            cycles := cycles + 3;
          end ;
    $85:  begin       { STA Zeropage                  }
            EAzeropage;
            OP_STA;
            cycles := cycles + 3;
          end ;
    $86:  begin       { STX Zeropage                  }
            EAzeropage;
            OP_STX;
            cycles := cycles + 3;
          end ;
    $87:  begin { SMB0 zeropage                 }
            EAzeropage;
            OP_SMB0;
            cycles := cycles + 5;
          end ;
    $88:  begin       { DEY implied                   }
            OP_DEY;
            cycles := cycles + 2;
          end ;
    $89:  begin       { BIT immediate                 }
            EAimmediate;
            OP_BIT ;
            cycles := cycles + 2;
          end ;
    $8A:  begin       { TXA implied                   }
            OP_TXA;
            cycles := cycles + 2;
          end ;
    $8B: begin  {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $8C:  begin       { STY absolute                  }
            EAabsolute;
            OP_STY;
            cycles := cycles + 4;
          end ;
    $8D:  begin       { STA absolute                  }
            EAabsolute;
            OP_STA;
            cycles := cycles + 4;
          end ;
    $8E:  begin       { STX absolute                  }
            EAabsolute;
            OP_STX;
            cycles := cycles + 4;
          end ;
    $8F:  begin       { BBS0 implied                  }
            OP_BBS($01) ;
            cycles := cycles + 5 ;
          end ;
    $90:  begin       { BCC ProgramCounterRelative    }
            EAPCrelative;
            OP_BCC;
            cycles := cycles + 2 + pageboundary;
          end ;
    $91:  begin       { STA ZeropageIndirectIndexedY  }
            EAZeropageIndirectIndexedY;
            OP_STA;
            cycles := cycles + 6;
          end ;
    $92:  begin       { STA ZeropageIndirect          }
            EAzeropageIndirect;
            OP_STA;
            cycles := cycles + 5 ;
          end ;
    $93:  begin       {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $94:  begin       { STY ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_STY;
            cycles := cycles + 4;
          end ;
    $95:  begin       { STA ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_STA;
            cycles := cycles + 4;
          end ;
    $96:  begin       { STX ZeroPageIndexedY          }
            EAZeroPageIndexedY;
            OP_STX;
            cycles := cycles + 4;
          end ;
    $97:  begin       { SMB1 zeropage                 }
            EAzeropage;
            OP_SMB1;
            cycles := cycles + 5;
          end ;
    $98:  begin       { TYA implied                   }
            OP_TYA;
            cycles := cycles + 2;
          end ;
    $99:  begin       { STA absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_STA;
            cycles := cycles + 5;
          end ;
    $9A:  begin       { TXS implied                   }
            OP_TXS;
            cycles := cycles + 2;
          end ;
    $9B: begin        {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $9C:  begin       { STZ absolute                  }
            EAabsolute;
            OP_STZ;
            cycles := cycles + 4;
          end ;
    $9D:  begin       { STA absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_STA;
            cycles := cycles + 5;
          end ;
    $9E:  begin       { STZ absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_STZ;
            cycles := cycles + 5;
          end ;
    $9F:  begin       { BBS1 implied                  }
            OP_BBS($02) ;
            cycles := cycles + 5 ;
          end ;
    $A0:  begin       { LDY immediate                 }
            EAimmediate;
            OP_LDY;
            cycles := cycles + 2;
          end ;
    $A1:  begin       { LDA ZeropageIndexedIndirectX  }
            EAZeropageIndexedIndirectX;
            OP_LDA;
            cycles := cycles + 6;
          end ;
    $A2:  begin       { LDX immediate                 }
            EAimmediate;
            OP_LDX;
            cycles := cycles + 2;
          end ;
    $A3:  begin       {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $A4:  begin       { LDY Zeropage                  }
            EAzeropage;
            OP_LDY;
            cycles := cycles + 3;
          end ;
    $A5:  begin       { LDA Zeropage                  }
            EAzeropage;
            OP_LDA;
            cycles := cycles + 3;
          end ;
    $A6:  begin       { LDX Zeropage                  }
            EAzeropage;
            OP_LDX;
            cycles := cycles + 3;
          end ;
    $A7:  begin       { SMB2 zeropage                 }
            EAzeropage;
            OP_SMB2;
            cycles := cycles + 5;
          end ;
    $A8:  begin       { TAY implied                   }
            OP_TAY;
            cycles := cycles + 2;
          end ;
    $A9:  begin       { LDA immediate                 }
            EAimmediate;
            OP_LDA;
            cycles := cycles + 2;
          end ;
    $AA:  begin       { TAX implied                   }
            OP_TAX;
            cycles := cycles + 2;
          end ;
    $AB:  begin       {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $AC:  begin       { LDY absolute                  }
            EAabsolute;
            OP_LDY;
            cycles := cycles + 4;
          end ;
    $AD:  begin       { LDA absolute                  }
            EAabsolute;
            OP_LDA;
            cycles := cycles + 4;
          end ;
    $AE:  begin       { LDX absolute                  }
            EAabsolute;
            OP_LDX;
            cycles := cycles + 4;
          end ;
    $AF:  begin       { BBS2 implied                  }
            OP_BBS($04) ;
            cycles := cycles + 5 ;
          end ;
    $B0:  begin       { BCS ProgramCounterRelative    }
            EAPCrelative;
            OP_BCS;
            cycles := cycles + 2 + pageboundary;
          end ;
    $B1:  begin       { LDA ZeropageIndirectIndexedY  }
            EAZeropageIndirectIndexedY;
            OP_LDA;
            cycles := cycles + 5 + pageboundary;
          end ;
    $B2:  begin       { LDA ZeropageIndirect          }
            EAzeropageIndirect;
            OP_LDA;
            cycles := cycles + 5 ;
          end ;
    $B3:  begin       {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $B4:  begin       { LDY ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_LDY;
            cycles := cycles + 4;
          end ;
    $B5:  begin       { LDA ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_LDA;
            cycles := cycles + 4;
          end ;
    $B6:  begin       { LDX ZeroPageIndexedY          }
            EAZeroPageIndexedY;
            OP_LDX;
            cycles := cycles + 4;
          end ;
    $B7:  begin       { SMB3 zeropage                 }
            EAzeropage;
            OP_SMB3;
            cycles := cycles + 5;
          end ;
    $B8:  begin       { CLV implied                   }
            OP_CLV;
            cycles := cycles + 2;
          end ;
    $B9:  begin       { LDA absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_LDA;
            cycles := cycles + 4 + pageboundary;
          end ;
    $BA:  begin       { TSX implied                   }
            OP_TSX;
            cycles := cycles + 2;
          end ;
    $BB:  begin       {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $BC:  begin       { LDY absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_LDY;
            cycles := cycles + 4 + pageboundary;
          end ;
    $BD:  begin       { LDA absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_LDA;
            cycles := cycles + 4 + pageboundary;
          end ;
    $BE:  begin       { LDX absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_LDX;
            cycles := cycles + 4 + pageboundary;
          end ;
    $BF:  begin       { BBS3 implied                  }
            OP_BBS($08) ;
            cycles := cycles + 5 ;
          end ;
    $C0:  begin       { CPY immediate                 }
            EAimmediate;
            OP_CPY;
            cycles := cycles + 2;
          end ;
    $C1:  begin       { CMP ZeropageIndexedIndirectX  }
            EAZeropageIndexedIndirectX;
            OP_CMP;
            cycles := cycles + 6;
          end ;
    $C2:  begin       {  NOP 2 bytes                  }
            EAimmediate;
            cycles := cycles + 2;
          end ;
    $C3:  begin       {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $C4:  begin       { CPY Zeropage                  }
            EAZeropage;
            OP_CPY;
            cycles := cycles + 3;
          end ;
    $C5:  begin       { CMP Zeropage                  }
           EAZeropage;
            OP_CMP;
            cycles := cycles + 3;
          end ;
    $C6:  begin       { DEC Zeropage                  }
            EAZeropage;
            OP_DEC;
            cycles := cycles + 5;
          end ;
    $C7:  begin       { SMB4 zeropage                 }
            EAzeropage;
            OP_SMB4;
            cycles := cycles + 5;
          end ;
    $C8:  begin       { INY implied                   }
            OP_INY;
            cycles := cycles + 2;
          end ;
    $C9:  begin       { CMP immediate                 }
            EAimmediate;
            OP_CMP;
            cycles := cycles + 2;
          end ;
    $CA:  begin       { DEX implied                   }
            OP_DEX;
            cycles := cycles + 2;
          end ;
    $CB:  begin              { WAIT                   }
            OP_WAIT;
            cycles := cycles + 3;
          end ;
    $CC:  begin       { CPY absolute                  }
            EAabsolute;
            OP_CPY;
            cycles := cycles + 4;
          end ;
    $CD:  begin       { CMP absolute                  }
            EAabsolute;
            OP_CMP;
            cycles := cycles + 4;
          end ;
    $CE:  begin       { DEC absolute                  }
            EAabsolute;
            OP_DEC;
            cycles := cycles + 6;
          end ;
    $CF:  begin       { BBS4 implied                  }
            OP_BBS($10) ;
            cycles := cycles + 5 ;
          end ;
    $D0:  begin       { BNE ProgramCounterRelative    }
            EAPCrelative;
            OP_BNE;
            cycles := cycles + 2 + pageboundary;
          end ;
    $D1:  begin       { CMP ZeropageIndirectIndexedY  }
            EAZeropageIndirectIndexedY;
            Op_CMP;
            cycles := cycles + 5 + pageboundary;
          end ;
    $D2:  begin       { CMP ZeropageIndirect          }
            EAzeropageIndirect;
            OP_CMP;
            cycles := cycles + 5 ;
          end ;
    $D3: begin        {  NOP 1 bytes                  }
           cycles := cycles + 1;
         end ;
    $D4:  begin             { NOP ZeroPageIndexed     }
            EAZeroPageIndexedX;
            cycles := cycles + 4;
          end ;
    $D5:  begin       { CMP ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_CMP;
            cycles := cycles + 4;
          end ;
    $D6:  begin       { DEC ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_DEC;
            cycles := cycles + 6;
          end ;
    $D7:  begin       { SMB5 zeropage                 }
            EAzeropage;
            OP_SMB5;
            cycles := cycles + 5;
          end ;
    $D8:  begin       { CLD implied                   }
            OP_CLD;
            cycles := cycles + 2;
          end ;
    $D9:  begin       { CMP absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_CMP;
            cycles := cycles + 4 + pageboundary;
          end ;
    $DA:  begin       { PHX Stack                     }
            OP_PHX;
            cycles := cycles + 3;
          end ;
    $DB:  begin       { STP                           }
            OP_STP;
            cycles := cycles + 3;
          end ;
    $DC:  begin       { NOP absolute                  }
            EAabsolute ;
            cycles := cycles + 4;
          end ;
    $DD:  begin       { CMP absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_CMP;
            cycles := cycles + 4 + pageboundary;
          end ;
    $DE:  begin       { DEC absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_DEC;
            cycles := cycles + 7;
          end ;
    $DF:  begin       { BBS5 implied                  }
            OP_BBS($20) ;
            cycles := cycles + 5 ;
          end ;
    $E0:  begin       { CPX immediate                 }
            EAimmediate;
            OP_CPX;
            cycles := cycles + 2;
          end ;
    $E1:  begin      { SBC ZeropageIndexedIndirectX   }
            EAZeropageIndexedIndirectX;
            OP_SBC_65C02;
            cycles := cycles + 6;
          end ;
    $E2:  begin       {  NOP 2 bytes                  }
            EAimmediate;
            cycles := cycles + 2;
          end ;
    $E3:  begin       {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $E4:  begin       { CPX Zeropage                  }
            EAzeropage;
            OP_CPX;
            cycles := cycles + 3;
          end ;
    $E5:  begin       { SBC Zeropage                  }
            EAzeropage;
            OP_SBC_65C02;
            cycles := cycles + 3;
          end ;
    $E6:  begin       { INC Zeropage                  }
            EAzeropage;
            OP_INC;
            cycles := cycles + 5;
          end ;
    $E7:  begin       { SMB6 zeropage                 }
            EAzeropage;
            OP_SMB6;
            cycles := cycles + 5;
          end ;
    $E8:  begin       { INX implied                   }
            OP_INX;
            cycles := cycles + 2;
    end ;
    $E9:  begin       { SBC immediate                 }
            EAimmediate;
            OP_SBC_65C02;
            cycles := cycles + 2;
          end ;
    $EA:  begin       { NOP implied                   }
            cycles := cycles + 2;
          end ;
    $EB:  begin       {  NOP 1 bytes                  }
            cycles := cycles + 1;
          end ;
    $EC:  begin       { CPX absolute                  }
            EAabsolute;
            OP_CPX;
            cycles := cycles + 4;
          end ;
    $ED:  begin       { SBC absolute                  }
            EAabsolute;
            OP_SBC_65C02;
            cycles := cycles + 4;
          end ;
    $EE:  begin       { INC absolute                  }
            EAabsolute;
            OP_INC;
            cycles := cycles + 6;
          end ;
    $EF:  begin       { BBS6 implied                  }
            OP_BBS($40) ;
            cycles := cycles + 5 ;
          end ;
    $F0:  begin       { BEQ ProgramCounterRelative    }
            EAPCrelative;
            OP_BEQ;
            cycles := cycles + 2 + pageboundary;
          end ;
    $F1:  begin       { SBC ZeropageIndirectIndexedY  }
            EAZeropageIndirectIndexedY;
            OP_SBC_65C02;
            cycles := cycles + 5 + pageboundary;
          end ;
    $F2:  begin       { STA ZeropageIndirect          }
            EAzeropageIndirect;
            OP_SBC_65C02;
            cycles := cycles + 5 ;
          end ;
    $F3: begin        {  NOP 1 bytes                  }
           cycles := cycles + 1;
         end ;
    $F4:  begin             { NOP ZeroPageIndexed     }
            EAZeroPageIndexedX;
            cycles := cycles + 4;
          end ;
    $F5:  begin       { SBC ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_SBC_65C02;
            cycles := cycles + 4;
          end ;
    $F6:  begin       { INC ZeroPageIndexedX          }
            EAZeroPageIndexedX;
            OP_INC;
            cycles := cycles + 6;
          end ;
    $F7:  begin       { SMB7 zeropage                 }
            EAzeropage;
            OP_SMB7;
            cycles := cycles + 5;
          end ;
    $F8:  begin       { SED implied                   }
            OP_SED;
            cycles := cycles + 2;
          end ;
    $F9:  begin       { SBC absoluteIndexedY          }
            EAabsoluteIndexedY;
            OP_SBC_65C02;
            cycles := cycles + 4 + pageboundary;
          end ;
    $FA:  begin       { PLX Stack                     }
            OP_PLX;
            cycles := cycles + 4;
          end ;
    $FB:  begin        {  NOP 1 bytes                 }
            cycles := cycles + 1;
          end ;
    $FC:  begin       { NOP absolute                  }
            EAabsolute ;
            cycles := cycles + 4;
          end ;
    $FD:  begin       { SBC absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_SBC_65C02;
            cycles := cycles + 4 + pageboundary;
          end ;
    $FE:  begin       { INC absoluteIndexedX          }
            EAabsoluteIndexedX;
            OP_INC;
            cycles := cycles + 7;
          end ;
    $FF:  begin       { BBS7 implied                  }
            OP_BBS($80) ;
            cycles := cycles + 5 ;
          end ;
  end ;
end ; { OnestepC6502 }

procedure OneStep65 ;

begin
  if Is65C02
    then
      OneStep65C02
    else
      OneStep6502 ;
end ;

end.

unit udisassemble6502;

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

{
  Disasembly of current PC

  asline  OPCC arg         OPCC = 65C02 opcode arg = 0, 1, 2 byte length =
  aline   PCPC OP A1 A2

}


interface

uses
  Classes, SysUtils ;

type

  Tsymbol = record
    slabel: string;
    address: integer;
  end ;

procedure disassemble6502(currentPC : integer ;
                          var NextPC : integer ;
                          var disassemblyline, assemblerline : string ;
                          var symbol : Tsymbol ) ;


implementation

uses
     utim, udebugwindow, u6502cpu  ;

type
  TAddressmode = (
                 absolute,                 { 2, a     }
       	         absoluteIndexedIndirectX, { 2 (a,X)  }
                 absoluteindexedX,         { 2  a,X   }
                 absoluteindexedY,         { 2  a,Y   }
       	         absoluteindirect,         { 2 (a)    }
                 accumulator,              { 0  A     }
                 immediate,                { 1  #     }
                 implied,                  { 0  i     }
                 ProgramCounterRelative,   { 1  R     }
       	         Stack,                    { 0  S     }
                 Zeropage,                 { 1  zp    }
                 ZeroPageIndexedIndirect,  { 1 (zp,X) }
                 ZeroPageIndexedX,         { 1  zp,X  }
                 ZeroPageIndexedY,         { 1  zp,Y  }
                 ZeroPageIndirect,         { 1 (zp)   }
                 ZeroPageIndirectIndexedY, { 1 (zp),Y }
                 ZeroPageRelative,         { 2 zp,R   }
                 nop1,                     { 0        }
       	         nop2,                     { 1        }
       	         nop3                      { 2        }
                 ) ;

  TOpcode = record
              Mnemonic : array[1..4] of char;
              Addrmode : Taddressmode ;
            end;

const
  Opsize : array[TAddressmode] of integer =
  (
   2, {a         absolute,                }
   2, {(a,X)     absoluteIndexedIndirectX,}
   2, { a,X      absoluteindexedX,        }
   2, { a,Y      absoluteindexedY,        }
   2, {(a)       absoluteindirect,        }
   0, { A        accumulator,             }
   1, { #        immediate,               }
   0, { i        implied,                 }
   1, { R        ProgramCounterRelative,  }
   0, { S        Stack,                   }
   1, { zp       Zeropage,                }
   1, {(zp,X)    ZeroPageIndexedIndirect, }
   1, { zp,X     ZeroPageIndexedX,        }
   1, { zp,Y     ZeroPageIndexedY,        }
   1, {(zp)      ZeroPageIndirect,        }
   1, {(zp),Y    Zero PageIndirectIndexedY}
   2, {zp,R      ZeroPageRelative,        }
   0, {          nop1,                    }
   1, {          nop2,                    }
   2  {          nop3                     }
   ) ;

  Opcode6502 : array [0..255] of Topcode = (
  ( Mnemonic : 'BRK ' ; Addrmode : implied                  )  , { 0x }
  ( Mnemonic : 'ORA ' ; Addrmode : ZeropageIndexedIndirect  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'ORA ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : 'ASL ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'PHP ' ; Addrmode : Stack                    )  ,
  ( Mnemonic : 'ORA ' ; Addrmode : immediate                )  ,
  ( Mnemonic : 'ASL ' ; Addrmode : Accumulator              )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'ORA ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : 'ASL ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'BPL ' ; Addrmode : ProgramCounterRelative   )  , { 1x }
  ( Mnemonic : 'ORA ' ; Addrmode : ZeropageIndirectIndexedY )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'ORA ' ; Addrmode : ZeroPageIndexedX         )  ,
  ( Mnemonic : 'ASL ' ; Addrmode : ZeroPageIndexedX         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'CLC ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'ORA ' ; Addrmode : absoluteIndexedY         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'ORA ' ; Addrmode : absoluteIndexedX         )  ,
  ( Mnemonic : 'ASL ' ; Addrmode : absoluteIndexedX         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'JSR ' ; Addrmode : absolute                 )  , { 2x }
  ( Mnemonic : 'AND ' ; Addrmode : ZeropageIndexedIndirect  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'BIT ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : 'AND ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : 'ROL ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'PLP ' ; Addrmode : Stack                    )  ,
  ( Mnemonic : 'AND ' ; Addrmode : immediate                )  ,
  ( Mnemonic : 'ROL ' ; Addrmode : Accumulator              )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'BIT ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : 'AND ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : 'ROL ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'BMI ' ; Addrmode : ProgramCounterRelative   )  , { 3x }
  ( Mnemonic : 'AND ' ; Addrmode : ZeropageIndirectIndexedY )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'AND ' ; Addrmode : ZeroPageIndexedX         )  ,
  ( Mnemonic : 'ROL ' ; Addrmode : ZeroPageIndexedX         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'SEC ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'AND ' ; Addrmode : absoluteIndexedY         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'AND ' ; Addrmode : absoluteIndexedX         )  ,
  ( Mnemonic : 'ROL ' ; Addrmode : absoluteIndexedX         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'RTI ' ; Addrmode : implied                  )  , { 4x }
  ( Mnemonic : 'EOR ' ; Addrmode : ZeropageIndexedIndirect  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'EOR ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : 'LSR ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'PHA ' ; Addrmode : Stack                    )  ,
  ( Mnemonic : 'EOR ' ; Addrmode : immediate                )  ,
  ( Mnemonic : 'LSR ' ; Addrmode : Accumulator              )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'JMP ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : 'EOR ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : 'LSR ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'BVC ' ; Addrmode : ProgramCounterRelative   )  , { 5x }
  ( Mnemonic : 'EOR ' ; Addrmode : ZeropageIndirectIndexedY )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'EOR ' ; Addrmode : ZeroPageIndexedX         )  ,
  ( Mnemonic : 'LSR ' ; Addrmode : ZeroPageIndexedX         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'CLI ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'EOR ' ; Addrmode : absoluteIndexedY         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'EOR ' ; Addrmode : absoluteIndexedX         )  ,
  ( Mnemonic : 'LSR ' ; Addrmode : absoluteIndexedX         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'RTS ' ; Addrmode : Stack                    )  , { 6x }
  ( Mnemonic : 'ADC ' ; Addrmode : ZeropageIndexedIndirect  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'ADC ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : 'ROR ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'PLA ' ; Addrmode : Stack                    )  ,
  ( Mnemonic : 'ADC ' ; Addrmode : immediate                )  ,
  ( Mnemonic : 'ROR ' ; Addrmode : Accumulator              )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'JMP ' ; Addrmode : AbsoluteIndirect         )  ,
  ( Mnemonic : 'ADC ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : 'ROR ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'BVS ' ; Addrmode : ProgramCounterRelative   )  , { 7x }
  ( Mnemonic : 'ADC ' ; Addrmode : ZeropageIndirectIndexedY )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'ADC ' ; Addrmode : ZeroPageIndexedX         )  ,
  ( Mnemonic : 'ROR ' ; Addrmode : ZeroPageIndexedX         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'SEI ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'ADC ' ; Addrmode : absoluteIndexedY         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'ADC ' ; Addrmode : absoluteIndexedX         )  ,
  ( Mnemonic : 'ROR ' ; Addrmode : absoluteIndexedX         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  , { 8x }
  ( Mnemonic : 'STA ' ; Addrmode : ZeropageIndexedIndirect  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'STY ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : 'STA ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : 'STX ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'DEY ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'TXA ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'STY ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : 'STA ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : 'STX ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'BCC ' ; Addrmode : ProgramCounterRelative   )  , { 9x }
  ( Mnemonic : 'STA ' ; Addrmode : ZeropageIndirectIndexedY )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'STY ' ; Addrmode : ZeroPageIndexedX         )  ,
  ( Mnemonic : 'STA ' ; Addrmode : ZeroPageIndexedX         )  ,
  ( Mnemonic : 'STX ' ; Addrmode : ZeroPageIndexedY         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'TYA ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'STA ' ; Addrmode : absoluteIndexedY         )  ,
  ( Mnemonic : 'TXS ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'STA ' ; Addrmode : absoluteIndexedX         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'LDY ' ; Addrmode : immediate                )  , { Ax }
  ( Mnemonic : 'LDA ' ; Addrmode : ZeropageIndexedIndirect  )  ,
  ( Mnemonic : 'LDX ' ; Addrmode : immediate                )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'LDY ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : 'LDA ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : 'LDX ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'TAY ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'LDA ' ; Addrmode : immediate                )  ,
  ( Mnemonic : 'TAX ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'LDY ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : 'LDA ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : 'LDX ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'BCS ' ; Addrmode : ProgramCounterRelative   )  , { Bx }
  ( Mnemonic : 'LDA ' ; Addrmode : ZeropageIndirectIndexedY )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'LDY ' ; Addrmode : ZeroPageIndexedX         )  ,
  ( Mnemonic : 'LDA ' ; Addrmode : ZeroPageIndexedX         )  ,
  ( Mnemonic : 'LDX ' ; Addrmode : ZeroPageIndexedY         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'CLV ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'LDA ' ; Addrmode : absoluteIndexedY         )  ,
  ( Mnemonic : 'TSX ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'LDY ' ; Addrmode : absoluteIndexedX         )  ,
  ( Mnemonic : 'LDA ' ; Addrmode : absoluteIndexedX         )  ,
  ( Mnemonic : 'LDX ' ; Addrmode : absoluteIndexedY         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'CPY ' ; Addrmode : immediate                )  , { Cx }
  ( Mnemonic : 'CMP ' ; Addrmode : ZeropageIndexedIndirect  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'CPY ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : 'CMP ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : 'DEC ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'INY ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'CMP ' ; Addrmode : immediate                )  ,
  ( Mnemonic : 'DEX ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'CPY ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : 'CMP ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : 'DEC ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'BNE ' ; Addrmode : ProgramCounterRelative   )  , { Dx }
  ( Mnemonic : 'CMP ' ; Addrmode : ZeropageIndirectIndexedY )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'CMP ' ; Addrmode : ZeroPageIndexedX         )  ,
  ( Mnemonic : 'DEC ' ; Addrmode : ZeroPageIndexedX         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'CLD ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'CMP ' ; Addrmode : absoluteIndexedY         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'CMP ' ; Addrmode : absoluteIndexedX         )  ,
  ( Mnemonic : 'DEC ' ; Addrmode : absoluteIndexedX         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'CPX ' ; Addrmode : immediate                )  , { Ex }
  ( Mnemonic : 'SBC ' ; Addrmode : ZeropageIndexedIndirect  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'CPX ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : 'SBC ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : 'INC ' ; Addrmode : Zeropage                 )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'INX ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'SBC ' ; Addrmode : immediate                )  ,
  ( Mnemonic : 'NOP ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'CPX ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : 'SBC ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : 'INC ' ; Addrmode : absolute                 )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'BEQ ' ; Addrmode : ProgramCounterRelative   )  , { Fx }
  ( Mnemonic : 'SBC ' ; Addrmode : ZeropageIndirectIndexedY )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'SBC ' ; Addrmode : ZeroPageIndexedX         )  ,
  ( Mnemonic : 'INC ' ; Addrmode : ZeroPageIndexedX         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'SED ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'SBC ' ; Addrmode : absoluteIndexedY         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )  ,
  ( Mnemonic : 'SBC ' ; Addrmode : absoluteIndexedX         )  ,
  ( Mnemonic : 'INC ' ; Addrmode : absoluteIndexedX         )  ,
  ( Mnemonic : '??? ' ; Addrmode : implied                  )
  ) ;

 Opcode65C02 : array [0..255] of Topcode = (
 ( Mnemonic : 'BRK ' ; Addrmode : implied                  ) , { 0x }
 ( Mnemonic : 'ORA ' ; Addrmode : ZeroPageIndexedIndirect  ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop2                     ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'TSB ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'ORA ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'ASL ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'RMB0' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'PHP ' ; Addrmode : Stack                    ) ,
 ( Mnemonic : 'ORA ' ; Addrmode : immediate                ) ,
 ( Mnemonic : 'ASL ' ; Addrmode : accumulator              ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'TSB ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'ORA ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'ASL ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'BBR0' ; Addrmode : ZeroPageRelative         ) ,
 ( Mnemonic : 'BPL ' ; Addrmode : ProgramCounterRelative   ) , { 1x }
 ( Mnemonic : 'ORA ' ; Addrmode : ZeroPageIndirectIndexedY ) ,
 ( Mnemonic : 'ORA ' ; Addrmode : ZeroPageIndirect         ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'TRB ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'ORA ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'ASL ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'RMB1' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'CLC ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'ORA ' ; Addrmode : absoluteindexedY         ) ,
 ( Mnemonic : 'INC ' ; Addrmode : accumulator              ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'TRB ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'ORA ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'ASL ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'BBR1' ; Addrmode : ZeroPageRelative         ) ,
 ( Mnemonic : 'JSR ' ; Addrmode : absolute                 ) , { 2x }
 ( Mnemonic : 'AND ' ; Addrmode : ZeroPageIndexedIndirect  ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop2                     ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'BIT ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'AND ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'ROL ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'RMB2' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'PLP ' ; Addrmode : Stack                    ) ,
 ( Mnemonic : 'AND ' ; Addrmode : immediate                ) ,
 ( Mnemonic : 'ROL ' ; Addrmode : accumulator              ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'BIT ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'AND ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'ROL ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'BBR2' ; Addrmode : ZeroPageRelative         ) ,
 ( Mnemonic : 'BMI ' ; Addrmode : ProgramCounterRelative   ) , { 3x }
 ( Mnemonic : 'AND ' ; Addrmode : ZeroPageIndirectIndexedY ) ,
 ( Mnemonic : 'AND ' ; Addrmode : ZeroPageIndirect         ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'BIT ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'AND ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'ROL ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'RMB3' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'SEC ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'AND ' ; Addrmode : absoluteindexedY         ) ,
 ( Mnemonic : 'DEC ' ; Addrmode : accumulator              ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'BIT ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'AND ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'ROL ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'BBR3' ; Addrmode : ZeroPageRelative         ) ,
 ( Mnemonic : 'RTI ' ; Addrmode : implied                  ) , { 4x }
 ( Mnemonic : 'EOR ' ; Addrmode : ZeroPageIndexedIndirect  ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop2                     ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop2                     ) ,
 ( Mnemonic : 'EOR ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'LSR ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'RMB4' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'PHA ' ; Addrmode : Stack                    ) ,
 ( Mnemonic : 'EOR ' ; Addrmode : immediate                ) ,
 ( Mnemonic : 'LSR ' ; Addrmode : accumulator              ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'JMP ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'EOR ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'LSR ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'BBR4' ; Addrmode : ZeroPageRelative         ) ,
 ( Mnemonic : 'BVC ' ; Addrmode : ProgramCounterRelative   ) , { 5x }
 ( Mnemonic : 'EOR ' ; Addrmode : ZeroPageIndirectIndexedY ) ,
 ( Mnemonic : 'EOR ' ; Addrmode : ZeroPageIndirect         ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop2                     ) ,
 ( Mnemonic : 'EOR ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'LSR ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'RMB5' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'CLI ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'EOR ' ; Addrmode : absoluteindexedY         ) ,
 ( Mnemonic : 'PHY ' ; Addrmode : Stack                    ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop3                     ) ,
 ( Mnemonic : 'EOR ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'LSR ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'BBR5' ; Addrmode : ZeroPageRelative         ) ,
 ( Mnemonic : 'RTS ' ; Addrmode : Stack                    ) , { 6x }
 ( Mnemonic : 'ADC ' ; Addrmode : ZeroPageIndexedIndirect  ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop2                     ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'STZ ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'ADC ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'ROR ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'RMB6' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'PLA ' ; Addrmode : Stack                    ) ,
 ( Mnemonic : 'ADC ' ; Addrmode : immediate                ) ,
 ( Mnemonic : 'ROR ' ; Addrmode : accumulator              ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'JMP ' ; Addrmode : absoluteindirect         ) ,
 ( Mnemonic : 'ADC ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'ROR ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'BBR6' ; Addrmode : ZeroPageRelative         ) ,
 ( Mnemonic : 'BVS ' ; Addrmode : ProgramCounterRelative   ) , { 7x }
 ( Mnemonic : 'ADC ' ; Addrmode : ZeroPageIndirectIndexedY ) ,
 ( Mnemonic : 'ADC ' ; Addrmode : ZeroPageIndirect         ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'STZ ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'ADC ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'ROR ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'RMB7' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'SEI ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'ADC ' ; Addrmode : absoluteindexedY         ) ,
 ( Mnemonic : 'PLY ' ; Addrmode : Stack                    ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'JMP ' ; Addrmode : absoluteIndexedIndirectX ) ,
 ( Mnemonic : 'ADC ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'ROR ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'BBR7' ; Addrmode : ZeroPageRelative         ) ,
 ( Mnemonic : 'BRA ' ; Addrmode : ProgramCounterRelative   ) , { 8x }
 ( Mnemonic : 'STA ' ; Addrmode : ZeroPageIndexedIndirect  ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop2                     ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'STY ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'STA ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'STX ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'SMB0' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'DEY ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'BIT ' ; Addrmode : immediate                ) ,
 ( Mnemonic : 'TXA ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'STY ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'STA ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'STX ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'BBS0' ; Addrmode : ZeroPageRelative         ) ,
 ( Mnemonic : 'BCC ' ; Addrmode : ProgramCounterRelative   ) , { 9x }
 ( Mnemonic : 'STA ' ; Addrmode : ZeroPageIndirectIndexedY ) ,
 ( Mnemonic : 'STA ' ; Addrmode : ZeroPageIndirect         ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'STY ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'STA ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'STX ' ; Addrmode : ZeroPageIndexedY         ) ,
 ( Mnemonic : 'SMB1' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'TYA ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'STA ' ; Addrmode : absoluteindexedY         ) ,
 ( Mnemonic : 'TXS ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'STZ ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'STA ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'STZ ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'BBS1' ; Addrmode : ZeroPageRelative         ) ,
 ( Mnemonic : 'LDY ' ; Addrmode : immediate                ) , { Ax }
 ( Mnemonic : 'LDA ' ; Addrmode : ZeroPageIndexedIndirect  ) ,
 ( Mnemonic : 'LDX ' ; Addrmode : immediate                ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'LDY ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'LDA ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'LDX ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'SMB2' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'TAY ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'LDA ' ; Addrmode : immediate                ) ,
 ( Mnemonic : 'TAX ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'LDY ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'LDA ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'LDX ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'BBS2' ; Addrmode : ZeroPageRelative         ) ,
 ( Mnemonic : 'BCS ' ; Addrmode : ProgramCounterRelative   ) , { Bx }
 ( Mnemonic : 'LDA ' ; Addrmode : ZeroPageIndirectIndexedY ) ,
 ( Mnemonic : 'LDA ' ; Addrmode : ZeroPageIndirect         ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'LDY ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'LDA ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'LDX ' ; Addrmode : ZeroPageIndexedY         ) ,
 ( Mnemonic : 'SMB3' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'CLV ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'LDA ' ; Addrmode : absoluteindexedY         ) ,
 ( Mnemonic : 'TSX ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'LDY ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'LDA ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'LDX ' ; Addrmode : absoluteindexedY         ) ,
 ( Mnemonic : 'BBS3' ; Addrmode : ZeroPageRelative         ) ,
 ( Mnemonic : 'CPY ' ; Addrmode : immediate                ) , { Cx }
 ( Mnemonic : 'CMP ' ; Addrmode : ZeroPageIndexedIndirect  ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop2                     ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'CPY ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'CMP ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'DEC ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'SMB4' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'INY ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'CMP ' ; Addrmode : immediate                ) ,
 ( Mnemonic : 'DEX ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'WAI ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'CPY ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'CMP ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'DEC ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'BBS4' ; Addrmode : ZeroPageRelative         ) ,
 ( Mnemonic : 'BNE ' ; Addrmode : ProgramCounterRelative   ) , {Dx }
 ( Mnemonic : 'CMP ' ; Addrmode : ZeroPageIndirectIndexedY ) ,
 ( Mnemonic : 'CMP ' ; Addrmode : ZeroPageIndirect         ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop2                     ) ,
 ( Mnemonic : 'CMP ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'DEC ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'SMB5' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'CLD ' ; Addrmode : Implied                  ) ,
 ( Mnemonic : 'CMP ' ; Addrmode : absoluteindexedY         ) ,
 ( Mnemonic : 'PHX ' ; Addrmode : Stack                    ) ,
 ( Mnemonic : 'STP ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop3                     ) ,
 ( Mnemonic : 'CMP ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'DEC ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'BBS5' ; Addrmode : ZeroPageRelative         ) ,
 ( Mnemonic : 'CPX ' ; Addrmode : immediate                ) , { Ex }
 ( Mnemonic : 'SBC ' ; Addrmode : ZeroPageIndexedIndirect  ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop2                     ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'CPX ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'SBC ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'INC ' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'SMB6' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'INX ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'SBC ' ; Addrmode : immediate                ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'CPX ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'SBC ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'INC ' ; Addrmode : absolute                 ) ,
 ( Mnemonic : 'BBS6' ; Addrmode : ZeroPageRelative         ) ,
 ( Mnemonic : 'BEQ ' ; Addrmode : ProgramCounterRelative   ) , { Fx }
 ( Mnemonic : 'SBC ' ; Addrmode : ZeroPageIndirectIndexedY ) ,
 ( Mnemonic : 'SBC ' ; Addrmode : ZeroPageIndirect         ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop2                     ) ,
 ( Mnemonic : 'SBC ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'INC ' ; Addrmode : ZeroPageIndexedX         ) ,
 ( Mnemonic : 'SMB7' ; Addrmode : Zeropage                 ) ,
 ( Mnemonic : 'SED ' ; Addrmode : implied                  ) ,
 ( Mnemonic : 'SBC ' ; Addrmode : absoluteindexedY         ) ,
 ( Mnemonic : 'PLX ' ; Addrmode : Stack                    ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop1                     ) ,
 ( Mnemonic : 'NOP ' ; Addrmode : nop3                     ) ,
 ( Mnemonic : 'SBC ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'INC ' ; Addrmode : absoluteindexedX         ) ,
 ( Mnemonic : 'BBS7' ; Addrmode : ZeroPageRelative         )
 ) ;

 procedure disassemble6502(currentPC : integer ;
                           var NextPC : integer ;
                           var disassemblyline, assemblerline : string ;
                           var symbol : Tsymbol ) ;
 var
   aline,
   asline      : string ;
   mnen        : string ;
   addressmode : Taddressmode ;
   nr_of_ops,
   opcode,
   relativePC  : integer ;

 begin
   { add PC to line }
   opcode := memory[currentPC] ;
   aline := inttohex(currentPC,4) + ' ' +
            inttohex(opcode,2) + ' '  ;
   if Is65C02
     then
       begin
         addressmode := Opcode65c02[opcode].addrmode ;
         mnen        := Opcode65c02[opcode].mnemonic  ;
       end
     else
       begin
         addressmode := Opcode6502[opcode].addrmode  ;
         mnen        := Opcode6502[opcode].mnemonic  ;
       end ;
   nr_of_ops := opsize[addressmode] ;

   case nr_of_ops of
     0: begin
          aline := aline + '     ';
        end ;
     1: begin
          aline := aline + inttohex(memory[currentPC + 1],2)  + '   ' ;
        end ;
     2: begin
          aline := aline + inttohex(memory[currentPC + 1],2)  +  ' '
                       + inttohex(memory[currentPC + 2],2) ;
        end ;
     end;

    { get label  }
    symbol.slabel := '' ;
    symbol.address := -1 ;
    case addressmode of
      absolute,
      absoluteIndexedIndirectX,
      absoluteindexedX,
      absoluteindexedY,
      absoluteindirect
            : begin
                symbol.slabel   := 'L' +
                                 inttohex(memory[currentPC + 2],2) +
                                 inttohex(memory[currentPC + 1],2) ;
                symbol.address := memory[currentPC + 2] * 256 +
                                  memory[currentPC + 1] ;
              end;
      ProgramCounterRelative
            : begin
                { calculate signed offset of branch }
                relativePC := memory[currentPC + 1] ;
                if relativePC > $7F
                  then
                    { backward branch }
                     symbol.address := currentPC + 2 - (256 - relativePC)
                  else
                    { forward branch }
                    symbol.address := currentPC + 2 + relativePC ;
                 symbol.slabel := 'L' + inttohex(symbol.address,4) ;
            end ;
      Zeropage,
      ZeroPageIndexedIndirect,
      ZeroPageIndexedX,
      ZeroPageIndexedY,
      ZeroPageIndirect,
      ZeroPageIndirectIndexedY,
      ZeroPageRelative
            : begin
                symbol.slabel := 'L' + '00' +
                                 inttohex(memory[currentPC + 1],2) ;
                symbol.address := memory[currentPC + 1] ;
              end;
   end ;

   {if local disassmbly labels wanted
     insert symbol in symbol table if not already present
     else replace symbol with symbol from table
     only  when in range startcode - end code }

   if symbol.address <> -1
     then
       begin
         if dissymbol
           then
             begin
               if SymbolTable[symbol.address] = ''
                 then
                   begin
                     if (symbol.address >= startcode) and
                        (symbol.address <= endcode)
                       then
                         SymbolTable[symbol.address] := symbol.slabel
                    end
                 else
                    symbol.slabel := SymbolTable[symbol.address] ;
             end
           else
             symbol.slabel := SymbolTable[symbol.address] ;
       end ;

   if mnen[4] = ' '
     then
       asline := mnen
     else
       asline := mnen + ' ' ;
   case addressmode of
     absolute                 : asline := asline +
                                          '$' +               { 2, a     }
                                          inttohex(memory[currentPC + 2],2) +
                                          inttohex(memory[currentPC + 1],2) ;
     absoluteIndexedIndirectX : asline := asline +
                                          '($' +              { 2 (a,X)  }
                                          inttohex(memory[currentPC + 2],2) +
                                          inttohex(memory[currentPC + 1],2) +
                                          ',X)';
     absoluteindexedX         : asline := asline +
                                          '$' +               { 2  a,X   }
                                          inttohex(memory[currentPC + 2],2) +
                                          inttohex(memory[currentPC + 1],2) +
                                          ',X' ;
     absoluteindexedY         : asline := asline +
                                          '$' +               { 2  a,X   }
                                          inttohex(memory[currentPC + 2],2) +
                                          inttohex(memory[currentPC + 1],2) +
                                          ',Y' ;
     absoluteindirect         : asline := asline +
                                          '($' +              { 2 (a)    }
                                          inttohex(memory[currentPC + 2],2) +
                                          inttohex(memory[currentPC + 1],2) +
                                           ')' ;
     accumulator              : asline := asline +
                                          'A' ;               { 0  A     }
     immediate                : asline := asline +
                                          '#$' +               { 1  #     }
                                          inttohex(memory[currentPC + 1],2) ;
     implied                  : asline := asline ;            { 0  i     }

     ProgramCounterRelative   : asline := asline +            { 1  R     }
                                          '$' +
                                          inttohex(memory[currentPC + 1],2) ;
     Stack                    : asline := asline ;            { 0  S     }

     Zeropage                 : asline := asline +            { 1  zp    }
                                          '$' +
                                          inttohex(memory[currentPC + 1],2) ;
     ZeroPageIndexedIndirect  : asline := asline +            { 1 (zp,X) }
                                          '($' +
                                          inttohex(memory[currentPC + 1],2) +
                                          ',X)' ;
     ZeroPageIndexedX         : asline := asline +            { 1  zp,X  }
                                          '$' +
                                          inttohex(memory[currentPC + 1],2) +
                                          ',X' ;
     ZeroPageIndexedY         : asline := asline +             { 1  zp,Y  }
                                          inttohex(memory[currentPC + 1],2) +
                                          ',Y' ;
     ZeroPageIndirect         : asline := asline +            { 1 (zp)   }
                                          '($' +
                                          inttohex(memory[currentPC + 1],2) +
                                          ')' ;
     ZeroPageIndirectIndexedY : asline := asline +            { 1 (zp),Y }
                                          '($' +
                                          inttohex(memory[currentPC + 1],2) +
                                          '),Y' ;
     ZeroPageRelative         : asline := asline +            { 2 zp,R   }
                                          '$' +
                                          inttohex(memory[currentPC + 1],2) +
                                          ', $' +
                                          inttohex(memory[currentPC + 2],2) ;

     nop1                     : asline := asline  ;           { 0        }

     nop2                     : asline := asline +            { 1 xx     }
                                          inttohex(memory[currentPC + 1],2) ;
     nop3                     : asline := asline +            { 2 xx yy  }
                                          '($' +
                                          inttohex(memory[currentPC + 1],2) +
                                          ' $' +
                                          inttohex(memory[currentPC + 2],2) ;
    end;


   case nr_of_ops of
     0: begin
          NextPC := currentPC + 1 ;
        end ;
     1: begin
          NextPC := currentPC + 2 ;
        end ;
     2: begin
          NextPC := currentPC + 3 ;
        end ;
     end;

   assemblerline   := asline ;
   disassemblyline := aline ;
 end ;
end.


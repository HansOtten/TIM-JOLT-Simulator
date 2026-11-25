; 
; TIM simulator ROM
; 6502 part of the TIM-1 ROm simulation 
;
; Hans Otten, 2021, 2023
;
; Version 0.2 november 2023
; - emulate an ACIA 6850 at 1600
; - some handy routines
;
; MIT License
;
;  Copyright (c) 2023 Hans Otten 
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
; 
; TIM-1 ROM and 6530 addresses
;
;
; TIM ROM addressses
;
MSGPRTR  =       226                   ; One benaeth first TIM zeropage 
; characters        
CR  = $0D
LF  = $0A
; Init CPU and console
;
        .org $F800
START	JMP TIMROM		
INITS   JMP INITACIA        
OUTSER  JMP OUTACIA
INTIM   JMP INECHO   					; TIM also does hardware echo in software 
INSER   JMP INACIA

TIMROM  LDX #$FF  
        TXS   
        CLD   
        JSR INITS               ; clear console
;
; Welcome message
; 

        LDA #(STRTMSG & $FF)    ; high part 
        STA MSGPRTR  
        LDA #(STRTMSG >> 8)     ; low part of address of message
        STA MSGPRTR + 1
        JSR PRMSG
        BRK						; back to TIM

;
; PRMSG 
;   print string to ACIA 
;   A,Y contain address of message string
;   null terminated string, max 256 chars
;


PRMSG   
        LDY #$00  
NPRMSG  LDA (MSGPRTR),Y  
        BEQ EPRMSG  
        JSR OUTSER  
        INY
        BEQ EPRMSG
        JMP NPRMSG  
EPRMSG  RTS   
; 
; PRINT CRLF to ACIA
;  
CRLF    
        LDA #CR 
        JSR OUTSER  
        LDA #LF  
        JSR OUTSER
        RTS 
;
; Print space
;
SPACE
        LDA #' '
        JSR OUTSER
        RTS
;
; Print byte as hex number 
;
PRHEX   
        PHA                 ; save low nibble       
        LSR A               ; move high nibble to low 
        LSR A
        LSR A
        LSR A   
        JSR PRNYB           ; print high nibble 
        PLA                 ; get lower nibble back                     
PRNYB   AND #$0F
        CMP #10
        BCC PRDIG           ; If 0-9, print
        ADC #6              ;  convert to 'A..F'
PRDIG   ADC #'0'
        JSR OUTSER         ;  print 
        RTS
STRTMSG .text "TIM Simulator ROM HJCO 2023 V0.2"
		.byte CR, LF
		.text "."
        .byte 0
       
;
; ACIA routines for TIM Simulator
;
ACIAbase = $FE00		;
;
ACIAC = ACIAbase  
; write 
; bit 0 CR0 counter divide Reset if CR0 and CR 1 1
; bit 1 CR1 counter divide
; bit 2 CR2 word select 1
; bit 3 CR3 word select 2
; bit 4 CR4 word select 3
; bit 5 CR5 transmit control 1
; bit 6 CR6 transmit control 2
; bit 7 CR7 receive interrupt enable
;

ACIAS = ACIAbase  
; read  
; bit 0 RDR Receive data register full if databyte received 
; bit 1 TDR Transmit Data register empty
; bit 2 DCD
; bit 3 CTS
; bit 4 FE
; bit 5 OVRN
; bit 6 PE
; bit 7 IRQ
;
ACIAT = ACIAbase + 1        ; write databyte to sent, makes TDRE bit low until data sent out
ACIAR = ACIAbase + 1        ; databyte received Reading makes RDR low
;
INITACIA LDA #3
        STA ACIAC           ; reset ACIA
        LDA #$11
        STA  ACIAC          ; CR0 =1 divide 16 CR4 = 1 8 bits 2 stop bits 
        RTS
;
OUTACIA AND #$7F	; 7 bit 
		PHA                 ; save char to sent
WAITE   LDA ACIAS 
        AND #$02            ; check bit 1 TDR 
        BEQ WAITE 
        PLA
        STA ACIAT           ; sent out character
        RTS
;
INACIA  LDA ACIAS
        AND #$01            ; check check bit RDR
        BEQ INACIA
        LDA ACIAR
        RTS 
;
; Get input and echo to output as TIM ROM has bit-banged software echo
;		
INECHO	JSR	INACIA
		JSR	OUTACIA
		RTS
;
;
endacia 

        .END

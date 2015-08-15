;==============================================================================
;  ______  ______        _   _            _
; / ___\ \/ / __ )      | | | | __ _  ___| | _____ _ __
; \___ \\  /|  _ \ _____| |_| |/ _` |/ __| |/ / _ \ '__|
;  ___) /  \| |_) |_____|  _  | (_| | (__|   <  __/ |
; |____/_/\_\____/      |_| |_|\__,_|\___|_|\_\___|_|
;
; A program for Hacking your W65C816SXB
;------------------------------------------------------------------------------
; Copyright (C)2015 Andrew Jacobs
; All rights reserved.
;
; This work is made available under the terms of the Creative Commons
; Attribution-NonCommercial-ShareAlike 4.0 International license. Open the
; following URL to see the details.
;
; http://creativecommons.org/licenses/by-nc-sa/4.0/
;
;==============================================================================
; Notes:
;
; This program provides a simple monitor that you can use to inspect the memory
; in your W65C816SXB and reprogram parts of the flash ROM.
;
;------------------------------------------------------------------------------

                pw      132
                inclist on

                chip    65816
                longi   off
                longa   off

                include "w65c816.inc"
                include "w65c816sxb.inc"

;==============================================================================
; ASCII Character Codes
;------------------------------------------------------------------------------

SOH             equ     $01
EOT             equ     $04
ACK             equ     $06
BEL             equ     $07
BS              equ     $08
LF              equ     $0a
CR              equ     $0d
NAK             equ     $15
CAN             equ     $18
ESC             equ     $1b
DEL             equ     $7f

;==============================================================================
; Data Areas
;------------------------------------------------------------------------------

                page0

BUFLEN          ds      1
BANK            ds      1

ADDR_S          ds      3
ADDR_E          ds      3

BLOCK           ds      1
SUM             ds      1

TEMP            ds      4

                data
                org     $200

BUFFER          ds      128

;==============================================================================
; Initialisation
;------------------------------------------------------------------------------

                code
                public  Start
                extern  UartRx
                extern  UartTx
                extern  UartRxTest
Start:
                short_a                         ; Configure register sizes
                long_i
                jsr     UartCRLF
                ldx     #TITLE                  ; Display application title
                jsr     UartStr

                stz     BANK                    ; Reset default bank

;==============================================================================
; Command Processor
;------------------------------------------------------------------------------

NewCommand:
                stz     BUFLEN                  ; Clear the buffer
                jsr     UartCRLF                ; Move to a new line

                lda     #'.'                    ; Output the prompt
                jsr     UartTx

                short_i
                ldx     #0
DisplayCmd:     cpx     BUFLEN                  ; Any saved characters
                beq     ReadCommand
                lda     BUFFER,x                ; Yes, display them
                jsr     UartTx
                inx
                bra     DisplayCmd

RingBell:
                lda     #BEL                    ; Make a beep
                jsr     UartTx

ReadCommand:
                jsr     UartRx                  ; Wait for character

                cmp     #ESC                    ; Cancel input?
                beq     NewCommand              ; Yes, clear and restart
                cmp     #CR                     ; End of command?
                beq     ProcessCommand          ; Yes, start processing

                cmp     #BS                     ; Back space?
                beq     BackSpace
                cmp     #DEL                    ; Delete?
                beq     BackSpace

                cmp     #' '                    ; Printable character
                bcc     RingBell                ; No.
                cmp     #DEL
                bcs     RingBell                ; No.
                sta     BUFFER,x                ; Save rhe character
                inx
                jsr     UartTx                  ; Echo it and repeat
                bra     ReadCommand

BackSpace:
                cpx     #0                      ; Buffer empty?
                beq     RingBell                ; Yes, beep and continue
                dex                             ; No, remove last character
                lda     #BS
                jsr     UartTx
                lda     #' '
                jsr     UartTx
                lda     #BS
                jsr     UartTx
                bra     ReadCommand             ; And retry

ProcessCommand:
                stx     BUFLEN                  ; Save final length
                ldy     #0                      ; Load index for start

                jsr     SkipSpaces              ; Fetch command character
                bcs     NewCommand              ; None, empty command

;==============================================================================
; B - Select Memory Bank
;------------------------------------------------------------------------------

                cmp     #'B'                    ; Select memory bank?
                bne     NotMemoryBank

                ldx     #BANK                   ; Parse bank
                jsr     GetByte
                bcc     $+5
                jmp     ShowError
                jmp     NewCommand
NotMemoryBank:

;==============================================================================
; M - Display Memory
;------------------------------------------------------------------------------

                cmp     #'M'                    ; Memory display?
                bne     NotMemoryDisplay

                ldx     #ADDR_S                 ; Parse start address
                jsr     GetAddr
                bcc     $+5
                jmp     ShowError
                ldx     #ADDR_E                 ; Parse end address
                jsr     GetAddr
                bcc     $+5
                jmp     ShowError

DisplayMemory:
                jsr     UartCRLF
                lda     ADDR_S+2                ; Show memory address
                jsr     UartHex2
                lda     #':'
                jsr     UartTx
                lda     ADDR_S+1
                jsr     UartHex2
                lda     ADDR_S+0
                jsr     UartHex2

                ldy     #0                      ; Show sixteen bytes of data
ByteLoop:       lda     #' '
                jsr     UartTx
                lda     [ADDR_S],y
                jsr     UartHex2
                iny
                cpy     #16
                bne     ByteLoop

                lda     #' '
                jsr     UartTx
                lda     #'|'
                jsr     UartTx
                ldy     #0                      ; Show sixteen characters
CharLoop:       lda     [ADDR_S],Y
                jsr     IsPrintable
                bcs     $+4
                lda     #'.'
                jsr     UartTx
                iny
                cpy     #16
                bne     CharLoop
                lda     #'|'
                jsr     UartTx

                clc                             ; Bump the display address
                tya
                adc     ADDR_S+0
                sta     ADDR_S+0
                bcc     $+4
                inc     ADDR_S+1

                sec                             ; Exceeded the end address?
                sbc     ADDR_E+0
                lda     ADDR_S+1
                sbc     ADDR_E+1
                bmi     DisplayMemory           ; No, show more

                jmp     NewCommand
NotMemoryDisplay:

;==============================================================================
; R - Select ROM Bank
;------------------------------------------------------------------------------

                cmp     #'R'                    ; ROM Bank?
                bne     NotROMBank

                jsr     SkipSpaces
                bcc     $+5
BankFail:       jmp     ShowError
                cmp     #'0'
                bcc     BankFail
                cmp     #'3'+3
                bcs     BankFail

                sta     TEMP
                lda     #0
                ror     TEMP                    ; Bit 0 set
                bcs     $+4
                ora     #%00001100              ; No, make CA2 (A15) low
                ror     TEMP                    ; Bit 1 set
                bcs     $+4
                ora     #%11000000              ; No, make CB2 (FAMS) low
                sta     VIA2_PCR

                jmp     NewCommand
NotROMBank:

;==============================================================================
; X - XMODEM Upload
;------------------------------------------------------------------------------

                cmp     #'X'                    ; XModem upload?
                beq     $+5
                jmp     NotXModem

                ldx     #ADDR_S                 ; Parse start address
                jsr     GetAddr
                bcc     $+5
                jmp     ShowError

                bit     ADDR_S+1                ; Load into ROM area?
                bpl     NotROMArea
                lda     VIA2_PCR                ; Yes, check ROM selected
                and     #%11001100
                bne     NotROMArea
                long_i                          ; Upload to ROM3 ROM Area
                ldx     #NOT_SAFE
                jsr     UartStr
                jmp     NewCommand

NotROMArea:
                long_i                          ; Display waiting message
                ldx     #WAITING
                jsr     UartStr
                jsr     UartCRLF
                short_i
                stz     BLOCK                   ; Reset the block number
                inc     BLOCK

TransferWait:
                stz     TEMP+0                  ; Clear timeout counter
                stz     TEMP+1
		lda	#-20
                sta     TEMP+2
TransferPoll:
                jsr     UartRxTest              ; Any data yet?
                bcs     TransferScan
                inc     TEMP+0
                bne     TransferPoll
                inc     TEMP+1
                bne     TransferPoll
                inc     TEMP+2
                bne     TransferPoll
                jsr     SendNAK                 ; Send a NAK
                bra     TransferWait
TransferScan:
                jsr     UartRx                  ; Wait for SOH or EOT
                cmp     #EOT
                beq     TransferDone
                cmp     #SOH
                bne     TransferWait
                jsr     UartRx                  ; Check the block number
                cmp     BLOCK
                bne     TransferError
                jsr     UartRx                  ; Check inverted block
                eor     #$ff
                cmp     BLOCK
                bne     TransferError

                ldy     #0
                sty     SUM                     ; Clear the check sum
TransferBlock:  jsr     UartRx
                sta     [ADDR_S],Y
                clc                             ; Add to check sum
                adc     SUM
                sta     SUM
                iny
                cpy     #128
                bne     TransferBlock
                jsr     UartRx                  ; Check the check sum
                cmp     SUM
                bne     TransferError           ; Failed
                clc
                tya
                adc     ADDR_S+0                ; Bump address one block
                sta     ADDR_S+0
                bcc     $+4
                inc     ADDR_S+1

                jsr     SendACK                 ; Acknowledge block
                inc     BLOCK                   ; Bump block number
                bra     TransferWait

TransferError;
                jsr     SendNAK                 ; Send a NAK
                jmp     TransferWait            ; And try again

TransferDone:
                jsr     SendACK                 ; Acknowledge transmission
                jmp     NewCommand              ; Done

SendACK:
                lda     #ACK
                jmp     UartTx

SendNAK:
                lda     #NAK
                jmp     UartTx

NotXModem:

;==============================================================================
; ? - Help
;------------------------------------------------------------------------------

                cmp     #'?'                    ; Help command?
                bne     NotHelp

                long_i
                ldx     #HELP                   ; Output help string
                jsr     UartStr
                jmp     NewCommand
NotHelp:

ShowError:
                long_i
                ldx     #ERROR                  ; Output error message
                jsr     UartStr
                jmp     NewCommand

;==============================================================================
;------------------------------------------------------------------------------

GetByte:
                stz     0,x                     ; Set the target address
                jsr     SkipSpaces              ; Skip to first real characater
                bcc     $+3
                rts                             ; None found
                jsr     IsHexDigit              ; Must have atleast one digit
                bcc     ByteFail
                jsr     AddDigit
                jsr     NextChar
                bcs     ByteDone
                jsr     IsHexDigit
                bcc     ByteDone
                jsr     AddDigit
ByteDone:       clc
                rts
ByteFail:       sec
                rts

GetAddr:
                stz     0,x                     ; Set the target address
                stz     1,x
                lda     BANK
                sta     2,x
                jsr     SkipSpaces              ; Skip to first real characater
                bcc     $+3
                rts                             ; None found
                jsr     IsHexDigit              ; Must have atleast one digit
                bcc     AddrFail
                jsr     AddDigit
                jsr     NextChar
                bcs     AddrDone
                jsr     IsHexDigit
                bcc     AddrDone
                jsr     AddDigit
                jsr     NextChar
                bcs     AddrDone
                jsr     IsHexDigit
                bcc     AddrDone
                jsr     AddDigit
                jsr     NextChar
                bcs     AddrDone
                jsr     IsHexDigit
                bcc     AddrDone
                jsr     AddDigit
AddrDone:       clc
                rts
AddrFail:       sec
                rts

AddDigit:
                sec                             ; Convert ASCII to binary
                sbc     #'0'
                cmp     #$0a
                bcc     $+4
                sbc     #7

                asl     0,x                     ; Shift up one nybble
                rol     1,x
                asl     0,x
                rol     1,x
                asl     0,x
                rol     1,x
                asl     0,x
                rol     1,x

                ora     0,x                     ; Merge in new digit
                sta     0,x                     ; Then get next digit
                rts

; Get the next character from the command buffer updating the position in X.
; Set the carry if the end of the buffer is reached.

NextChar:
                cpy     BUFLEN                  ; Any characters left?
                bcc     $+3
                rts
                lda     BUFFER,y
                iny
                jmp     ToUpperCase

SkipSpaces:
                jsr     NextChar                ; Fetch next character
                bcc     $+3                     ; Any left?
                rts                             ; No
                cmp     #' '                    ; Is it a space?
                beq     SkipSpaces              ; Yes, try again
                clc
                rts                             ; Done

; If the character in A is lower case then convert it to upper case.

ToUpperCase:
                jsr     IsLowerCase             ; Test the character
                bcc     $+4
                sbc     #32                     ; Convert lower case
                clc
                rts                             ; Done

; Determine if the character in A is a lower case letter. Set the carry if it
; is, otherwise clear it.

IsLowerCase:
                cmp     #'a'                    ; Between a and z?
                bcc     ClearCarry
                cmp     #'z'+1
                bcs     ClearCarry
SetCarry:       sec
                rts
ClearCarry:     clc
                rts

; Determine if the character in A is a hex character. Set the carry if it is,
; otherwise clear it.

IsHexDigit:
                cmp     #'0'                    ; Between 0 and 9?
                bcc     ClearCarry
                cmp     #'9'+1
                bcc     SetCarry
                cmp     #'A'                    ; Between A and F?
                bcc     ClearCarry
                cmp     #'F'+1
                bcc     SetCarry
                bra     ClearCarry

; Determine if the character in A is a printable character. Set the carry if it
; is, otherwise clear it.

IsPrintable:
                cmp     #' '
                bcc     ClearCarry
                cmp     #DEL
                bcc     SetCarry
                bra     ClearCarry

;==============================================================================
;------------------------------------------------------------------------------

UartHex2:
                pha                             ; Save the original byte
                lsr     a                       ; Shift down hi nybble
                lsr     a
                lsr     a
                lsr     a
                jsr     UartHex                 ; Display
                pla                             ; Recover data byte

UartHex:
                and     #$0f                    ; Strip out lo nybble
                sed                             ; Convert to ASCII
                clc
                adc     #$90
                adc     #$40
                cld
                jmp     UartTx                  ; And display

; Display the string of characters starting a the memory location pointed to by
; X (16-bits).

UartStr:
                lda     0,x
                bne     $+3
                rts
                jsr     UartTx
                inx
                bra     UartStr

; Display a CR/LF control character sequence.

UartCRLF:
                jsr     UartCR
                lda     #LF
                jmp     UartTx
UartCR:         lda     #CR
                jmp     UartTx

;==============================================================================
; String Literals
;------------------------------------------------------------------------------

TITLE           db      CR,LF,"W65C816SXB-Hacker [15.08]",0

ERROR           db      CR,LF,"Error - Type ? for help",0

NOT_SAFE        db      CR,LF,"WDC ROM Bank Selected",0

WAITING         db      CR,LF,"Waiting for XMODEM transfer to start",0

HELP            db      CR,LF,"B bb           - Set memory bank"
                db      CR,LF,"M bbbb eeee    - Display memory in current bank"
                db      CR,LF,"R 0-3          - Select ROM bank 0-3"
                db      CR,LF,"U              - Perform ROM unlock sequence"
                db      CR,LF,"X bbbb         - XMODEM upload to current bank"
                db      0

                end
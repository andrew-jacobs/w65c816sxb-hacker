;===============================================================================
;  ______  ______        _   _            _
; / ___\ \/ / __ )      | | | | __ _  ___| | _____ _ __
; \___ \\  /|  _ \ _____| |_| |/ _` |/ __| |/ / _ \ '__|
;  ___) /  \| |_) |_____|  _  | (_| | (__|   <  __/ |
; |____/_/\_\____/      |_| |_|\__,_|\___|_|\_\___|_|
;
; A program for Hacking your W65C816SXB
;-------------------------------------------------------------------------------
; Copyright (C)2015 Andrew Jacobs
; All rights reserved.
;
; This work is made available under the terms of the Creative Commons
; Attribution-NonCommercial-ShareAlike 4.0 International license. Open the
; following URL to see the details.
;
; http://creativecommons.org/licenses/by-nc-sa/4.0/
;
;===============================================================================
; Notes:
;
; This program provides a simple monitor that you can use to inspect the memory
; in your W65C816SXB and reprogram parts of the flash ROM.
;
;-------------------------------------------------------------------------------

                pw      132
                inclist on

                chip    65816
                longi   off
                longa   off

                include "w65c816.inc"
                include "w65c816sxb.inc"

;===============================================================================
; ASCII Character Codes
;-------------------------------------------------------------------------------

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

;===============================================================================
; Data Areas
;-------------------------------------------------------------------------------

                page0
                org     $20

BUFLEN          ds      1                       ; Command buffer length
BANK            ds      1                       ; Memory bank

ADDR_S          ds      3                       ; Start address
ADDR_E          ds      3                       ; End address

BLOCK           ds      1                       ; XMODEM block number
RETRIES         ds      1                       ; Retry count
SUM             ds      1                       ; Checksum

TEMP            ds      4                       ; Scratch workspace

                data
                org     $200

BUFFER          ds      128                     ; Command buffer

;===============================================================================
; Initialisation
;-------------------------------------------------------------------------------

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

;===============================================================================
; Command Processor
;-------------------------------------------------------------------------------

NewCommand:
                stz     BUFLEN                  ; Clear the buffer
ShowCommand:
                short_i
                jsr     UartCRLF                ; Move to a new line

                lda     #'.'                    ; Output the prompt
                jsr     UartTx

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

;===============================================================================
; B - Select Memory Bank
;-------------------------------------------------------------------------------

                cmp     #'B'                    ; Select memory bank?
                bne     NotMemoryBank

                ldx     #BANK                   ; Parse bank
                jsr     GetByte
                bcc     $+5
                jmp     ShowError
                jmp     NewCommand
NotMemoryBank:

;===============================================================================
; E - Erase ROM bank
;-------------------------------------------------------------------------------

                cmp     #'E'                    ; Erase bank?
                bne     NotEraseBank

                jsr     CheckSafe

                lda     #$00                    ; Set start address
                sta     ADDR_S+0
                lda     #$80
                sta     ADDR_S+1
EraseLoop:
                lda     #$aa                    ; Unlock flash
                sta     $8000+$5555
                lda     #$55
                sta     $8000+$2aaa
                lda     #$80                    ; Signal erase
                sta     $8000+$5555
                lda     #$aa
                sta     $8000+$5555
                lda     #$55
                sta     $8000+$2aaa
                lda     #$30                    ; Sector erase
                sta     (ADDR_S)

EraseWait:
                lda     (ADDR_S)                ; Wait for erase to finish
                cmp     #$FF
                bne     EraseWait

                clc                             ; Move to next sector
                lda     ADDR_S+1
                adc     #$10
                sta     ADDR_S+1
                bcc     EraseLoop               ; Repeat until end of memory
                jmp     NewCommand              ; And start over

EraseFailed:
                long_i                          ; Warn that erase failed
                ldx     #ERASE_FAILED
                jsr     UartStr
                longi   off
                jmp     NewCommand              ; And start over
NotEraseBank:

;===============================================================================
; G - Goto
;-------------------------------------------------------------------------------

                cmp     #'G'                    ; Invoke code
                bne     NotGoto

                ldx     #ADDR_S                 ; Parse execution address
                jsr     GetAddr
                bcs     $+5
                jmp     [ADDR_S]                ; Run from address
                jmp     ($FFFC)                 ; Otherwise reset
NotGoto:

;===============================================================================
; M - Display Memory
;-------------------------------------------------------------------------------

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

;===============================================================================
; S - S19 Record
;-------------------------------------------------------------------------------

                cmp     #'S'                    ; S19?
                beq     $+5
                jmp     NotS19

                jsr     NextChar                ; Get record type
                bcs     S19Fail
                cmp     #'1'                    ; Only process type 1
                bne     S19Done

                ldx     #ADDR_E                 ; Get byte count
                jsr     GetByte
                bcs     S19Fail
                lda     ADDR_E                  ; Use as initial checksum
                sta     SUM
                dec     ADDR_E
                beq     S19Fail

                ldx     #ADDR_S                 ; Get address
                jsr     GetAddr
                bcs     S19Fail
                lda     ADDR_S+0                ; Add to checksum
                adc     ADDR_S+1
                clc
                adc     SUM
                sta     SUM
                dec     ADDR_E
                beq     S19Fail
                dec     ADDR_E
                beq     S19Fail

S19Load:
                ldx     #TEMP                   ; Fetch a data byte
                jsr     GetByte
                bcs     S19Fail
                lda     TEMP
                adc     SUM
                sta     SUM
                dec     ADDR_E
                beq     S19Fail

                lda     ADDR_S+2                ; Writing to ROM?
                bne     WriteS19                ; No
                bit     ADDR_S+1
                bpl     WriteS19                ; No

                lda     #$aa                    ; Yes, unlock flash
                sta     $8000+$5555
                lda     #$55
                sta     $8000+$2aaa
                lda     #$a0                    ; Start byte write
                sta     $8000+$5555
WriteS19:
                lda     TEMP                    ; Write the value
                sta     [ADDR_S]

                inc     ADDR_S+0                ; Bump address by one
                bne     $+4
                inc     ADDR_S+1

                lda     ADDR_E                  ; Reached checksum?
                cmp     #1
                bne     S19Load

                ldx     #TEMP                   ; Yes, read it
                jsr     GetByte
                bcs     S19Fail
                lda     TEMP
                adc     SUM
                cmp     #$ff                    ; Checksum correct?
                bne     S19Fail

S19Done:        jmp     NewCommand              ; Get

S19Fail:
                long_i                          ; Display error message
                ldx     #INVALID_S19
                jsr     UartStr
                longi   off
                jmp     NewCommand              ; And start over
NotS19:

;===============================================================================
; R - Select ROM Bank
;-------------------------------------------------------------------------------

                cmp     #'R'                    ; ROM Bank?
                bne     NotROMBank              ; No

                jsr     SkipSpaces              ; Find first argument
                bcc     $+5                     ; Success?
BankFail:       jmp     ShowError               ; No

                cmp     #'0'                    ; Check bank is 0..3
                bcc     BankFail
                cmp     #'3'+1
                bcs     BankFail

                sta     TEMP                    ; Work out VIA settings
                lda     #0
                ror     TEMP                    ; Bit 0 set
                bcs     $+4
                ora     #%00001100              ; No, make CA2 (A15) low
                ror     TEMP                    ; Bit 1 set
                bcs     $+4
                ora     #%11000000              ; No, make CB2 (FAMS) low
                sta     VIA2_PCR                ; Set ROM select lines

                jmp     NewCommand              ; Done
NotROMBank:

;===============================================================================
; W - Write memory
;-------------------------------------------------------------------------------

                cmp     #'W'                    ; Write memory?
                bne     NotWrite

                ldx     #ADDR_S                 ; Parse start address
                jsr     GetAddr
                bcc     $+5
                jmp     ShowError

                bit     ADDR_S+1                ; Load into ROM area?
                bpl     $+5
                jsr     CheckSafe               ; Yes, check selection

                ldx     #ADDR_E                 ; Parse value byte
                jsr     GetByte                 ; Is there a value?
                bcc     $+5
                jmp     NewCommand              ; No.

                lda     ADDR_S+2                ; Writing to ROM?
                bne     WriteMemory             ; No
                bit     ADDR_S+1
                bpl     WriteMemory             ; No

                lda     #$aa                    ; Yes, unlock flash
                sta     $8000+$5555
                lda     #$55
                sta     $8000+$2aaa
                lda     #$a0                    ; Start byte write
                sta     $8000+$5555
WriteMemory:
                lda     ADDR_E                  ; Write the value
                sta     [ADDR_S]

                inc     ADDR_S+0                ; Bump address by one
                bne     $+4
                inc     ADDR_S+1

                lda     #'W'                    ; Build command for next byte
                jsr     StartCommand
                lda     #' '
                jsr     BuildCommand
                lda     ADDR_S+1                ; Add the next address
                jsr     BuildByte
                lda     ADDR_S+0
                jsr     BuildByte
                lda     #' '
                jsr     BuildCommand
                jmp     ShowCommand             ; And prompt for data

NotWrite:

;===============================================================================
; X - XMODEM Upload
;-------------------------------------------------------------------------------

                cmp     #'X'                    ; XModem upload?
                beq     $+5                     ; Yes.
                jmp     NotXModem

                ldx     #ADDR_S                 ; Parse start address
                jsr     GetAddr
                bcc     $+5
                jmp     ShowError

                bit     ADDR_S+1                ; Load into ROM area?
                bpl     $+5
                jsr     CheckSafe               ; Yes, check selection

                long_i                          ; Display waiting message
                ldx     #WAITING
                jsr     UartStr
                jsr     UartCRLF
                short_i
                stz     BLOCK                   ; Reset the block number
                inc     BLOCK

ResetRetries:
                lda     #10                     ; Reset the retry counter
                sta     RETRIES

TransferWait:
                stz     TEMP+0                  ; Clear timeout counter
                stz     TEMP+1
                lda     #-20
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
                dec     RETRIES
                beq     TimedOut
                jsr     SendNAK                 ; Send a NAK
                bra     TransferWait

TimedOut:
                long_i
                ldx     #TIMEOUT
                jsr     UartStr
                longi   off
                jmp     NewCommand

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
TransferBlock:
                jsr     UartRx
                pha

                lda     ADDR_S+2                ; Writing to ROM?
                bne     WriteByte               ; No
                bit     ADDR_S+1
                bpl     WriteByte               ; No

                lda     #$aa                    ; Yes, unlock flash
                sta     $8000+$5555
                lda     #$55
                sta     $8000+$2aaa
                lda     #$a0                    ; Start byte write
                sta     $8000+$5555

WriteByte:
                pla
                sta     [ADDR_S],Y

WriteWait:
                cmp     [ADDR_S],Y              ; Wait for write
                bne     WriteWait

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
                jmp     TransferWait

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

;===============================================================================
; ? - Help
;-------------------------------------------------------------------------------

                cmp     #'?'                    ; Help command?
                bne     NotHelp

                long_i
                ldx     #HELP                   ; Output help string
                jsr     UartStr
                longi   off
                jmp     NewCommand
NotHelp:

;-------------------------------------------------------------------------------

ShowError:
                long_i
                ldx     #ERROR                  ; Output error message
                jsr     UartStr
                longi   off
                jmp     NewCommand

;===============================================================================
;-------------------------------------------------------------------------------

; Checks if an expendable ROM bank is currently selected. If the bank with the
; WDC firmware is selected then warn and accept a new command.

CheckSafe:
                lda     VIA2_PCR                ; WDC ROM selected?
                and     #%11001100
                beq     $+3
                rts                             ; No, save to change

                pla                             ; Discard return address
                pla
                long_i                          ; Complain about bank
                ldx     #NOT_SAFE
                jsr     UartStr
                longi   off
                jmp     NewCommand              ; And start over

;===============================================================================
; Byte and Word Parsing
;-------------------------------------------------------------------------------

; Parse a hex byte from the command line and store it at the location indicated
; by the X register.

GetByte:
                stz     0,x                     ; Set the target address
                jsr     SkipSpaces              ; Skip to first real character
                bcc     $+3
                rts                             ; None found
                jsr     IsHexDigit              ; Must have at least one digit
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

; Parse an address from the command line and store it at the location indicated
; by the X register.

GetAddr:
                stz     0,x                     ; Set the target address
                stz     1,x
                lda     BANK
                sta     2,x
                jsr     SkipSpaces              ; Skip to first real character
                bcc     $+3
                rts                             ; None found

                jsr     IsHexDigit              ; Must have at least one digit
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
AddrDone:       clc                             ; Carry clear got an address
                rts
AddrFail:       sec                             ; Carry set -- failed.
                rts

; Add a hex digit to the 16-bit value being build at at the location indicated
; by X.

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
                sta     0,x                     ; .. and save
                rts

;===============================================================================
; Command Line Parsing and Building
;-------------------------------------------------------------------------------

; Get the next character from the command buffer updating the position in X.
; Set the carry if the end of the buffer is reached.

NextChar:
                cpy     BUFLEN                  ; Any characters left?
                bcc     $+3
                rts
                lda     BUFFER,y
                iny
                jmp     ToUpperCase

; Skip over any spaces until a non-space character or the end of the string
; is reached.

SkipSpaces:
                jsr     NextChar                ; Fetch next character
                bcc     $+3                     ; Any left?
                rts                             ; No
                cmp     #' '                    ; Is it a space?
                beq     SkipSpaces              ; Yes, try again
                clc
                rts                             ; Done

; Clear the buffer and the add the command character in A.

StartCommand:
                stz     BUFLEN                  ; Clear the character cound

; Append the character in A to the command being built updating the length.

BuildCommand:
                ldy     BUFLEN
                inc     BUFLEN
                sta     BUFFER,y
                rts

; Convert the value in A into hex characters and append to the command buffer.

BuildByte:
                pha                             ; Save the value
                lsr     a                       ; Shift MS nybble down
                lsr     a
                lsr     a
                lsr     a
                jsr     HexToAscii              ; Convert to ASCII
                jsr     BuildCommand            ; .. and add to command
                pla                             ; Pull LS nybble
                jsr     HexToAscii              ; Convert to ASCII
                jmp     BuildCommand            ; .. and add to command

;===============================================================================
; Character Classification
;-------------------------------------------------------------------------------

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

;===============================================================================
; Display Utilities
;-------------------------------------------------------------------------------

; Display the value in A as two hexadecimal digits.

UartHex2:
                pha                             ; Save the original byte
                lsr     a                       ; Shift down hi nybble
                lsr     a
                lsr     a
                lsr     a
                jsr     UartHex                 ; Display
                pla                             ; Recover data byte

; Display the LSB of the value in A as a hexadecimal digit using decimal
; arithmetic to do the conversion.

UartHex:
                jsr     HexToAscii              ; Convert to ASCII
                jmp     UartTx                  ; And display

; Convert a LSB of the value in A to a hexadecimal digit using decimal
; arithmetic.

HexToAscii:
                and     #$0f                    ; Strip out lo nybble
                sed                             ; Convert to ASCII
                clc
                adc     #$90
                adc     #$40
                cld
                rts                             ; Done

; Display the string of characters starting a the memory location pointed to by
; X (16-bits).

UartStr:
                lda     0,x                     ; Fetch the next character
                bne     $+3                     ; Return it end of string
                rts
                jsr     UartTx                  ; Otherwise print it
                inx                             ; Bump the pointer
                bra     UartStr                 ; And repeat

; Display a CR/LF control character sequence.

UartCRLF:
                jsr     UartCR                  ; Transmit a CR
                lda     #LF                     ; Followed by a LF
                jmp     UartTx

UartCR:         lda     #CR                     ; Transmit a CR
                jmp     UartTx

;===============================================================================
; String Literals
;-------------------------------------------------------------------------------

TITLE           db      CR,LF,"W65C816SXB-Hacker [15.11]",0

ERROR           db      CR,LF,"Error - Type ? for help",0

ERASE_FAILED    db      CR,LF,"Erase failed",0
WRITE_FAILED    db      CR,LF,"Write failed",0
NOT_SAFE        db      CR,LF,"WDC ROM Bank Selected",0
INVALID_S19     db      CR,LF,"Invalid S19 record",0

WAITING         db      CR,LF,"Waiting for XMODEM transfer to start",0
TIMEOUT         db      CR,LF,"Timeout",0

HELP            db      CR,LF,"B bb           - Set memory bank"
                db      CR,LF,"E              - Erase ROM area"
                db      CR,LF,"G [xxxx]       - Run from bb:xxxx or invoke reset vector"
                db      CR,LF,"M ssss eeee    - Display memory in current bank"
                db      CR,LF,"R 0-3          - Select ROM bank 0-3"
                db      CR,LF,"S...           - Process S19 record"
                db      CR,LF,"W xxxx bb      - Set memory at xxxx to bb"
                db      CR,LF,"X xxxx         - XMODEM upload to bb:xxxx"
                db      0

                end
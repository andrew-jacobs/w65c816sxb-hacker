;===============================================================================
;  ______  ______        _   _            _
; / ___\ \/ / __ )      | | | | __ _  ___| | _____ _ __
; \___ \\  /|  _ \ _____| |_| |/ _` |/ __| |/ / _ \ '__|
;  ___) /  \| |_) |_____|  _  | (_| | (__|   <  __/ |
; |____/_/\_\____/      |_| |_|\__,_|\___|_|\_\___|_|
;
; A program for Hacking your W65C265SXB or W65C816SXB
;-------------------------------------------------------------------------------
; Copyright (C),2015-2018 Andrew Jacobs
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
; in your SXB and reprogram parts of the flash ROM.
;
;-------------------------------------------------------------------------------

                pw      132
                inclist on

                chip    65816

                ifdef   W65C265SXB
                include "w65c265.inc"
                else
                include "w65c816.inc"
                endif

;===============================================================================
;-------------------------------------------------------------------------------

MNEM            macro   P,Q,R
                dw      ((((P-'@')<<5)|(Q-'@'))<<5)|(R-'@')
                endm

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
;-------------------------------------------------------------------------------

OP_ADC          equ     0<<1
OP_AND          equ     1<<1
OP_ASL          equ     2<<1
OP_BCC          equ     3<<1
OP_BCS          equ     4<<1
OP_BEQ          equ     5<<1
OP_BIT          equ     6<<1
OP_BMI          equ     7<<1
OP_BNE          equ     8<<1
OP_BPL          equ     9<<1
OP_BRA          equ     10<<1
OP_BRK          equ     11<<1
OP_BRL          equ     12<<1
OP_BVC          equ     13<<1
OP_BVS          equ     14<<1
OP_CLC          equ     15<<1
OP_CLD          equ     16<<1
OP_CLI          equ     17<<1
OP_CLV          equ     18<<1
OP_CMP          equ     19<<1
OP_COP          equ     20<<1
OP_CPX          equ     21<<1
OP_CPY          equ     22<<1
OP_DEC          equ     23<<1
OP_DEX          equ     24<<1
OP_DEY          equ     25<<1
OP_EOR          equ     26<<1
OP_INC          equ     27<<1
OP_INX          equ     28<<1
OP_INY          equ     29<<1
OP_JML          equ     30<<1
OP_JMP          equ     31<<1
OP_JSL          equ     32<<1
OP_JSR          equ     33<<1
OP_LDA          equ     34<<1
OP_LDX          equ     35<<1
OP_LDY          equ     36<<1
OP_LSR          equ     37<<1
OP_MVN          equ     38<<1
OP_MVP          equ     39<<1
OP_NOP          equ     40<<1
OP_ORA          equ     41<<1
OP_PEA          equ     42<<1
OP_PEI          equ     43<<1
OP_PER          equ     44<<1
OP_PHA          equ     45<<1
OP_PHB          equ     46<<1
OP_PHD          equ     47<<1
OP_PHK          equ     48<<1
OP_PHP          equ     49<<1
OP_PHX          equ     50<<1
OP_PHY          equ     51<<1
OP_PLA          equ     52<<1
OP_PLB          equ     53<<1
OP_PLD          equ     54<<1
OP_PLP          equ     55<<1
OP_PLX          equ     56<<1
OP_PLY          equ     57<<1
OP_REP          equ     58<<1
OP_ROL          equ     59<<1
OP_ROR          equ     60<<1
OP_RTI          equ     61<<1
OP_RTL          equ     62<<1
OP_RTS          equ     63<<1
OP_SBC          equ     64<<1
OP_SEC          equ     65<<1
OP_SED          equ     66<<1
OP_SEI          equ     67<<1
OP_SEP          equ     68<<1
OP_STA          equ     69<<1
OP_STP          equ     70<<1
OP_STX          equ     71<<1
OP_STY          equ     72<<1
OP_STZ          equ     73<<1
OP_TAX          equ     74<<1
OP_TAY          equ     75<<1
OP_TCD          equ     76<<1
OP_TCS          equ     77<<1
OP_TDC          equ     78<<1
OP_TRB          equ     79<<1
OP_TSB          equ     80<<1
OP_TSC          equ     81<<1
OP_TSX          equ     82<<1
OP_TXA          equ     83<<1
OP_TXS          equ     84<<1
OP_TXY          equ     85<<1
OP_TYA          equ     86<<1
OP_TYX          equ     87<<1
OP_WAI          equ     88<<1
OP_WDM          equ     89<<1
OP_XBA          equ     90<<1
OP_XCE          equ     91<<1

MD_ABS          equ     0<<1                    ; a
MD_ACC          equ     1<<1                    ; A
MD_ABX          equ     2<<1                    ; a,x
MD_ABY          equ     3<<1                    ; a,y
MD_ALG          equ     4<<1                    ; al
MD_ALX          equ     5<<1                    ; al,x
MD_AIN          equ     6<<1                    ; (a)
MD_AIX          equ     7<<1                    ; (a,x)
MD_DPG          equ     8<<1                    ; d
MD_STK          equ     9<<1                    ; d,s
MD_DPX          equ     10<<1                   ; d,x
MD_DPY          equ     11<<1                   ; d,x
MD_DIN          equ     12<<1                   ; (d)
MD_DLI          equ     13<<1                   ; [d]
MD_SKY          equ     14<<1                   ; (d,s),y
MD_DIX          equ     15<<1                   ; (d,x)
MD_DIY          equ     16<<1                   ; (d),y
MD_DLY          equ     17<<1                   ; [d],y
MD_IMP          equ     18<<1                   ;
MD_REL          equ     19<<1                   ; r
MD_RLG          equ     20<<1                   ; rl
MD_MOV          equ     21<<1                   ; xyc
MD_IMM          equ     22<<1                   ; # (A or M)
MD_INT          equ     23<<1                   ; # (BRK/COP/WDM)
MD_IMX          equ     24<<1                   ; # (X or Y)

;===============================================================================
; Data Areas
;-------------------------------------------------------------------------------

                page0
                org     $20

FLAGS           ds      1                       ; Emulated processor flags
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
                extern  RomSelect
                extern  RomCheck
Start:
                short_a                         ; Configure register sizes
                long_i
                jsr     TxCRLF
                ldx     #TITLE                  ; Display application title
                jsr     TxStr

                stz     BANK                    ; Reset default bank

;===============================================================================
; Command Processor
;-------------------------------------------------------------------------------

NewCommand:
                stz     BUFLEN                  ; Clear the buffer
ShowCommand:
                short_i
                jsr     TxCRLF                  ; Move to a new line

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
                sta     BUFFER,x                ; Save the character
                inx
                jsr     UartTx                  ; Echo it and repeat
                bra     ReadCommand

BackSpace:
                cpx     #0                      ; Buffer empty?
                beq     RingBell                ; Yes, beep and continue
                dex                             ; No, remove last character
                lda     #BS
                jsr     UartTx
                jsr     TxSpace
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
; D - Disassemble Memory
;-------------------------------------------------------------------------------

                cmp     #'D'                    ; Memory display?
                bne     NotDisassemble

                ldx     #ADDR_S                 ; Parse start address
                jsr     GetAddr
                bcc     $+5
                jmp     ShowError
                ldx     #ADDR_E                 ; Parse end address
                jsr     GetAddr
                bcc     $+5
                jmp     ShowError

                php
                pla
                sta     FLAGS

Disassemble:
                jsr     TxCRLF
                lda     ADDR_S+2                ; Show memory address
                jsr     TxHex2
                lda     #':'
                jsr     UartTx
                lda     ADDR_S+1
                jsr     TxHex2
                lda     ADDR_S+0
                jsr     TxHex2
                jsr     TxSpace

                jsr     TxCodeBytes             ; Show code bytes
                jsr     TxSymbolic              ; And instruction

                lda     [ADDR_S]                ; Fetch opcode again
                pha
                ldy     #1

                cmp     #$18                    ; CLC?
                bne     NotCLC
                lda     #C_FLAG
                bra     DoREP
NotCLC:
                cmp     #$38                    ; SEC?
                bne     NotSEC
                lda     #C_FLAG
                bra     DoSEP
NotSEC:
                cmp     #$c2                    ; REP?
                bne     NotREP
                lda     [ADDR_S],Y
DoREP:          trb     FLAGS
                bra     NextOpcode
NotREP:
                cmp     #$e2                    ; SEP?
                bne     NextOpcode
                lda     [ADDR_S],Y
DoSEP:          tsb     FLAGS

NextOpcode:
                pla
                jsr     OpcodeSize

                clc
                adc     ADDR_S+0                ; And move start address on
                sta     ADDR_S+0
                bcc     $+4
                inc     ADDR_S+1

                sec                             ; Exceeded the end address?
                sbc     ADDR_E+0
                lda     ADDR_S+1
                sbc     ADDR_E+1
                bmi     Disassemble             ; No, show more

                jmp     NewCommand              ; Done
NotDisassemble:

;===============================================================================
; E - Erase ROM bank
;-------------------------------------------------------------------------------

                cmp     #'E'                    ; Erase bank?
                bne     NotEraseBank

                jsr     CheckSafe

                ifdef   W65C265SXB
                lda     BCR                     ; Save mask rom state
                pha
                lda     #$80                    ; Then ensure disabled
                tsb     BCR
                endif

                ldx     #ADDR_S                 ; Parse optional start address
                jsr     GetAddr
                bcc     SkipStartAddrInit

                lda     #$00                    ; Set default start address
                sta     ADDR_S+0
                lda     #$80
                sta     ADDR_S+1

SkipStartAddrInit:

                ldx     #ADDR_E                 ; Parse optional end address
                jsr     GetAddr
                bcc     SkipEndAddrInit

                lda     #$FF                    ; Set default end address
                sta     ADDR_E+0
                lda     #$FF
                sta     ADDR_E+1

SkipEndAddrInit:

                lda     ADDR_S+1                ; Ensure start is within ROM
                bmi     $+5
                jmp     ShowError

                lda     ADDR_E+1                ; Ensure end  is within ROM
                bmi     $+5
                jmp     ShowError

                lda     ADDR_S+1                ; Clip the starting address
                and     #$F0
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

                clc                             ; Clear C to include the end
                sbc     ADDR_E+1                ; addr in the range to erase.

                bmi     EraseLoop               ; Repeat until complete

                ifdef   W65C265SXB
                pla                             ; Restore mask ROM state
                sta     BCR
                endif

                jmp     NewCommand              ; And start over

EraseFailed:
                long_i                          ; Warn that erase failed
                ldx     #ERASE_FAILED
                jsr     TxStr
                longi   off
                jmp     NewCommand              ; And start over
NotEraseBank:

;===============================================================================
; F - WDC Mask ROM Enable/Disable
;-------------------------------------------------------------------------------

                ifdef   W65C265SXB
                cmp     #'F'
                bne     NotMaskROM

                jsr     SkipSpaces              ; Find first argument
                bcs     MaskFail                ; Success?

                cmp     #'0'                    ; Check bank is 0..3
                beq     MaskOff
                cmp     #'1'
                beq     MaskOn
MaskFail:
                jmp     ShowError

MaskOn:
                lda     #$80                    ; Enable mask ROM
                trb     BCR
                jmp     NewCommand

MaskOff:
                lda     #$80                    ; Disable mask ROM
                tsb     BCR
                jmp     NewCommand

NotMaskROM:
                endif

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
; H - Hunt for RAM
;-------------------------------------------------------------------------------

                cmp     #'H'                    ; Hunt for RAM
                beq     $+5
                jmp     NotHunt

                stz     ADDR_S+0                ; Start at $00:0000
                stz     ADDR_S+1
                stz     ADDR_S+2

HuntStart:
                lda     [ADDR_S]                ; Is byte is writeable?
                pha
                eor     #$ff
                sta     [ADDR_S]
                cmp     [ADDR_S]
                beq     HuntFound               ; Yes

                pla
                clc                             ; Try the next block
                lda     ADDR_S+1
                adc     #$10
                sta     ADDR_S+1
                bcc     HuntStart
                inc     ADDR_S+2
                bne     HuntStart
                jmp     NewCommand              ; Reached end of RAM

HuntFound:
                jsr     TxCRLF
                lda     ADDR_S+2                ; Print start address
                jsr     TxHex2
                lda     #':'
                jsr     UartTx
                lda     ADDR_S+1
                jsr     TxHex2
                lda     ADDR_S+0
                jsr     TxHex2

                lda     #'-'
                jsr     UartTx

HuntEnd:
                pla                             ; Restore memory bytes
                sta     [ADDR_S]
                clc                             ; Try the next block
                lda     ADDR_S+1
                adc     #$10
                sta     ADDR_S+1
                bcc     HuntNext
                inc     ADDR_S+2
                beq     HuntDone

HuntNext
                lda     [ADDR_S]                ; Is byte is writeable?
                pha
                eor     #$ff
                sta     [ADDR_S]
                cmp     [ADDR_S]
                beq     HuntEnd                 ; Yes, keep looking

                pla
                sec                             ; Print end address
                lda     ADDR_S+0
                sbc     #1
                pha
                lda     ADDR_S+1
                sbc     #0
                pha
                lda     ADDR_S+2
                sbc     #0
                jsr     TxHex2
                lda     #':'
                jsr     UartTx
                pla
                jsr     TxHex2
                pla
                jsr     TxHex2
                bra     HuntStart

HuntDone:
                lda     #$ff                    ; Pring FF:FFFF
                pha
                pha
                jsr     TxHex2
                lda     #':'
                jsr     UartTx
                pla
                jsr     TxHex2
                pla
                jsr     TxHex2
                jmp     NewCommand
NotHunt:

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
                jsr     TxCRLF
                lda     ADDR_S+2                ; Show memory address
                jsr     TxHex2
                lda     #':'
                jsr     UartTx
                lda     ADDR_S+1
                jsr     TxHex2
                lda     ADDR_S+0
                jsr     TxHex2

                ldy     #0                      ; Show sixteen bytes of data
ByteLoop:       jsr     TxSpace
                lda     [ADDR_S],y
                jsr     TxHex2
                iny
                cpy     #16
                bne     ByteLoop

                jsr     TxSpace
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

                jsr     RomSelect               ; Switch ROM banks
                jmp     NewCommand              ; Done
NotROMBank:

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
                ; Byte count not included in the S19 byte count field
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
                lda     ADDR_S+1
                bpl     WriteS19                ; No

                ifdef   W65C265SXB
                cmp     #$df                    ; Register page?
                beq     NoWrite
                endif

                lda     #$aa                    ; Yes, unlock flash
                sta     $8000+$5555
                lda     #$55
                sta     $8000+$2aaa
                lda     #$a0                    ; Start byte write
                sta     $8000+$5555
WriteS19:
                lda     TEMP                    ; Write the value
                sta     [ADDR_S]

NoWrite:
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
                jsr     TxStr
                longi   off
                jmp     NewCommand              ; And start over
NotS19:

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
; X - XMODEM Receive
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
                jsr     TxStr
                jsr     TxCRLF
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
                jsr     TxStr
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
                lda     ADDR_S+1
                bpl     WriteByte               ; No

                ifdef   W65C265SXB
                cmp     #$df                    ; Register page?
                beq     WriteSkip
                endif

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
                bra     $+3

WriteSkip:
                pla

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
                jsr     TxStr
                longi   off
                jmp     NewCommand
NotHelp:

;-------------------------------------------------------------------------------

ShowError:
                long_i
                ldx     #ERROR                  ; Output error message
                jsr     TxStr
                longi   off
                jmp     NewCommand

;===============================================================================
;-------------------------------------------------------------------------------

; Checks if an expendable ROM bank is currently selected. If the bank with the
; WDC firmware is selected then warn and accept a new command.

CheckSafe:
                jsr     RomCheck                ; WDC ROM selected?
                beq     $+3
                rts                             ; No, save to change

                pla                             ; Discard return address
                pla
                long_i                          ; Complain about bank
                ldx     #NOT_SAFE
                jsr     TxStr
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
                stz     BUFLEN                  ; Clear the character count

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

; If the character in MD_ACC is lower case then convert it to upper case.

ToUpperCase:
                jsr     IsLowerCase             ; Test the character
                bcc     $+4
                sbc     #32                     ; Convert lower case
                clc
                rts                             ; Done

; Determine if the character in MD_ACC is a lower case letter. Set the carry if it
; is, otherwise clear it.

                longa   off
IsLowerCase:
                cmp     #'a'                    ; Between a and z?
                bcc     ClearCarry
                cmp     #'z'+1
                bcs     ClearCarry
SetCarry:       sec
                rts
ClearCarry:     clc
                rts

; Determine if the character in MD_ACC is a hex character. Set the carry if it is,
; otherwise clear it.

                longa   off
IsHexDigit:
                cmp     #'0'                    ; Between 0 and 9?
                bcc     ClearCarry
                cmp     #'9'+1
                bcc     SetCarry
                cmp     #'A'                    ; Between MD_ACC and F?
                bcc     ClearCarry
                cmp     #'F'+1
                bcc     SetCarry
                bra     ClearCarry

; Determine if the character in MD_ACC is a printable character. Set the carry if it
; is, otherwise clear it.

                longa   off
IsPrintable:
                cmp     #' '
                bcc     ClearCarry
                cmp     #DEL
                bcc     SetCarry
                bra     ClearCarry

;===============================================================================
; Display Utilities
;-------------------------------------------------------------------------------

; Display the value in MD_ACC as two hexadecimal digits.

TxHex2:
                pha                             ; Save the original byte
                lsr     a                       ; Shift down hi nybble
                lsr     a
                lsr     a
                lsr     a
                jsr     UartHex                 ; Display
                pla                             ; Recover data byte

; Display the LSB of the value in MD_ACC as a hexadecimal digit using decimal
; arithmetic to do the conversion.

UartHex:
                jsr     HexToAscii              ; Convert to ASCII
                jmp     UartTx                  ; And display

; Convert a LSB of the value in MD_ACC to a hexadecimal digit using decimal
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

                .longa  off
                .longi  on
TxStr:
                lda     0,x                     ; Fetch the next character
                bne     $+3                     ; Return it end of string
                rts
                jsr     UartTx                  ; Otherwise print it
                inx                             ; Bump the pointer
                bra     TxStr                   ; And repeat

; Display a CR/LF control character sequence.

TxCRLF:
                jsr     TxCR                    ; Transmit a CR
                lda     #LF                     ; Followed by a LF
                jmp     UartTx

TxCR:
                lda     #CR                     ; Transmit a CR
                jmp     UartTx

TxSpace:
                lda     #' '                    ; Transmit a space
                jmp     UartTx

;===============================================================================
;-------------------------------------------------------------------------------

;

                longa   off
                longi   off
TxCodeBytes:
                lda     [ADDR_S]                ; Fetch the opcode
                jsr     OpcodeSize              ; and work out its size
                tax
                ldy     #0                      ; Clear byte count
CodeLoop:
                lda     [ADDR_S],Y              ; Fetch a byte of code
                jsr     TxHex2
                jsr     TxSpace
                iny
                dex
                bne     CodeLoop
PadLoop:
                cpy     #4                      ; Need to pad out?
                bne     $+3
                rts
                jsr     TxSpace
                jsr     TxSpace
                jsr     TxSpace
                iny
                bra     PadLoop

;

                longa   off
                longi   off
TxSymbolic:
                lda     [ADDR_S]                ; Fetch opcode
                pha
                jsr     TxOpcode
                pla
                jsr     TxOperand
                rts

;

                longa   off
                longi   off
TxOpcode:
                php                             ; Save register sizes
                tax                             ; Work out the mnemonic
                lda     OPCODES,x
                tax
                long_a
                lda     MNEMONICS,x

                pha                             ; Save last character
                lsr     a                       ; Shift second down
                lsr     a
                lsr     a
                lsr     a
                lsr     a
                pha                             ; Save it
                lsr     a                       ; Shift first down
                lsr     a
                lsr     a
                lsr     a
                lsr     a
                jsr     ExpandMnem              ; Print first
                pla
                jsr     ExpandMnem              ; .. second
                pla
                jsr     ExpandMnem              ; .. and third
                plp
                jsr     TxSpace
                rts

ExpandMnem:
                clc
                and     #$1f                    ; Expand letter code
                adc     #'@'
                jmp     UartTx

;

                longa   off
                longi   off
TxOperand:
                tax                             ; Work out addressing mode
                lda     MODES,x
                tax
                jmp     (MODE_SHOW,x)

MODE_SHOW:
                dw      TxAbsolute              ; a
                dw      TxAccumulator           ; A
                dw      TxAbsoluteX             ; a,x
                dw      TxAbsoluteY             ; a,y
                dw      TxLong                  ; al
                dw      TxLongX                 ; al,x
                dw      TxAbsoluteIndirect      ; (a)
                dw      TxAbsoluteXIndirect     ; (a,x)
                dw      TxDirect                ; d
                dw      TxStack                 ; d,s
                dw      TxDirectX               ; d,x
                dw      TxDirectY               ; d,y
                dw      TxDirectIndirect        ; (d)
                dw      TxDirectIndirectLong    ; [d]
                dw      TxStackIndirectY        ; (d,s),y
                dw      TxDirectXIndirect       ; (d,x)
                dw      TxDirectIndirectY       ; (d),y
                dw      TxDirectIndirectLongY   ; [d],y
                dw      TxImplied               ;
                dw      TxRelative              ; r
                dw      TxRelativeLong          ; rl
                dw      TxMove                  ; xyc
                dw      TxImmediateM            ; # (A & M)
                dw      TxImmediateByte         ; # (BRK/COP/WDM)
                dw      TxImmediateX            ; # (X or Y)


TxAccumulator:
                lda     #'A'
                jmp     UartTx

TxImmediateM:
                lda     #M_FLAG
                bit     FLAGS
                beq     TxImmediateWord
                bra     TxImmediateByte

TxImmediateX:
                lda     #X_FLAG
                bit     FLAGS
                beq     TxImmediateWord
                bra     TxImmediateByte

TxImplied:
                rts

TxMove:
                lda     #'$'
                jsr     UartTx
                ldy     #1
                lda     [ADDR_S],Y
                jsr     TxHex2
                lda     #','
                jsr     UartTx
                lda     #'$'
                jsr     UartTx
                iny
                lda     [ADDR_S],Y
                jmp     TxHex2

TxImmediateByte:
                lda     #'#'
                jsr     UartTx
                bra     TxDirect

TxImmediateWord:
                lda     #'#'
                jsr     UartTx
                bra     TxAbsolute

TxStack:
                jsr     TxDirect
                lda     #','
                jsr     UartTx
                lda     #'S'
                jmp     UartTx

TxDirect:
                lda     #'$'
                jsr     UartTx
                ldy     #1
                lda     [ADDR_S],Y
                jmp     TxHex2

TxDirectX:
                jsr     TxDirect
TxX:            lda     #','
                jsr     UartTx
                lda     #'X'
                jmp     UartTx

TxDirectY:
                jsr     TxDirect
TxY:            lda     #','
                jsr     UartTx
                lda     #'Y'
                jmp     UartTx

TxAbsolute:
                lda     #'$'
                jsr     UartTx
                ldy     #2
                lda     [ADDR_S],Y
                jsr     TxHex2
                dey
                lda     [ADDR_S],Y
                jmp     TxHex2

TxAbsoluteX:
                jsr     TxAbsolute
                bra     TxX

TxAbsoluteY:
                jsr     TxAbsolute
                bra     TxY

TxLong:
                lda     #'$'
                jsr     UartTx
                ldy     #3
                lda     [ADDR_S],Y
                jsr     TxHex2
                lda     #':'
                jsr     UartTx
                dey
                lda     [ADDR_S],Y
                jsr     TxHex2
                dey
                lda     [ADDR_S],Y
                jmp     TxHex2

TxLongX:
                jsr     TxLong
                bra     TxX

TxAbsoluteIndirect:
                lda     #'('
                jsr     UartTx
                jsr     TxAbsolute
                lda     #')'
                jmp     UartTx

TxAbsoluteXIndirect:
                lda     #'('
                jsr     UartTx
                jsr     TxAbsoluteX
                lda     #')'
                jmp     UartTx

TxDirectIndirect:
                lda     #'('
                jsr     UartTx
                jsr     TxDirect
                lda     #')'
                jmp     UartTx

TxDirectXIndirect:
                lda     #'('
                jsr     UartTx
                jsr     TxDirectX
                lda     #')'
                jmp     UartTx

TxDirectIndirectY:
                lda     #'('
                jsr     UartTx
                jsr     TxDirect
                lda     #')'
                jsr     UartTx
                jmp     TxY

TxDirectIndirectLong:
                lda     #'['
                jsr     UartTx
                jsr     TxDirect
                lda     #']'
                jmp     UartTx

TxDirectIndirectLongY:
                jsr     TxDirectIndirectLong
                jmp     TxY

TxStackIndirectY:
                lda     #'('
                jsr     UartTx
                jsr     TxStack
                lda     #')'
                jsr     UartTx
                jmp     TxY

TxRelative:
                ldx     ADDR_S+1                ; Work out next PC
                lda     ADDR_S+0
                clc
                adc     #2
                bcc     $+3
                inx

                pha                             ; Add relative offset
                ldy     #1
                lda     [ADDR_S],y
                bpl     $+3
                dex
                clc
                adc     1,s
                sta     1,s
                bcc     $+3
                inx
                bra     TxAddr

TxRelativeLong:
                ldx     ADDR_S+1                ; Work out next PC
                lda     ADDR_S+0
                clc
                adc     #3
                bcc     $+3
                inx

                clc                             ; Add relative offset
                ldy     #1
                adc     [ADDR_S],y
                pha
                iny
                txa
                adc     [ADDR_S],Y
                tax

TxAddr:
                lda     #'$'                    ; Print address
                jsr     UartTx
                txa
                jsr     TxHex2
                pla
                jmp     TxHex2

;  Returns the size of the opcode in A given the current flag settings.

                longa   off
                longi   off
OpcodeSize:
                tax                             ; Work out addressing mode
                lda     MODES,x
                tax
                jmp     (MODE_SIZE,x)

MODE_SIZE:
                dw      Size3                   ; a
                dw      Size1                   ; A
                dw      Size3                   ; a,x
                dw      Size3                   ; a,y
                dw      Size4                   ; al
                dw      Size4                   ; al,x
                dw      Size3                   ; (a)
                dw      Size3                   ; (a,x)
                dw      Size2                   ; d
                dw      Size2                   ; d,s
                dw      Size2                   ; d,x
                dw      Size2                   ; d,y
                dw      Size2                   ; (d)
                dw      Size2                   ; [d]
                dw      Size2                   ; (d,s),y
                dw      Size2                   ; (d,x)
                dw      Size2                   ; (d),y
                dw      Size2                   ; [d],y
                dw      Size1                   ;
                dw      Size2                   ; r
                dw      Size3                   ; rl
                dw      Size3                   ; xyc
                dw      TestM                   ; # (A & M)
                dw      Size2                   ; # (BRK/COP/WDM)
                dw      TestX                   ; # (X or Y)

TestM
                lda     #M_FLAG                 ; Is M bit set?
                and     FLAGS
                beq     Size3                   ; No, word
                bra     Size2                   ; else byte

TestX
                lda     #X_FLAG                 ; Is X bit set?
                and     FLAGS
                beq     Size3                   ; No, word
                bra     Size2                   ; else byte

Size1:          lda     #1
                rts
Size2:          lda     #2
                rts
Size3           lda     #3
                rts
Size4:          lda     #4
                rts

OPCODES:
                db      OP_BRK,OP_ORA,OP_COP,OP_ORA     ; 00
                db      OP_TSB,OP_ORA,OP_ASL,OP_ORA
                db      OP_PHP,OP_ORA,OP_ASL,OP_PHD
                db      OP_TSB,OP_ORA,OP_ASL,OP_ORA
                db      OP_BPL,OP_ORA,OP_ORA,OP_ORA     ; 10
                db      OP_TRB,OP_ORA,OP_ASL,OP_ORA
                db      OP_CLC,OP_ORA,OP_INC,OP_TCS
                db      OP_TRB,OP_ORA,OP_ASL,OP_ORA
                db      OP_JSR,OP_AND,OP_JSL,OP_AND     ; 20
                db      OP_BIT,OP_AND,OP_ROL,OP_AND
                db      OP_PLP,OP_AND,OP_ROL,OP_PLD
                db      OP_BIT,OP_AND,OP_ROL,OP_AND
                db      OP_BMI,OP_AND,OP_AND,OP_AND     ; 30
                db      OP_BIT,OP_AND,OP_ROL,OP_AND
                db      OP_SEC,OP_AND,OP_DEC,OP_TSC
                db      OP_BIT,OP_AND,OP_ROL,OP_AND
                db      OP_RTI,OP_EOR,OP_WDM,OP_EOR     ; 40
                db      OP_MVP,OP_EOR,OP_LSR,OP_EOR
                db      OP_PHA,OP_EOR,OP_LSR,OP_PHK
                db      OP_JMP,OP_EOR,OP_LSR,OP_EOR
                db      OP_BVC,OP_EOR,OP_EOR,OP_EOR     ; 50
                db      OP_MVN,OP_EOR,OP_LSR,OP_EOR
                db      OP_CLI,OP_EOR,OP_PHY,OP_TCD
                db      OP_JMP,OP_EOR,OP_LSR,OP_EOR
                db      OP_RTS,OP_ADC,OP_PER,OP_ADC     ; 60
                db      OP_STZ,OP_ADC,OP_ROR,OP_ADC
                db      OP_PLA,OP_ADC,OP_ROR,OP_RTL
                db      OP_JMP,OP_ADC,OP_ROR,OP_ADC
                db      OP_BVS,OP_ADC,OP_ADC,OP_ADC     ; 70
                db      OP_STZ,OP_ADC,OP_ROR,OP_ADC
                db      OP_SEI,OP_ADC,OP_PLY,OP_TDC
                db      OP_JMP,OP_ADC,OP_ROR,OP_ADC
                db      OP_BRA,OP_STA,OP_BRL,OP_STA     ; 80
                db      OP_STY,OP_STA,OP_STX,OP_STA
                db      OP_DEY,OP_BIT,OP_TXA,OP_PHB
                db      OP_STY,OP_STA,OP_STX,OP_STA
                db      OP_BCC,OP_STA,OP_STA,OP_STA     ; 90
                db      OP_STY,OP_STA,OP_STX,OP_STA
                db      OP_TYA,OP_STA,OP_TXS,OP_TXY
                db      OP_STZ,OP_STA,OP_STZ,OP_STA
                db      OP_LDY,OP_LDA,OP_LDX,OP_LDA     ; A0
                db      OP_LDY,OP_LDA,OP_LDX,OP_LDA
                db      OP_TAY,OP_LDA,OP_TAX,OP_PLB
                db      OP_LDY,OP_LDA,OP_LDX,OP_LDA
                db      OP_BCS,OP_LDA,OP_LDA,OP_LDA     ; B0
                db      OP_LDA,OP_LDY,OP_LDX,OP_LDA
                db      OP_CLV,OP_LDA,OP_TSX,OP_TYX
                db      OP_LDY,OP_LDA,OP_LDX,OP_LDA
                db      OP_CPY,OP_CMP,OP_REP,OP_CMP     ; C0
                db      OP_CPY,OP_CMP,OP_DEC,OP_CMP
                db      OP_INY,OP_CMP,OP_DEX,OP_WAI
                db      OP_CPY,OP_CMP,OP_DEC,OP_CMP
                db      OP_BNE,OP_CMP,OP_CMP,OP_CMP     ; D0
                db      OP_PEI,OP_CMP,OP_DEC,OP_CMP
                db      OP_CLD,OP_CMP,OP_PHX,OP_STP
                db      OP_JML,OP_CMP,OP_DEC,OP_CMP
                db      OP_CPX,OP_SBC,OP_SEP,OP_SBC     ; E0
                db      OP_CPX,OP_SBC,OP_INC,OP_SBC
                db      OP_INX,OP_SBC,OP_NOP,OP_XBA
                db      OP_CPX,OP_SBC,OP_INC,OP_SBC
                db      OP_BEQ,OP_SBC,OP_SBC,OP_SBC     ; F0
                db      OP_PEA,OP_SBC,OP_INC,OP_SBC
                db      OP_SED,OP_SBC,OP_PLX,OP_XCE
                db      OP_JSR,OP_SBC,OP_INC,OP_SBC

MODES:
                db      MD_INT,MD_DIX,MD_INT,MD_STK     ; 00
                db      MD_DPG,MD_DPG,MD_DPG,MD_DLI
                db      MD_IMP,MD_IMM,MD_ACC,MD_IMP
                db      MD_ABS,MD_ABS,MD_ABS,MD_ALG
                db      MD_REL,MD_DIY,MD_DIN,MD_SKY     ; 10
                db      MD_DPG,MD_DPX,MD_DPX,MD_DLY
                db      MD_IMP,MD_ABY,MD_ACC,MD_IMP
                db      MD_ABS,MD_ABX,MD_ABX,MD_ALX
                db      MD_ABS,MD_DIX,MD_ALG,MD_STK     ; 20
                db      MD_DPG,MD_DPG,MD_DPG,MD_DLI
                db      MD_IMP,MD_IMM,MD_ACC,MD_IMP
                db      MD_ABS,MD_ABS,MD_ABS,MD_ALG
                db      MD_REL,MD_DIY,MD_DIN,MD_SKY     ; 30
                db      MD_DPX,MD_DPX,MD_DPX,MD_DLY
                db      MD_IMP,MD_ABY,MD_ACC,MD_IMP
                db      MD_ABX,MD_ABX,MD_ABX,MD_ALX
                db      MD_IMP,MD_DIX,MD_INT,MD_STK     ; 40
                db      MD_MOV,MD_DPG,MD_DPG,MD_DLI
                db      MD_IMP,MD_IMM,MD_ACC,MD_IMP
                db      MD_ABS,MD_ABS,MD_ABS,MD_ALG
                db      MD_REL,MD_DIY,MD_DIN,MD_SKY     ; 50
                db      MD_MOV,MD_DPX,MD_DPX,MD_DLY
                db      MD_IMP,MD_ABY,MD_IMP,MD_IMP
                db      MD_ALG,MD_ABX,MD_ABX,MD_ALX
                db      MD_IMP,MD_DIX,MD_IMP,MD_STK     ; 60
                db      MD_DPG,MD_DPG,MD_DPG,MD_DLI
                db      MD_IMP,MD_IMM,MD_ACC,MD_IMP
                db      MD_AIN,MD_ABS,MD_ABS,MD_ALG
                db      MD_REL,MD_DIY,MD_DIN,MD_SKY     ; 70
                db      MD_DPX,MD_DPX,MD_DPX,MD_DLY
                db      MD_IMP,MD_ABY,MD_IMP,MD_IMP
                db      MD_AIX,MD_ABX,MD_ABX,MD_ALX
                db      MD_REL,MD_DIX,MD_RLG,MD_STK     ; 80
                db      MD_DPG,MD_DPG,MD_DPG,MD_DLI
                db      MD_IMP,MD_IMM,MD_IMP,MD_IMP
                db      MD_ABS,MD_ABS,MD_ABS,MD_ALG
                db      MD_REL,MD_DIY,MD_DIN,MD_SKY     ; 90
                db      MD_DPX,MD_DPX,MD_DPY,MD_DLY
                db      MD_IMP,MD_ABY,MD_IMP,MD_IMP
                db      MD_ABS,MD_ABX,MD_ABX,MD_ALX
                db      MD_IMX,MD_DIX,MD_IMX,MD_STK     ; A0
                db      MD_DPG,MD_DPG,MD_DPG,MD_DLI
                db      MD_IMP,MD_IMM,MD_IMP,MD_IMP
                db      MD_ABS,MD_ABS,MD_ABS,MD_ALG
                db      MD_REL,MD_DIY,MD_DIN,MD_SKY     ; B0
                db      MD_DPX,MD_DPX,MD_DPY,MD_DLY
                db      MD_IMP,MD_ABY,MD_IMP,MD_IMP
                db      MD_ABX,MD_ABX,MD_ABY,MD_ALX
                db      MD_IMX,MD_DIX,MD_INT,MD_STK     ; C0
                db      MD_DPG,MD_DPG,MD_DPG,MD_DLI
                db      MD_IMP,MD_IMM,MD_IMP,MD_IMP
                db      MD_ABS,MD_ABS,MD_ABS,MD_ALG
                db      MD_REL,MD_DIY,MD_DIN,MD_SKY     ; D0
                db      MD_IMP,MD_DPX,MD_DPX,MD_DLY
                db      MD_IMP,MD_ABY,MD_IMP,MD_IMP
                db      MD_AIN,MD_ABX,MD_ABX,MD_ALX
                db      MD_IMX,MD_DIX,MD_INT,MD_STK     ; E0
                db      MD_DPG,MD_DPG,MD_DPG,MD_DLI
                db      MD_IMP,MD_IMM,MD_IMP,MD_IMP
                db      MD_ABS,MD_ABS,MD_ABS,MD_ALG
                db      MD_REL,MD_DIY,MD_DIN,MD_SKY     ; F0
                db      MD_IMP,MD_DPX,MD_DPX,MD_DLY
                db      MD_IMP,MD_ABY,MD_IMP,MD_IMP
                db      MD_AIX,MD_ABX,MD_ABX,MD_ALX

MNEMONICS:
                MNEM    'A','D','C'
                MNEM    'A','N','D'
                MNEM    'A','S','L'
                MNEM    'B','C','C'
                MNEM    'B','C','S'
                MNEM    'B','E','Q'
                MNEM    'B','I','T'
                MNEM    'B','M','I'
                MNEM    'B','N','E'
                MNEM    'B','P','L'
                MNEM    'B','R','A'
                MNEM    'B','R','K'
                MNEM    'B','R','L'
                MNEM    'B','V','C'
                MNEM    'B','V','S'
                MNEM    'C','L','C'
                MNEM    'C','L','D'
                MNEM    'C','L','I'
                MNEM    'C','L','V'
                MNEM    'C','M','P'
                MNEM    'C','O','P'
                MNEM    'C','P','X'
                MNEM    'C','P','Y'
                MNEM    'D','E','C'
                MNEM    'D','E','X'
                MNEM    'D','E','Y'
                MNEM    'E','O','R'
                MNEM    'I','N','C'
                MNEM    'I','N','X'
                MNEM    'I','N','Y'
                MNEM    'J','M','L'
                MNEM    'J','M','P'
                MNEM    'J','S','L'
                MNEM    'J','S','R'
                MNEM    'L','D','A'
                MNEM    'L','D','X'
                MNEM    'L','D','Y'
                MNEM    'L','S','R'
                MNEM    'M','V','N'
                MNEM    'M','V','P'
                MNEM    'N','O','P'
                MNEM    'O','R','A'
                MNEM    'P','E','A'
                MNEM    'P','E','I'
                MNEM    'P','E','R'
                MNEM    'P','H','A'
                MNEM    'P','H','B'
                MNEM    'P','H','D'
                MNEM    'P','H','K'
                MNEM    'P','H','P'
                MNEM    'P','H','X'
                MNEM    'P','H','Y'
                MNEM    'P','L','A'
                MNEM    'P','L','B'
                MNEM    'P','L','D'
                MNEM    'P','L','P'
                MNEM    'P','L','X'
                MNEM    'P','L','Y'
                MNEM    'R','E','P'
                MNEM    'R','O','L'
                MNEM    'R','O','R'
                MNEM    'R','T','I'
                MNEM    'R','T','L'
                MNEM    'R','T','S'
                MNEM    'S','B','C'
                MNEM    'S','E','C'
                MNEM    'S','E','D'
                MNEM    'S','E','I'
                MNEM    'S','E','P'
                MNEM    'S','T','A'
                MNEM    'S','T','P'
                MNEM    'S','T','X'
                MNEM    'S','T','Y'
                MNEM    'S','T','Z'
                MNEM    'T','A','X'
                MNEM    'T','A','Y'
                MNEM    'T','C','D'
                MNEM    'T','C','S'
                MNEM    'T','D','C'
                MNEM    'T','R','B'
                MNEM    'T','S','B'
                MNEM    'T','S','C'
                MNEM    'T','S','X'
                MNEM    'T','X','A'
                MNEM    'T','X','S'
                MNEM    'T','X','Y'
                MNEM    'T','Y','A'
                MNEM    'T','Y','X'
                MNEM    'W','A','I'
                MNEM    'W','D','M'
                MNEM    'X','B','A'
                MNEM    'X','C','E'

;===============================================================================
; String Literals
;-------------------------------------------------------------------------------

TITLE           db      CR,LF
                ifdef   W65C816SXB
                db      "W65C816SXB"
                endif
                ifdef   W65C265SXB
                db      "W65C265SXB"
                endif
                db      "-Hacker (Enhanced) [19.00]",0

ERROR           db      CR,LF,"Error - Type ? for help",0

ERASE_FAILED    db      CR,LF,"Erase failed",0
WRITE_FAILED    db      CR,LF,"Write failed",0
NOT_SAFE        db      CR,LF,"WDC ROM Bank Selected",0
INVALID_S19     db      CR,LF,"Invalid S19 record",0

WAITING         db      CR,LF,"Waiting for XMODEM transfer to start",0
TIMEOUT         db      CR,LF,"Timeout",0

HELP            db      CR,LF,"B bb            - Set memory bank"
                db      CR,LF,"D ssss eeee     - Disassemble memory in current bank"
                db      CR,LF,"E [ssss] [eeee] - Erase ROM area"
                ifdef   W65C265SXB
                db      CR,LF,"F 0-1           - Disable/Enable WDC ROM"
                db      CR,LF,"H               - Hunt for RAM"
                endif
                db      CR,LF,"G [xxxx]        - Run from bb:xxxx or invoke reset vector"
                db      CR,LF,"M ssss eeee     - Display memory in current bank"
                db      CR,LF,"R 0-3           - Select ROM bank 0-3"
                db      CR,LF,"S...            - Process S19 record"
                db      CR,LF,"W xxxx yy       - Set memory at xxxx to yy"
                db      CR,LF,"X xxxx          - XMODEM receive to bb:xxxx"
                db      0

                end
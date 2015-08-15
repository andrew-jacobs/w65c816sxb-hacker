;==============================================================================
; __        ____  ____   ____ ___  _  __  ______  ______
; \ \      / / /_| ___| / ___( _ )/ |/ /_/ ___\ \/ / __ )
;  \ \ /\ / / '_ \___ \| |   / _ \| | '_ \___ \\  /|  _ \
;   \ V  V /| (_) |__) | |__| (_) | | (_) |__) /  \| |_) |
;    \_/\_/  \___/____/ \____\___/|_|\___/____/_/\_\____/
;
; Basic Vector Handling for the W65C816SXB Development Board
;------------------------------------------------------------------------------
; Copyright (C)2015 HandCoded Software Ltd.
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
;
;------------------------------------------------------------------------------

                pw      132
                inclist on

                chip    65816
                longi   off
                longa   off

                include "w65c816.inc"
                include "w65c816sxb.inc"

USE_FIFO        equ     0

;==============================================================================
; Power On Reset
;------------------------------------------------------------------------------

                code
                extern  Start
RESET:
		lda	VIA2_IER
		sta	VIA2_IER
                sei                             ; Stop interrupts
                ldx     #$ff
                txs

                if      USE_FIFO
                lda     #$1c
                sta     VIA2_DDRB
                lda     #$18
                sta     VIA2_ORB
                else
                stz     ACIA_CMD
                stz     ACIA_CTL
                stz     ACIA_SR

                lda     #%00011111              ; 8 bits, 1 stop bit, 19200 baud
                sta     ACIA_CTL
                lda     #%00001001              ; No parity, no interrupt
                sta     ACIA_CMD
                lda     ACIA_RXD                ; Clear receive buffer
                endif

                native
                jmp     Start                   ; Jump to the application start

;==============================================================================
; Interrupt Handlers
;------------------------------------------------------------------------------

; Handle IRQ and BRK interrupts in emulation mode.

IRQBRK:
                bra     $                       ; Loop forever

; Handle NMI interrupts in emulation mode.

NMIRQ:
                bra     $                       ; Loop forever

;------------------------------------------------------------------------------

; Handle IRQ interrupts in native mode.

IRQ:
                bra     $                       ; Loop forever

; Handle IRQ interrupts in native mode.

BRK:
                bra     $                       ; Loop forever

; Handle IRQ interrupts in native mode.

NMI:
                bra     $                       ; Loop forever

;------------------------------------------------------------------------------

; COP and ABORT interrupts are not handled.

COP:
                bra     $                       ; Loop forever

ABORT:
                bra     $                       ; Loop forever

;==============================================================================
; Buffered UART Interface
;------------------------------------------------------------------------------

; Adds the character in A to the transmit buffer. If the buffer is full then
; wait for it to drain.

                public  UartTx
UartTx:
                if      USE_FIFO
                phx
                php
                short_ai
                ldx     #$00                    ; Make data port all input
                stx     VIA2_DDRA
                sta     VIA2_ORA                ; Save the output character
                lda     #%01
TxWait:         bit     VIA2_IRB                ; Is there space for more data
                bne     TxWait

                lda     VIA2_IRB                ; Strobe WR
                and     #$fb
                tax
                ora     #$04
                sta     VIA2_ORB
                lda     #$ff                    ; Make data port all output
                sta     VIA2_DDRA
                nop
                nop
                stx     VIA2_ORB                ; End strobe
                lda     VIA2_IRA
                ldx     #$00                    ; Make data port all output
                stx     VIA2_DDRA
                plp
                plx
                rts

                else

                pha
                php
                short_a
                sta     ACIA_TXD
                jsr     TxDelay
                jsr     TxDelay
                jsr     TxDelay
                jsr     TxDelay
                jsr     TxDelay
                jsr     TxDelay
;                jsr     TxDelay
;                jsr     TxDelay
                plp
                pla
                rts

TxDelay:        lda     #0
                inc     a
                bne     $-1
                rts
                endif

; Fetch the next character from the RX buffer waiting for some to arrive if the
; buffer is empty.

                public  UartRx
UartRx:
                if      USE_FIFO
                phx
                php
                short_ai
                lda     #$02                    ; Wait until data in buffer
RxWait:         bit     VIA2_IRB
                bne     RxWait

                lda     VIA2_IRB                ; Strobe /RD low
                ora     #$08
                tax
                and     #$f7
                sta     VIA2_ORB
                nop                             ; Wait for data to be available
                nop
                nop
                nop
                lda     VIA2_IRA                ; Read it
                stx     VIA2_ORB                ; And end the strobe
                plp
                plx
                rts                             ; Done

                else

                php
                short_a
RxWait:
                lda     ACIA_SR
                bpl     RxWait
                and     #$08
                beq     RxWait
                lda     ACIA_RXD
;                stz     ACIA_SR
                plp
                rts
                endif

                public  UartRxTest
UartRxTest:
                if      USE_FIFO
                pha
                php
                short_a
                lda     VIA2_IRB
                plp
                ror     a
                ror     a
                pla
                rts

                else

                pha                             ; Save callers A
                php
                short_a
                lda     ACIA_SR                 ; Read the status register
                plp
                ror     a                       ; Shift RDRF bit into carry
                ror     a
                ror     a
                ror     a
                pla                             ; Restore A
                rts                             ; Done
                endif

;==============================================================================
; Reset Vectors
;------------------------------------------------------------------------------

ShadowVectors   section offset $7ee0

                ds      4               ; Reserved
                dw      COP             ; $FFE4 - COP(816)
                dw      BRK             ; $FFE6 - BRK(816)
                dw      ABORT           ; $FFE8 - ABORT(816)
                dw      NMI             ; $FFEA - NMI(816)
                ds      2               ; Reserved
                dw      IRQ             ; $FFEE - IRQ(816)

                ds      4
                dw      COP             ; $FFF4 - COP(C02)
                ds      2               ; $Reserved
                dw      ABORT           ; $FFF8 - ABORT(C02)
                dw      NMIRQ           ; $FFFA - NMI(C02)
                dw      RESET           ; $FFFC - RESET(C02)
                dw      IRQBRK          ; $FFFE - IRQBRK(C02)

                ends

;------------------------------------------------------------------------------

Vectors         section offset $ffe0

                ds      4               ; Reserved
                dw      COP             ; $FFE4 - COP(816)
                dw      BRK             ; $FFE6 - BRK(816)
                dw      ABORT           ; $FFE8 - ABORT(816)
                dw      NMI             ; $FFEA - NMI(816)
                ds      2               ; Reserved
                dw      IRQ             ; $FFEE - IRQ(816)

                ds      4
                dw      COP             ; $FFF4 - COP(C02)
                ds      2               ; $Reserved
                dw      ABORT           ; $FFF8 - ABORT(C02)
                dw      NMIRQ           ; $FFFA - NMI(C02)
                dw      RESET           ; $FFFC - RESET(C02)
                dw      IRQBRK          ; $FFFE - IRQBRK(C02)

                ends

                end
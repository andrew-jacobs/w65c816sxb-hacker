;==============================================================================
; __        ____  ____   ____ ___  _  __  ______  ______
; \ \      / / /_| ___| / ___( _ )/ |/ /_/ ___\ \/ / __ )
;  \ \ /\ / / '_ \___ \| |   / _ \| | '_ \___ \\  /|  _ \
;   \ V  V /| (_) |__) | |__| (_) | | (_) |__) /  \| |_) |
;    \_/\_/  \___/____/ \____\___/|_|\___/____/_/\_\____/
;
; Western Design Center W65C816SXB Development Board Hardware Definitions
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
; All of the current stock of W65C51 ACIAs have a silicon bug that causes the
; 'Transmit Data Register Empty' (TDRE) bit in the status register to be stuck
; high making it impossible to tell when the transmitter is ready for the next
; data byte.
;
;------------------------------------------------------------------------------

OSC_FREQ        equ     8000000                 ; SXB runs at 8MHz

;==============================================================================
; W65C51 ACIA
;------------------------------------------------------------------------------

ACIA_RXD        equ     $7f80
ACIA_TXD        equ     $7f80
ACIA_SR         equ     $7f81
ACIA_CMD        equ     $7f82
ACIA_CTL        equ     $7f83

;==============================================================================
; W65C21 PIA
;------------------------------------------------------------------------------

PIA_PIA         equ     $7fa0
PIA_DDRA        equ     $7fa0
PIA_CRA         equ     $7fa1
PIA_PIB         equ     $7fa2
PIA_DDRB        equ     $7fa2
PIA_CRB         equ     $7fa3

;==============================================================================
; W65C22 VIA
;------------------------------------------------------------------------------

VIA1_ORB        equ     $7fc0
VIA1_IRB        equ     $7fc0
VIA1_ORA        equ     $7fc1
VIA1_IRA        equ     $7fc1
VIA1_DDRB       equ     $7fc2
VIA1_DDRA       equ     $7fc3
VIA1_T1CL       equ     $7fc4
VIA1_T1CH       equ     $7fc5
VIA1_T1LL       equ     $7fc6
VIA1_T1LH       equ     $7fc7
VIA1_T2CL       equ     $7fc8
VIA1_T2CH       equ     $7fc9
VIA1_SR         equ     $7fca
VIA1_ACR        equ     $7fcb
VIA1_PCR        equ     $7fcc
VIA1_IFR        equ     $7fcd
VIA1_IER        equ     $7fce
VIA1_ORAN       equ     $7fcf
VIA1_IRAN       equ     $7fcf

;------------------------------------------------------------------------------

VIA2_ORB        equ     $7fe0
VIA2_IRB        equ     $7fe0
VIA2_ORA        equ     $7fe1
VIA2_IRA        equ     $7fe1
VIA2_DDRB       equ     $7fe2
VIA2_DDRA       equ     $7fe3
VIA2_T1CL       equ     $7fe4
VIA2_T1CH       equ     $7fe5
VIA2_T1LL       equ     $7fe6
VIA2_T1LH       equ     $7fe7
VIA2_T2CL       equ     $7fe8
VIA2_T2CH       equ     $7fe9
VIA2_SR         equ     $7fea
VIA2_ACR        equ     $7feb
VIA2_PCR        equ     $7fec
VIA2_IFR        equ     $7fed
VIA2_IER        equ     $7fee
VIA2_ORAN       equ     $7fef
VIA2_IRAN       equ     $7fef

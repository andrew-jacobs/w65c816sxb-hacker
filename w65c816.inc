;==============================================================================
; __        ____  ____   ____ ___  _  __   
; \ \      / / /_| ___| / ___( _ )/ |/ /_  
;  \ \ /\ / / '_ \___ \| |   / _ \| | '_ \ 
;   \ V  V /| (_) |__) | |__| (_) | | (_) |
;    \_/\_/  \___/____/ \____\___/|_|\___/ 
;
; Western Design Center W65C816 device definitions                                          
;------------------------------------------------------------------------------


;==============================================================================
; Status Register Bits
;------------------------------------------------------------------------------

N_FLAG          equ     7
V_FLAG          equ     6
M_FLAG          equ     5
X_FLAG          equ     4
B_FLAG          equ     4
D_FLAG          equ     3
I_FLAG          equ     2
Z_FLAG          equ     1
C_FLAG          equ     0

;==============================================================================
; Macros
;------------------------------------------------------------------------------

; Puts the processor in emulation mode. A, X and Y become 8-bits and the stack
; is fixed at $0100-$01ff. 

emulate         macro
                sec
                xce
                endm

; Puts the processor in native mode. The size of the memory and index register
; operations is not controlled by the M & X bits in the status register.

native          macro
                clc
                xce
                endm

; Resets the M bit making the accumulator and memory accesses 16-bits wide.
 
long_a          macro
                rep     #(1<<M_FLAG)
                longa   on
                endm

; Resets the X bit making the index registers 16-bits wide

long_i          macro
                rep     #(1<<X_FLAG)
                longi   on
                endm

; Resets the M and X bits making the accumulator, memory accesses and index
; registers 16-bits wide.
                
long_ai         macro
                rep     #(1<<M_FLAG)|(1<<X_FLAG)
                longa   on
                longi   on
                endm

; Sets the M bit making the accumulator and memory accesses 8-bits wide.

short_a         macro
                sep     #(1<<M_FLAG)
                longa   off
                endm

; Sets the X bit making the index registers 8-bits wide.

short_i         macro
                sep     #(1<<X_FLAG)
                longi   off
                endm
                
; Sets the M & X bits making the accumulator, memory accesses and index
; registers 8-bits wide.

short_ai        macro
                sep     #(1<<M_FLAG)|(1<<X_FLAG)
                longa   off
                longi   off
                endm

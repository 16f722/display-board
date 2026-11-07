; [8/8/19]
; MDS Spring 2017
Parse    ; @@@nn[.n]nnk
    MovF    RCData, w       ; Clears RCIF
    AddwF   Parse_sum, F
    IncF    Parse_State, F
    MovF    Parse_State, w
    Andlw   0x0F
    AddwF   PC, F
    Goto    :reset     ; Invalid State
    Goto    :at        ; @@@
    Goto    :at
    Goto    :at
    Goto    :addr      ; [aa]
    Goto    :char
    Goto    :char
    Goto    :char_et
    Goto    :char      ; char_mph
    Goto    :char
    Goto    :char
    Goto    :check_sum
    Goto    :reset     ; Invalid State
    Goto    :reset
    Goto    :reset
    Goto    :reset

:reset
    ClrF    Parse_State
    ClrF    Parse_Sum    ; '@@@'=-192
    BCF     Control, Parse_ET
    Movlw   Prse_Buffer
    MovwF   Parse_FSR
    Return

:at
    MovF    RCData, w
    Xorlw   '@'
    BTFSS   Status, z
    Goto    :reset
    Return

:addr
    MovF    RCData, w
    XorwF   Portx, w    ; Cmp to DIP-SW setting
    Andlw   0x0F
    BTFSS   Status, z
    Goto    :reset
    Return

:char_et
    MovF    RCData,w
    Xorlw   '.'
    BTFSS   Status, z
    Goto    :char
    BSF     Control, Parse_ET
    Return

:char
;    MovF    Parse_FSR, w
;    MovwF   FSR

:char_period_drop
    MovF    RCData, w
    Xorlw   '.'
    BTFSS   Status, z
    Goto    :char_inc
    Return  ; discard

:char_inc
    MovF    Parse_FSR, w
    MovwF   FSR
    IncF    Parse_FSR, F

:char_sp
    MovF    RCData, w
    Xorlw   ' '
    BTFSS   Status, z
    Goto    :char_minus
    Movlw   00000000b
    MovwF   IDF
    Return

:char_minus
    MovF    RCData, w
    Xorlw   '-'
    BTFSS   Status, z
    Goto    :char_L
    Movlw   01000000b
    MovwF   IDF
    Return

:char_L
    MovF    RCData, w
    Xorlw   'L'
    BTFSS   Status, z
    Goto    :char_hex
    Movlw   00111000b
    MovwF   IDF
    Return

:char_hex
    MovF    RCData, w
    Addlw   -58         ; -10/7..-1/12
    BTFSS   Status, c   ; >0x39
    Addlw   7           ; 0x30..0x39 -> 0..9, 0x41-0x46 -> A..F
    Addlw   3           ; 0..15
    Call    :segment_table
    MovwF   IDF
    Return

:segment_table
    Andlw    0x0F
    AddwF    PC, F
    Retlw    00111111b ; 0    gfedcba
    Retlw    00000110b ; 1       a
    Retlw    01011011b ; 2     f   b
    Retlw    01001111b ; 3       g
    Retlw    01100110b ; 4     e   c
    Retlw    01101101b ; 5       d
    Retlw    01111101b ; 6
    Retlw    00000111b ; 7
    Retlw    01111111b ; 8
    Retlw    01100111b ; 9
    Retlw    01110111b ; A
    Retlw    01111100b ; b
    Retlw    00111001b ; C
    Retlw    01011110b ; d
    Retlw    01111001b ; E
    Retlw    01110001b ; F

:check_sum
    MovF    Parse_Sum, F
    MovF    RCData, w
    SubwF   Parse_Sum, F
    SubwF   Parse_sum, F
    BTFSS   Status, z
    Goto    :reset
    BTFSC   Control, Parse_ET
    Goto    :copy_et
    Goto    :copy_mph
    

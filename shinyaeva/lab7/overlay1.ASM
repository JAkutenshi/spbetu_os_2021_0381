code    segment
assume  CS:code

main    proc far
        push    AX
        push    DX
        push    DS
        push    SI
        mov     DX, CS
        mov     DS, DX
        mov     SI, offset str
        add     SI, 22
        call    reg2hex
        mov     DX, offset str
        mov     AH, 09h
        int     21h
        pop     SI
        pop     DS
        pop     DX
        pop     AX
        retf
main    endp

reg2hex proc
        push    AX
        push    BX
        push    CX
        push    DX
        mov     BX, 0F000h
        mov     DL, 12
        mov     CX, 4
nloop:  push    CX
        push    AX
        and     AX, BX
        mov     CL, DL
        shr     AX, CL
        cmp     AL, 9
        ja      lttr
        add     AL, 30h
        jmp     ok
lttr:   add     AL, 37h
ok:     mov     byte ptr [SI], AL
        inc     SI
        pop     AX
        mov     CL, 4
        shr     BX, CL
        sub     DL, 4
        pop     CX
        loop    nloop
        pop     DX
        pop     CX
        pop     BX
        pop     AX
        ret
reg2hex endp

str     db 'OVERLAY1.OVL address: 0000h', 0Ah, 0Dh, '$'

code    ends

        end     main
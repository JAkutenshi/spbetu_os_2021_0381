stack   segment stack
        db 256 dup (?)
stack   ends

data    segment
flag    db 0

ls     db 'Interrupt loaded successfully$'              ;успешно загружено
us     db 'Interrupt unloaded successfully$'            ;успешно выгружено
ial    db 'Interrupt already loaded$'
iau    db 'Interrupt already unloaded$'

data    ends

code    segment
assume  CS:code, DS:data

inter   proc far
        jmp ibegin
PSP     dw ?
keepIP  dw 0
keepCS  dw 0
ID      dw 0FFFFh
keepSS  dw ?
keepSP  dw ?
keepAX  dw ?
vector  dd 0
istk    dw 32 dup (?)
istkend dw ?
; --- Begin of the resident program ---
ibegin: mov     keepSS, SS
        mov     keepSP, SP
        mov     keepAX, AX
        mov     AX, CS
        mov     SS, AX
        mov     SP, offset istkend
        push    BX
        push    CX
        push    DX
        push    DS
        push    ES
        push    SI
        push    DI
        push    BP
; --- Getting the scan code ---
        in      AL, 60h
        cmp     AL, 02h
        jl      stdrt
        cmp     AL, 0Bh
        jle     doreq
stdrt:  mov     AX, keepIP
        mov     word ptr vector, AX
        mov     AX, keepCS
        mov     word ptr vector + 2, AX
        pop     BP
        pop     DI
        pop     SI
        pop     ES
        pop     DS
        pop     DX
        pop     CX
        pop     BX
        mov     AX, keepSS
        mov     SS, AX
        mov     AX, keepAX
        mov     SP, keepSP
        jmp     CS:[vector]
doreq:  push    AX
        in      AL, 61h
        mov     AH, AL
        or      AL, 80h
        out     61h, AL
        xchg    AH, AL
        out     61h, AL
        mov     AL, 20h
        out     20h, AL
; --- The processing ---
        pop     AX
        xor     CX, CX
        mov     CL, AL
        add     CL, 2Eh
write:  mov     AH, 05h
        mov     CH, 00h
        int     16h
        or      AL, AL
        jnz     skip
        jmp     ifin
skip:   mov     AH, 0Ch
        mov     AL, 0
        int     21h
        jmp     write
; --- End of the resident program ---
ifin:   pop     BP
        pop     DI
        pop     SI
        pop     ES
        pop     DS
        pop     DX
        pop     CX
        pop     BX
        mov     AX, keepSS
        mov     SS, AX
        mov     AX, keepAX
        mov     SP, keepSP
        iret
iend:
inter   endp 

load    proc
        push    AX
        push    CX
        push    DX
; --- Storing offset and segment ---
        mov     AH, 35h
        mov     AL, 09h
        int     21h
        mov     keepIP, BX
        mov     keepCS, ES
; --- Interrupt setting ---
        push    DS
        mov     DX, offset inter
        mov     AX, seg inter
        mov     DS, AX
        mov     AH, 25h
        mov     AL, 09h
        int     21h
        pop     DS
; --- Resident program preservation ---
        mov     DX, offset iend
        mov     CL, 4
        shr     DX, CL
        inc     DX
        mov     AX, CS
        sub     AX, PSP
        add     DX, AX
        xor     AX, AX
        mov     AH, 31h
        int     21h
        pop     DX
        pop     CX
        pop     AX
        ret
load    endp

unload  proc
        push    AX
        push    DX
        push    SI
        push    ES
; --- Recovery offset and segment ---
        cli
        push    DS
        mov     AH, 35h
        mov     AL, 09h
        int     21h
        mov     SI, offset keepIP
        sub     SI, offset inter
        mov     DX, ES:[BX+SI]
        mov     AX, ES:[BX+SI+2]
        mov     DS, AX
        mov     AH, 25h
        mov     AL, 09h
        int     21h
        pop     DS
        mov     AX, ES:[BX+SI-2]
        mov     ES, AX
        push    ES
        mov     AX, ES:[2Ch]
        mov     ES, AX
        mov     AH, 49h
        int     21h
        pop     ES
        mov     AH, 49h
        int     21h
        sti
        pop     ES
        pop     SI
        pop     DX
        pop     AX
        ret
unload  endp

isParam proc
        push    AX
        mov     AL, ES:[82h]
        cmp     AL, '/'
        jne     nparam
        mov     AL, ES:[83h]
        cmp     AL, 'u'
        jne     nparam
        mov     AL, ES:[84h]
        cmp     AL, 'n'
        jne     nparam
        mov     flag, 1
nparam: pop     AX
        ret
isParam endp

isLoad  proc
        push    AX
        push    DX
        push    SI
        mov     flag, 1
        mov     AH, 35h
        mov     AL, 09h
        int     21h
        mov     SI, offset ID
        sub     SI, offset inter
        mov     DX, ES:[BX+SI]
        cmp     DX, 0FFFFh
        je      ld
        mov     flag, 0
ld:     pop     SI
        pop     DX
        pop     AX
        ret
isLoad  endp

print   proc
        push    AX
        mov     AH, 09h
        int     21h
        pop     AX
        ret
print   endp

main    proc far
        mov     AX, data
        mov     DS, AX
        mov     PSP, ES
        mov     flag, 0
        call    isParam
        cmp     flag, 1
        je      un
; --- Loading ---
        call    isLoad
        cmp     flag, 0
        je      notld
        mov     DX, offset ial
        call    print
        jmp     fin
notld:  mov     DX, offset ls
        call    print
        call    load
        jmp     fin
; --- Unloading ---
un:     call    isLoad
        cmp     flag, 0
        jne     alrld
        mov     DX, offset iau 
        call    print
        jmp     fin
alrld:  call    unload
        mov     DX, offset us
        call    print
; --- End ---
fin:    mov     AX, 4C00h
        int     21h
main    endp
code    ends
        end     main
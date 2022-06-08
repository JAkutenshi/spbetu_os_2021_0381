; Шаблон текста программы на ассемблере для модуля типа .COM
TESTPC     SEGMENT
           ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
           ORG     100H
START:     JMP     BEGIN
; ДАННЫЕ
LOCKED_MEM_ADRESS db 'Locked memory address:     h',13,10,'$'
ENV_ADRESS db 'Environment address:     h',13,10,'$'
TAIL db 'Comand line tail:        ',13,10,'$'
EMPTY_TAIL db 'There is no symbols in the command line tail',13,10,'$'
CONTENT db 'Content:',13,10, '$'
END_STRING db 13, 10, '$'
PATH db 'Path:  ',13,10,'$'
;ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX   PROC  near
; байт в AL переводится в два символа шестн. числа в AX
           push     CX
           mov      AH,AL
           call     TETR_TO_HEX
           xchg     AL,AH
           mov      CL,4
           shr      AL,CL
           call     TETR_TO_HEX ;в AL старшая цифра
           pop      CX          ;в AH младшая
           ret
BYTE_TO_HEX  ENDP
;-------------------------------
WRD_TO_HEX   PROC  near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
           push     BX
           mov      BH,AH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           dec      DI
           mov      AL,BH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           pop      BX
           ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC   PROC  near
; перевод в 10с/с, SI - адрес поля младшей цифры
   push CX
   push DX
   xor AH,AH
   xor DX,DX
   mov CX,10
loop_bd:
   div CX
   or DL,30h
   mov [SI],DL
   dec SI
   xor DX,DX
   cmp AX,10
   jae loop_bd
   cmp AL,00h
   je end_l
   or AL,30h
   mov [SI],AL
end_l:
   pop DX
   pop CX
   ret
BYTE_TO_DEC    ENDP
;-------------------------------
WRITESTRING PROC near
   mov AH,09h
   int 21h
   ret
WRITESTRING ENDP
;-------------------------------
GET_LOCKED_MEMORY PROC near
    mov ax, ds:[02h]
    mov di, offset LOCKED_MEM_ADRESS
    add di, 26
    call WRD_TO_HEX
    mov dx, offset LOCKED_MEM_ADRESS
    call WRITESTRING
    ret
GET_LOCKED_MEMORY ENDP
;-------------------------------
GET_ENVIRONMENT_ADRESS PROC near
    mov ax, ds:[2Ch]
    mov di, offset ENV_ADRESS
    add di, 24
    call WRD_TO_HEX
    mov dx, offset ENV_ADRESS
    call WRITESTRING
    ret
GET_ENVIRONMENT_ADRESS ENDP
;-------------------------------
GET_COMMANDLINE_TAIL PROC near
    xor cx, cx
    mov cl, ds:[80h]
    mov si, offset TAIL
    add si, 19
    cmp cl, 0h
    je ifEmpty
    xor di, di
    xor ax, ax
    readContentOfTail:
        mov al, ds:[81h+di]
        inc di
        mov [si], al
        inc si
        loop readContentOfTail
        mov dx, offset TAIL
        jmp printing
    ifEmpty:
        mov dx, offset EMPTY_TAIL
    printing:
        call WRITESTRING
        ret
GET_COMMANDLINE_TAIL ENDP
;-------------------------------
GET_ENVIRONMENT_CONTENT_AND_PATH PROC near
    mov dx, offset CONTENT
    call WRITESTRING
    xor di, di
    mov ds, ds:[2Ch]
    reading:
        cmp byte ptr [di], 00h
        jz end_of_string
        mov dl, [di]
        mov ah, 02h
        int 21h
        jmp finding_end
    end_of_string:
        cmp byte ptr [di+1], 00h
        jz finding_end
        push ds
        mov cx, cs
        mov ds, cx
        mov dx, offset END_STRING
        call WRITESTRING
        pop ds
    finding_end:
        inc di
        cmp word ptr [di], 001h
        jz read_PATH
        jmp reading
    read_PATH:
        push ds
        mov ax, cs
        mov ds, ax
        mov dx, offset PATH
        call WRITESTRING
        pop ds
        add di, 2
    loop_for_path:
        cmp byte ptr [di], 00h
        jz end_of_proc
        mov dl, [di]
        mov ah, 02h
        int 21h
        inc di
        jmp loop_for_path
    end_of_proc:
        ret
GET_ENVIRONMENT_CONTENT_AND_PATH ENDP
;-------------------------------
; КОД

BEGIN:
;........... .
        call GET_LOCKED_MEMORY
        call GET_ENVIRONMENT_ADRESS
        call GET_COMMANDLINE_TAIL
        call GET_ENVIRONMENT_CONTENT_AND_PATH
;........... . ; Выход в DOS
           xor     AL,AL
           mov     AH,4Ch
           int     21H
TESTPC     ENDS
           END     START
;конец модуля, START - точка входа
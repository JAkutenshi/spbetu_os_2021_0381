STK SEGMENT STACK
   DB 128 DUP (0) ;выделяем память
STK ENDS

DATA SEGMENT
; Данные
T_PC db  'Type: PC',0DH,0AH,'$'
T_PC_XT db 'Type: PC/XT',0DH,0AH,'$'
T_AT db  'Type: AT',0DH,0AH,'$'
T_PS2_M30 db 'Type: PS2 модель 30',0DH,0AH,'$'
T_PS2_M50_60 db 'Type: PS2 модель 50 или 60',0DH,0AH,'$'
T_PS2_M80 db 'Type: PS2 модель 80',0DH,0AH,'$'
T_PС_JR db 'Type: PСjr',0DH,0AH,'$'
T_PC_C db 'Type: PC Convertible',0DH,0AH,'$'

VERSION db 'Version:  .  ',0DH,0AH,'$'
OEM db  'OEM:  ',0DH,0AH,'$'
USER db  'User:        $'

DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE, DS:DATA 
START: JMP BEGIN      ;точка входа (метка)

; Процедуры
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
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
    push CX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX ;в AL старшая цифра
    pop CX ;в AH младшая
    ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
    push BX
    mov BH,AH
    call BYTE_TO_HEX
    mov [DI],AH
    dec DI
    mov [DI],AL
    dec DI
    mov AL,BH
    call BYTE_TO_HEX
    mov [DI],AH
    dec DI
    mov [DI],AL
    pop BX
    ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
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
BYTE_TO_DEC ENDP
;-------------------------------
PC_TYPE PROC near
    mov ax, 0f000h       ;получаем номер модели 
    mov es, ax
    mov al, es:[0fffeh]  ;смещение

    cmp al, 0ffh         ;сравниваем
    je pc
    cmp al, 0feh
    je pc_xt
    cmp al, 0fbh
    je pc_xt
    cmp al, 0fch
    je pc_at
    cmp al, 0fah
    je pc_ps2_m30
    cmp al, 0f8h
    je pc_ps2_m80
    cmp al, 0fdh
    je pc_jr 
    cmp al, 0f9h
    je pc_conv
pc:
    mov dx, offset T_PC
    jmp write
pc_xt:
    mov dx, offset T_PC_XT
    jmp write
pc_at:
    mov dx, offset T_AT
    jmp write
pc_ps2_m30:
    mov dx, offset T_PS2_M30
    jmp write
pc_ps2_m50_60:
    mov dx, offset T_PS2_M50_60
    jmp write
pc_ps2_m80:
    mov dx, offset T_PS2_M80
    jmp write
pc_jr:
    mov dx, offset T_PС_JR
    jmp write
pc_conv:
    mov dx, offset T_PC_C
    jmp write
write:
    mov AH,09h
    int 21h
    ret
PC_TYPE ENDP

OS PROC near
    ;версия
    mov ah, 30h
    int 21h
    push ax
    mov si, offset VERSION
    add si, 9       ;смещение
    call BYTE_TO_DEC
    pop ax
    mov al, ah
    add si, 3       ;смещение
    call BYTE_TO_DEC
    mov dx, offset VERSION
    mov AH,09h      ;вывод
    int 21h
	
    ;серийный номер OEM
    mov si, offset OEM
    add si, 5      ;смещение 
    mov al, bh
    call BYTE_TO_DEC
    mov dx, offset OEM
    mov AH,09h     ;вывод
    int 21h
	
    ;серийный номер пользователя
    mov di, offset USER
    add di, 11     ;смещение
    mov ax, cx
    call WRD_TO_HEX
    mov al, bl
    call BYTE_TO_HEX
    sub di, 2
    mov [di], ax
    mov dx, offset USER
    mov AH,09h     ;вывод
    int 21h
    ret

OS ENDP

; Код
BEGIN:
    mov AX, DATA
    mov DS, AX
   call PC_TYPE
   call OS

   xor AL,AL
   mov AH,4Ch
   int 21H
CODE ENDS
END START; конец модуля, START - точка выхода
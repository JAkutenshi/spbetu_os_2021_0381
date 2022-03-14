TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H
START: JMP BEGIN
;Данные
        PC_ db  'Type: PC',0DH,0AH,'$'
        PC_XT db 'Type: PC/XT',0DH,0AH,'$'
        PC_AT db  'Type: AT',0DH,0AH,'$'
        PC_PS2_M30 db 'Type: PS2 model 30',0DH,0AH,'$'
        PC_PS2_M50_60 db 'Type: PS2 model 50 or 60',0DH,0AH,'$'
        PC_PS2_M80 db 'Type: PS2 model 80',0DH,0AH,'$'
        PС_JR db 'Type: PСjr',0DH,0AH,'$'
        PC_CONV db 'Type: PC Convertible',0DH,0AH,'$'

        VERSION db 'Version MS-DOS:  .  ',0DH,0AH,'$'
        SERIAL_OEM db  'Serial number OEM:  ',0DH,0AH,'$'
        USER db  'User serial number:       H $'
;Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near
        and AL,0Fh
        cmp AL,09
        jbe NEXT
        add AL,07
NEXT:   
        add AL,30h
        ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; байт в AL переводится в два символа шестн. числа в AX
        push CX
        mov AH,AL
        call TETR_TO_HEX
        xchg AL,AH
        mov CL,4
        shr AL,CL
        call TETR_TO_HEX    ; в AL старшая цифра
        pop CX              ; в AH младшая
        ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
; перевод в 16-ю с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего числа
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
; перевод в 10-ю с/с, SI – адрес поля младшей цифры
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
WRITESTRING PROC near
        mov AH,09h
        int 21h
        ret
WRITESTRING ENDP

PC_TYPE PROC near
        mov ax, 0f000h ; получаем номер модели 
        mov es, ax
        mov al, es:[0fffeh]

        cmp al, 0ffh ; начинаем стравнивать
        je pc
        cmp al, 0feh
        je xt
        cmp al, 0fbh
        je xt
        cmp al, 0fch
        je at
        cmp al, 0fah
        je ps2_m30
        cmp al, 0f8h
        je ps2_m80
        cmp al, 0fdh
        je jr
        cmp al, 0f9h
        je conv
pc:
		mov dx, offset PC_
		jmp writetype
xt:
		mov dx, offset PC_XT
		jmp writetype
at:
		mov dx, offset PC_AT
		jmp writetype
ps2_m30:
		mov dx, offset PC_PS2_M30
		jmp writetype
ps2_m50_60:
		mov dx, offset PC_PS2_M50_60
		jmp writetype
ps2_m80:
		mov dx, offset PC_PS2_M80
		jmp writetype
jr:
		mov dx, offset PС_JR
		jmp writetype
conv:
		mov dx, offset PC_CONV
writetype:
		call WRITESTRING
	ret
PC_TYPE ENDP

OS_VER PROC near
        mov ah, 30h
        int 21h
        push ax
        
        mov si, offset VERSION
        add si, 16
        call BYTE_TO_DEC
        pop ax
        mov al, ah
        add si, 3
        call BYTE_TO_DEC
        mov dx, offset VERSION
        call WRITESTRING
        
        mov si, offset SERIAL_OEM
        add si, 19
        mov al, bh
        call BYTE_TO_DEC
        mov dx, offset SERIAL_OEM
        call WRITESTRING
        
        mov di, offset USER
        add di, 25
        mov ax, cx
        call WRD_TO_HEX
        mov al, bl
        call BYTE_TO_HEX
        sub di, 2
        mov [di], ax
        mov dx, offset USER
        call WRITESTRING
        ret
OS_VER ENDP

BEGIN:
        call PC_TYPE
        call OS_VER

        xor AL,AL
        mov AH,4Ch
        int 21H
TESTPC ENDS
END START
ASSUME CS:CODE, DS:DATA, SS:STACK

STACK SEGMENT STACK
	DW 16 DUP(?)
STACK ENDS	

DATA SEGMENT
	; ДАННЫЕ
	TYPE_PC db 'IBM PC type: PC',0DH,0AH,'$'
	TYPE_PC_XT db 'IBM PC type: PC/XT',0DH,0AH,'$'
	TYPE_AT db 'IBM PC type: AT',0DH,0AH,'$'
	TYPE_PS2_30 db 'IBM PC type: PS2 model 30',0DH,0AH,'$'
	TYPE_PS2_50_OR_60 db 'IBM PC type: PS2 model 50 or 60',0DH,0AH,'$'
	TYPE_PS2_80 db 'IBM PC type: PS2 model 80',0DH,0AH,'$'
	TYPE_PCJR db 'IBM PC type: PCjr',0DH,0AH,'$'
	TYPE_PC_CONVERTIBLE db 'IBM PC type: PC Convertible',0DH,0AH,'$'

	VERSION db 'MS-DOS version:  . ',0DH,0AH,'$'
	SERIAL_NUMBER db  'Serial number(OEM):  ',0DH,0AH,'$'
	USER_NUMBER db  'User serial number:      H $'
DATA ENDS

CODE SEGMENT
;ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
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
loop_bd: div CX
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
end_l: pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP
;-------------------------------
; КОД
; Вывод значений
OUTPUT PROC near
	mov AH, 09h
	int 21h
	ret
OUTPUT ENDP	
;---------------------------------------------------------
GET_PC_TYPE PROC near
	; Тип IBM PC хранится в байте по адресу 0F000:0FFFEh
	mov AX, 0f000h
	mov ES, AX
	mov AL, ES:[0fffeh]
	
	; Сравнение значения AL для получения нужного типа
	cmp AL, 0ffh
	je _type_pc
	
	cmp AL, 0feh
	je _type_pc_xt
	
	cmp AL, 0fbh
	je _type_pc_xt
	
	cmp AL, 0fch
	je _type_at
	
	cmp AL, 0fah
	je _type_ps2_30
	
	cmp AL, 0fch
	je _type_ps2_50_or_60
	
	cmp AL, 0f8h
	je _type_ps2_80
	
	cmp AL, 0fdh
	je _type_PCjr
	
	cmp AL, 0f9h
	je _type_pc_conv
	; Нет совпадений
	call BYTE_TO_HEX
	jmp result
	
_type_pc:
	mov dx, offset TYPE_PC
	jmp result
_type_pc_xt:
	mov dx, offset TYPE_PC_XT
	jmp result
_type_at:
	mov dx, offset TYPE_AT
	jmp result
_type_ps2_30:
	mov dx, offset TYPE_PS2_30
	jmp result
_type_ps2_50_or_60:
	mov dx, offset TYPE_PS2_50_OR_60
	jmp result
_type_ps2_80:
	mov dx, offset TYPE_PS2_80
	jmp result
_type_PCjr:
	mov dx, offset TYPE_PCJR
	jmp result
_type_pc_conv:
	mov dx, offset TYPE_PC_CONVERTIBLE
	jmp result
result:
	call OUTPUT
	ret
GET_PC_TYPE ENDP	
;--------------------------------------------
GET_OS_VERSION PROC near
	; Определение версии MS DOS
	mov AH, 30h
	int 21h
	
    mov si, offset VERSION
	add si, 16
	call BYTE_TO_DEC
    mov al, ah
    add si, 3
	call BYTE_TO_DEC
	mov dx, offset VERSION
	call OUTPUT
	; BH - серийный номер OEM
	mov si, offset SERIAL_NUMBER
	add si, 20
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset SERIAL_NUMBER
	call OUTPUT
	; BL:CX - 24-битовый серийный номер пользователя
	mov di, offset USER_NUMBER
	add di, 23
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	mov dx, offset USER_NUMBER
	call OUTPUT
	ret
GET_OS_VERSION ENDP	
;--------------------------------------------	
Main PROC FAR
	push DS
	sub AX, AX
	mov AX, DATA
	mov DS, AX
	
	call GET_PC_TYPE
	call GET_OS_VERSION
 
; Выход в DOS
	xor AL,AL
	mov AH,4Ch
	int 21H
Main ENDP
CODE ENDS
END Main
	;END START ;конец модуля, START - точка входа
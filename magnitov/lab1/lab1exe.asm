;Модуль типа .EXE
AStack SEGMENT STACK

DW 512 DUP(?)

AStack ENDS


DATA SEGMENT

;Строки для вывода PC
PC db 'Type of PC: PC', 0DH, 0AH, '$'
PC_XT db 'Type of PC: PC/XT', 0DH, 0AH, '$'
TYPE_AT db 'Type of PC: AT or PS2 - 50 or 60', 0DH, 0AH, '$'
PS2_30 db 'Type of PC: PS2 - 30', 0DH, 0AH, '$'
PS2_80 db 'Type of PC: PS2 - 80', 0DH, 0AH, '$'
PC_JR db 'Type of PC: PCjr', 0DH, 0AH, '$'
PC_CONVERTIBLE db 'Type of PC: PC Convertable', 0DH, 0AH, '$'
ANOTHER db 'UNKNOWN CODE: XXh', 0DH, 0AH, '$'
SYSTEM_VERSION db 'System version:   .', 0DH, 0AH, '$'
OEM db 'OEM:  ', 0DH, 0AH, '$'
USER db 'User:       h', 0DH, 0AH, '$'

DATA ENDS


CODE SEGMENT 
ASSUME CS:CODE, DS:DATA, SS:AStack
;Процедуры

;-------------------------------
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

;-------------------------------
BYTE_TO_HEX PROC near
;Байт в AL переводится в два символа шестн. числа в AX
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

;-------------------------------
WRD_TO_HEX PROC near
;Перевод в 16 с/с 16-ти разрядного числа
;В AX - число, DI - адрес последнего символа
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
;-------------------------------

;-------------------------------
BYTE_TO_DEC PROC near
;Перевод в 10с/с, SI - адрес поля младшей цифры
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

;-------------------------------
PRINT PROC near
	mov AH, 09h
	int 21h
	ret
PRINT ENDP
;-------------------------------

;-------------------------------
TYPE_PC PROC near
	mov AX, 0f000h
	mov ES, AX
	mov AL, ES:[0fffeh] 
	
	cmp AL, 0ffh
	je m_PC
	
	cmp AL, 0feh
	je m_PC_XT
	
	cmp AL, 0fbh
	je m_PC_XT
	
	cmp AL, 0fch
	je m_TYPE_AT
	
	cmp AL, 0fah
	je m_PS2_30
	
	cmp AL, 0f8h
	je m_PS2_80
	
	cmp AL, 0fdh
	je m_PC_JR
	
	cmp AL, 0f9h
	je m_PC_CONVERTIBLE
	
	call BYTE_TO_HEX
	mov BX, OFFSET ANOTHER
	mov [BX+14], AX
	mov DX, OFFSET ANOTHER
	jmp m_print

	
m_PC:
	mov DX, OFFSET PC
	jmp m_print


m_PC_XT:
	mov DX, OFFSET PC_XT
	jmp m_print


m_TYPE_AT:
	mov DX, OFFSET TYPE_AT
	jmp m_print
	

m_PS2_30:
	mov DX, OFFSET PS2_30
	jmp m_print


m_PS2_80:
	mov DX, OFFSET PS2_80
	jmp m_print


m_PC_JR:
	mov DX, OFFSET PC_JR
	jmp m_print


m_PC_CONVERTIBLE:
	mov DX, OFFSET PC_CONVERTIBLE
	jmp m_print
	

m_print:
	call PRINT
	ret

TYPE_PC ENDP
;-------------------------------

;-------------------------------
VERSION PROC near
	mov AH, 30h
	int 21h
	
	push AX
	mov SI, OFFSET SYSTEM_VERSION
	add SI, 17
	call BYTE_TO_DEC
	pop AX
	
	mov AL, AH
	add SI, 3
	call BYTE_TO_DEC
	mov DX, OFFSET SYSTEM_VERSION
	call PRINT
	
	mov SI, OFFSET OEM
	add SI, 5
	mov AL, BH
	call BYTE_TO_DEC
	mov DX, OFFSET OEM
	call PRINT
	
	mov DI, OFFSET USER
	add DI, 11
	mov AX, CX
	call WRD_TO_HEX
	mov AL, BL
	call BYTE_TO_HEX
	mov [DI-2], AX
	mov DX, OFFSET USER
	call PRINT
	ret
	
VERSION ENDP
;-------------------------------


MAIN PROC far
	sub AX, AX
	push AX
	mov AX, DATA
	mov DS, AX
	
	call TYPE_PC
	call VERSION

xor AL,AL
mov AH,4Ch
int 21H
MAIN ENDP
CODE ENDS
END MAIN 
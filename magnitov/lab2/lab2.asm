LAB SEGMENT
ASSUME CS:LAB, DS:LAB, ES:NOTHING, SS:NOTHING
ORG 100H

START: JMP BEGIN

;Данные
;Строки для вывода сообщений
AD_MEMORY db 'Segment address of unavailable memory:     h', 0DH, 0AH, '$'
AD_ENVIRONMENT db 'Segment address of the environment:     h', 0DH, 0AH, '$'
TAIL db 'Command line tail: ', 0DH, 0AH, '$'
EMPTY_TAIL db 'Empty tail', 0DH, 0AH, '$'
ENV_AREA db 'Contents of the environment area: ', 0DH, 0AH, '$'
PATH db 'The path of the loaded module: ', 0DH, 0AH, '$'
WRITELN db ' ', 0DH, 0AH, '$'


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
PRINT_ONE PROC near
	mov AH, 02H
	int 21h
	ret
PRINT_ONE ENDP
;-------------------------------

;-------------------------------
UNAVAILABLE_MEMORY PROC near
	mov AX, ES:[2h]
	mov DI, OFFSET AD_MEMORY
	add DI, 42
	call WRD_TO_HEX
	mov DX, OFFSET AD_MEMORY
	call PRINT
	ret
UNAVAILABLE_MEMORY ENDP
;-------------------------------

;-------------------------------
ENVIRONMENT PROC near
	mov AX, DS:[2Ch]
	mov DI, OFFSET AD_ENVIRONMENT
	add DI, 39
	call WRD_TO_HEX
	mov DX, OFFSET AD_ENVIRONMENT
	call PRINT
	ret
ENVIRONMENT ENDP
;-------------------------------

;-------------------------------
CL_TAIL PROC near
	mov CX, 0
	mov CL, ES:[80h]
	cmp CX, 0
	je m_empty
	
	mov DX, OFFSET TAIL
	call PRINT
	
	mov DX, 0
	mov BX, 81h

m_read:
	mov DL, ES:[BX]
	inc BX
	mov AH, 02h
	int 21h
	loop m_read
	mov DX, OFFSET WRITELN
	call PRINT
	jmp m_end

m_empty:
	mov DX, OFFSET EMPTY_TAIL
	call PRINT

m_end:
	ret
CL_TAIL ENDP
;-------------------------------

;-------------------------------
CONT_ENVIRONMENT PROC near
	mov DX, OFFSET ENV_AREA
	call PRINT
	
	mov ES, DS:[2Ch]
	mov DI, 0

m_check:
	mov DL, ES:[DI]
	cmp DL, 0
	jne m_print
	mov DX, OFFSET WRITELN
	call PRINT
	inc DI
	mov DL, ES:[DI]
	cmp DL, 0
	je m_end_cont

m_print:	
	call PRINT_ONE
	inc DI
	jmp m_check
	
m_end_cont:
	add DI, 3
	mov DX, OFFSET PATH
	call PRINT

m_print_path:	
	mov DL, ES:[DI]
	cmp DL, 0
	je m_end_all
	call PRINT_ONE
	inc DI
	jmp m_print_path

m_end_all:
	ret
CONT_ENVIRONMENT ENDP
;-------------------------------


; КОД
BEGIN:
	call UNAVAILABLE_MEMORY
	call ENVIRONMENT
	call CL_TAIL
	call CONT_ENVIRONMENT

; Выход в DOS
xor AL,AL
mov AH,4Ch
int 21H
LAB ENDS
END START ;конец модуля, START - точка входа
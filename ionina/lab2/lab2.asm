; Шаблон текста программы на ассемблере для модуля типа .COM
LAB2 	SEGMENT
	ASSUME CS:LAB2, DS:LAB2, ES:NOTHING, SS:NOTHING
	ORG 100H

START: JMP BEGIN

;Данные
;Строки для вывода сообщений
INVALID_MEMORY db 'Segment address of unavailable memory:     h', 0DH, 0AH, '$'
ENVIRONMENT db 'Segment address of the environment:     h', 0DH, 0AH, '$'
TAIL db 'Command Line Tail: ', 0DH, 0AH, '$'
EMPTY_TAIL db 'Empty tail', 0DH, 0AH, '$'
AREA db 'Contents of the environment area: ', 0DH, 0AH, '$'
PATH db 'Path of the loaded module: ', 0DH, 0AH, '$'
WRITE_NEW db ' ', 0DH, 0AH, '$'


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




WRITE PROC near
	mov AH, 09h
	int 21h
	ret
WRITE ENDP


WRITE1 PROC near
	mov AH, 02H
	int 21h
WRITE1 ENDP
;-------------------------------



MEMORY_INVALID_ADRESS PROC near
	mov AX, ES:[2h]
	lea DI, INVALID_MEMORY
	add DI, 42
	call WRD_TO_HEX
	lea DX, INVALID_MEMORY
	call WRITE
	ret
MEMORY_INVALID_ADRESS ENDP


ENVIRONMENT_ADRESS PROC near
	mov AX, DS:[2Ch]
	lea DI, ENVIRONMENT
	add DI, 39
	call WRD_TO_HEX
	lea DX, ENVIRONMENT
	call WRITE
	ret
ENVIRONMENT_ADRESS ENDP


LINE_TAIL PROC near
	mov CX, 0
	mov CL, ES:[80h]
	cmp CX, 0
	je empty
	
	lea DX, TAIL
	call WRITE
	
	mov DX, 0
	mov BX, 81h

read_this:
	mov DL, ES:[BX]
	inc BX
	mov AH, 02h
	int 21h
	loop read_this
	lea DX, WRITE_NEW
	call WRITE
	jmp endl

empty:
	lea DX, EMPTY_TAIL
	call WRITE

endl:
	ret
LINE_TAIL ENDP


ENVIRONMENT_CONTENT PROC near
	lea DX, AREA
	call WRITE
	
	mov ES, DS:[2Ch]
	mov DI, 0

this:
	mov DL, ES:[DI]
	cmp DL, 0
	jne print
	lea DX, WRITE_NEW
	call WRITE
	inc DI
	mov DL, ES:[DI]
	cmp DL, 0
	je end1

print:	
	call WRITE1
	inc DI
	jmp this
	
end1:
	add DI, 3
	lea DX, PATH
	call WRITE

print_p:	
	mov DL, ES:[DI]
	cmp DL, 0
	je end2
	call WRITE1
	inc DI
	jmp print_p

end2:
	ret

ENVIRONMENT_CONTENT ENDP


; КОД
BEGIN:
	call MEMORY_INVALID_ADRESS
	call ENVIRONMENT_ADRESS
	call LINE_TAIL
	call ENVIRONMENT_CONTENT


; Выход в DOS
	xor AL,AL
	mov AH,4Ch
	int 21H
LAB2	 ENDS
END 	START 		;конец модуля, START - точка входа
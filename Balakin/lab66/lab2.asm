
LAB2 SEGMENT
 ASSUME CS:LAB2, DS:LAB2, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
; ДАННЫЕ

;СТРОКИ ДЛЯ ВЫВОДА ИНОФРМАЦИИ
MEMORYUNAV db 'Unavailable memory adress:     h',0DH,0AH,'$'
ENVIRONMENT db 'Environment adress:     h',0DH,0AH,'$'
CLINETAIL db 'Command-line tail:',0DH,0AH,'$'
EMPTYTAIL db 'No symbols in CL tail',0DH,0AH,'$'
ENVIRONMENTINFO db 'Environment info: ', 0DH,0AH,'$'
NEWLINE db 0DH,0AH,'$'
FILEPATH db 'File path: ',0DH,0AH,'$'

;ПРОЦЕДУРЫ

;вывод сообщения
WRITEMESSAGE PROC Near
mov AH,09h
int 21h
ret
WRITEMESSAGE ENDP

TETR_TO_HEX PROC near
 and AL,0Fh
 cmp AL,09
 jbe NEXT
 add AL,07
NEXT: add AL,30h
 ret
TETR_TO_HEX ENDP

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

;-------------------------------------------------------------------------------

;ОПРЕДЕЛЕНИЕ АДРЕСА НЕДОСТУПНОЙ ПАМЯТИ
WRITEMEMORYADRESS PROC Near
push AX
push ES
push BX
push DX
mov AX,ES:[2h]

lea DI, MEMORYUNAV
add DI, 30
call WRD_TO_HEX
mov DX, OFFSET MEMORYUNAV

call WRITEMESSAGE
pop DX
pop BX
pop ES
pop AX
ret
WRITEMEMORYADRESS ENDP

;ОПРЕДЕЛЕНИЕ АДРЕСА СРЕДЫ
WRITEENVIRONMENTADRESS PROC Near
push AX
push ES
push DX
mov AX,ES:[2Ch]

lea DI, ENVIRONMENT
add DI, 23
call WRD_TO_HEX
mov DX, OFFSET ENVIRONMENT
call WRITEMESSAGE

pop DX
pop ES
pop AX
ret
WRITEENVIRONMENTADRESS ENDP

;ОПРЕДЕЛЕНИЕ ХВОСТА КОМАНДНОЙ СТРОКИ
WRITECLINETAIL PROC Near
push AX
push ES
push BX
push DX
push CX

mov CX, 0
mov CL, ES:[80h]
cmp CX, 0
je empty

mov DX, OFFSET CLINETAIL
call WRITEMESSAGE

xor DX, DX
mov BX, 81h

addletter:
	mov DL, ES:[BX]
	inc BX
	mov AH,02h
	int 21h
	loop addletter
	mov DX, OFFSET NEWLINE
	call WRITEMESSAGE
	jmp writeend

empty:
	mov DX, OFFSET EMPTYTAIL
	call WRITEMESSAGE

writeend:
pop CX
pop DX
pop BX
pop ES
pop AX
ret
WRITECLINETAIL ENDP

;ОПРЕДЕЛЕНИЕ СОДЕРЖИМОГО СРЕДЫ И ПУТИ К МОДУЛЮ
WRITEENVIRONMENTINFO PROC Near
push DX
push AX
push BX
push ES

mov DX, OFFSET ENVIRONMENTINFO
call WRITEMESSAGE

mov ES, ES:[2Ch]
xor SI, SI
xor DX, DX
mov AX, 0
getsymbol:
	mov DL, byte ptr ES:[SI]
	cmp DL, 0
	je secondzerocheck
	mov AH, 02h
	int 21h
	inc SI
	jmp getsymbol
	
secondzerocheck:
	inc SI
	mov DL, byte ptr ES:[SI]
	cmp DL, 0
	je endcheck
	push DX
	mov DX, offset NEWLINE
	call WRITEMESSAGE
	pop DX
	jmp getsymbol
	
endcheck:
	push DX
	mov DX, offset NEWLINE
	call WRITEMESSAGE
	mov DX, offset FILEPATH
	call WRITEMESSAGE
	pop DX
	add SI, 3

getpathsymbol:
	mov DL, byte ptr ES:[SI]
	cmp DL, 0
	je endinfo
	mov AH, 02h
	int 21h
	inc SI
	jmp getpathsymbol

endinfo:
pop ES
pop BX	
pop AX
pop DX
ret
WRITEENVIRONMENTINFO ENDP

;
BEGIN:
 call WRITEMEMORYADRESS
 call WRITEENVIRONMENTADRESS
 call WRITECLINETAIL
 call WRITEENVIRONMENTINFO
 xor AL,AL
 
 mov AH, 01h
 int 21h
 
 mov AH,4Ch
 int 21H
LAB2 ENDS
END START ;конец модуля, START - точка входа
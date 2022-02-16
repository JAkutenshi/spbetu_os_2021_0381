
LAB1 SEGMENT
 ASSUME CS:LAB1, DS:LAB1, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
; ДАННЫЕ

;СТРОКИ ДЛЯ РАЗНЫХ ТИПОВ PC
PC db 'PC type: PC',0DH,0AH,'$'
PCXT db 'PC type: PC/XT',0DH,0AH,'$'
ATTYPE db 'PC type: AT or PS2 (50 or 60)',0DH,0AH,'$'
PS230 db 'PC type: PS2 30',0DH,0AH,'$'
PS280 db 'PC type: PS2 80',0DH,0AH,'$'
PCJR db 'PC type: PCjr',0DH,0AH,'$'
PCCONVERTIBLE db 'PC type: PC Convertible',0DH,0AH,'$'
UNKNOWN db 'Cannot recognize type code: XXh',0DH,0AH,'$'

SYSVERSION db 'System version:   .00', 0DH,0AH,'$'
OEMVERSION db 'OEM version:   ',0DH,0AH,'$'
USERNUMBER db 'User number:       h', 0DH, 0AH, '$'

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

;ОПРЕДЕЛЕНИЕ ТИПА PC
TYPEDETECTION PROC Near
push AX
push ES
push BX
push DX
mov AX,0F000h
mov ES,AX
mov AL,ES:[0FFFEh]


cmp AL,0FFh
je ITSPC

cmp AL,0FEh
je ITSPCXT
cmp AL,0FBh
je ITSPCXT

cmp AL,0FCh
je ITSAT

cmp AL,0FAh
je ITSPS230

cmp AL,0F8h
je ITSPS280

cmp AL,0FDh
je ITSPCJR

cmp AL,0F9h
je ITSPCCONV

jmp ITSUNKNOWN

ITSPC:
	mov DX, OFFSET PC
	jmp WRITEIT

ITSPCXT:
	mov DX, OFFSET PCXT
	jmp WRITEIT
	
ITSAT:
	mov DX, OFFSET ATTYPE
	jmp WRITEIT
	
ITSPS230:
	mov DX, OFFSET PS230
	jmp WRITEIT
	
ITSPS280:
	mov DX, OFFSET PS280
	jmp WRITEIT

ITSPCJR:
	mov DX, OFFSET PCJR
	jmp WRITEIT

ITSPCCONV:
	mov DX, OFFSET PCCONVERTIBLE
	jmp WRITEIT

ITSUNKNOWN:
	call BYTE_TO_HEX
	lea BX, UNKNOWN
	mov [BX+28],AX
	mov DX, OFFSET UNKNOWN

WRITEIT:
	call WRITEMESSAGE
	pop DX
	pop BX
	pop ES
	pop AX
ret
TYPEDETECTION ENDP

;ОПРЕДЕЛЕНИЕ ВЕРСИИ СИСТЕМЫ
VERSIONDETECTION PROC Near
push AX
push SI
push DI
push DX
push BX
push CX
mov AH,30h
int 21h

lea SI, SYSVERSION
add SI, 17
call BYTE_TO_DEC

add SI,4
mov AH, AL
call BYTE_TO_DEC
mov DX, OFFSET SYSVERSION
call WRITEMESSAGE

mov AH, BH
lea SI, OEMVERSION
add SI, 15
call BYTE_TO_DEC
mov DX, OFFSET OEMVERSION
call WRITEMESSAGE

mov AX,CX
lea DI,USERNUMBER
add DI, 16
call WRD_TO_HEX
lea DI, USERNUMBER
add DI, 17
mov AL, BL
call BYTE_TO_HEX
mov [DI], AX
mov DX, OFFSET USERNUMBER
call WRITEMESSAGE

pop CX
pop BX
pop DX
pop DI
pop SI
pop AX
ret
VERSIONDETECTION ENDP

;
BEGIN:
 call TYPEDETECTION
 call VERSIONDETECTION
; Выход в DOS
 xor AL,AL
 mov AH,4Ch
 int 21H
LAB1 ENDS
 END START ;конец модуля, START - точка входа
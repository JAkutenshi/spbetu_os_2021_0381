;Модуль типа .EXE

AStack SEGMENT STACK
DW 512 DUP(?)
AStack ENDS

DATA SEGMENT
;Данные
;Строки для вывода PC
PC db 'PC - PC', 0DH, 0AH, '$'
PC_XT db 'PC - PC/XT', 0DH, 0AH, '$'
TYPE_AT db 'PC - AT or PS2 (50/60)', 0DH, 0AH, '$'
PS2_30 db 'PC - PS2 (30)', 0DH, 0AH, '$'
PS2_80 db 'PC - PS2 (80)', 0DH, 0AH, '$'
PC_JR db 'PC - PCjr', 0DH, 0AH, '$'
PC_CONVERTIBLE db 'Type of PC: PC Convertable', 0DH, 0AH, '$'
UNKNOWN db 'PC CODE - XXh', 0DH, 0AH, '$'
SYS_VERS db 'System version:   .', 0DH, 0AH, '$'
OEM_NUM db 'OEM:  ', 0DH, 0AH, '$'
USER_NUM db 'User:       h', 0DH, 0AH, '$'
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA, SS:AStack
;Процедуры
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
WRITE PROC near
mov AH, 09h
int 21h
ret
WRITE ENDP
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




TYPE_OF_PC PROC near
mov AX, 0f000h
mov ES, AX
mov AL, ES:[0fffeh] 
	
cmp AL, 0ffh
je PC_TYPE
	
cmp AL, 0feh
je PC_XT_TYPE
	
cmp AL, 0fbh
je PC_XT_TYPE
	
cmp AL, 0fch
je AT_TYPE
	
cmp AL, 0fah
je PS2_30_TYPE
	
cmp AL, 0f8h
je PS2_80_TYPE
	
cmp AL, 0fdh
je PC_JR_TYPE
	
cmp AL, 0f9h
je PC_CONVERTIBLE_TYPE
	
call BYTE_TO_HEX
lea BX, UNKNOWN
mov [BX+10], AX

lea DX, UNKNOWN	
jmp write_this

	
PC_TYPE:
lea DX, PC
jmp write_this


PC_XT_TYPE:
lea DX, PC_XT
jmp write_this


AT_TYPE:
lea DX, TYPE_AT
jmp write_this
	

PS2_30_TYPE:
lea DX, PS2_30
jmp write_this


PS2_80_TYPE:
lea DX, PS2_80
jmp write_this


PC_JR_TYPE:
lea DX, PC_JR
jmp write_this


PC_CONVERTIBLE_TYPE:
lea DX, PC_CONVERTIBLE
jmp write_this
	

write_this:
call WRITE
ret

TYPE_OF_PC ENDP


VERS PROC near
mov AH, 30h
int 21h
	
push AX
lea SI, SYS_VERS
add SI, 17
call BYTE_TO_DEC
pop AX	
mov AL, AH
add SI, 3
call BYTE_TO_DEC
lea DX, SYS_VERS
call WRITE
	
lea SI, OEM_NUM
add SI, 5
mov AL, BH
call BYTE_TO_DEC
lea DX, OEM_NUM
call WRITE
	
lea DI, USER_NUM
add DI, 11
mov AX, CX
call WRD_TO_HEX
mov AL, BL
call BYTE_TO_HEX
mov [DI-2], AX
lea DX, USER_NUM
call WRITE
ret
	
VERS ENDP

MAIN PROC far
sub AX, AX
push AX
mov AX, DATA
mov DS, AX

call TYPE_OF_PC
call VERS

; Выход в DOS
xor AL,AL
mov AH,4Ch
int 21H


MAIN ENDP
CODE ENDS
END MAIN


AStack SEGMENT STACK
DW 512 DUP(?)
AStack ENDS

DATA SEGMENT

;Вывод PC
PC db 'PC', 0DH, 0AH, '$'
XPC db 'PC/XT', 0DH, 0AH, '$'
TYPE_AT db 'AT or PS2 [50 or 60]', 0DH, 0AH, '$'
PS30_2 db 'PS2 [30]', 0DH, 0AH, '$'
PS80_2 db 'PS2 [80]', 0DH, 0AH, '$'
JR db 'PCjr', 0DH, 0AH, '$'
PCC db 'Type PC Convertable', 0DH, 0AH, '$'
UN db 'CODE - XXh', 0DH, 0AH, '$'
SYSTEM db 'System version:   .', 0DH, 0AH, '$'
OEN db 'OEM:  ', 0DH, 0AH, '$'
USN db 'User:       h', 0DH, 0AH, '$'
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA, SS:AStack

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
WR PROC near
mov AH, 09h
int 21h
ret
WR ENDP
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
PCTYPE PROC near
mov AX, 0f000h
mov ES, AX
mov AL, ES:[0fffeh] 
	
cmp AL, 0ffh
je TYPE
	
cmp AL, 0feh
je XTYPE
	
cmp AL, 0fbh
je XTYPE
	
cmp AL, 0fch
je AT_TYPE
	
cmp AL, 0fah
je PS30_2_TYPE
	
cmp AL, 0f8h
je PS80_2_TYPE
	
cmp AL, 0fdh
je JR_TYPE
	
cmp AL, 0f9h
je PCC_TYPE
	
call BYTE_TO_HEX
lea BX, UN
mov [BX+10], AX

lea DX, UN	
jmp write

	
TYPE:
lea DX, PC
jmp write


XTYPE:
lea DX, XPC
jmp write


AT_TYPE:
lea DX, TYPE_AT
jmp write
	

PS30_2_TYPE:
lea DX, PS30_2
jmp write


PS80_2_TYPE:
lea DX, PS80_2
jmp write


JR_TYPE:
lea DX, JR
jmp write


PCC_TYPE:
lea DX, PCC
jmp write
	

write:
call WR
ret

PCTYPE ENDP
;-------------------------------
;-------------------------------
VERSION PROC near
mov AH, 30h
int 21h
	
push AX
lea SI, SYSTEM
add SI, 17
call BYTE_TO_DEC
pop AX	
mov AL, AH
add SI, 3
call BYTE_TO_DEC
lea DX, SYSTEM
call WR
	
lea SI, OEN
add SI, 5
mov AL, BH
call BYTE_TO_DEC
lea DX, OEN
call WR
	
lea DI, USN
add DI, 11
mov AX, CX
call WRD_TO_HEX
mov AL, BL
call BYTE_TO_HEX
mov [DI-2], AX
lea DX, USN
call WR
ret
	
VERSION ENDP
;-------------------------------

MAIN PROC far
sub AX, AX
push AX
mov AX, DATA
mov DS, AX

call PCTYPE
call VERSION

; Выход в DOS
xor AL,AL
mov AH,4Ch
int 21H


MAIN ENDP
CODE ENDS
END MAIN

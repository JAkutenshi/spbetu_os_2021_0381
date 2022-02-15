; Шаблон текста программы на ассемблере для модуля типа .COM
TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
; ДАННЫЕ
_TYPE db 'Type: $'
PC db 'PC',0DH,0AH,'$'
PC_XT db 'PC/XT',0DH,0AH,'$'
_AT db 'AT',0DH,0AH,'$'
PS30 db 'PS2 model 30',0DH,0AH,'$'
PS50 db 'PS2 model 50 or 60',0DH,0AH,'$'
PS80 db 'PS2 model 80',0DH,0AH,'$'
PCjr db 'PCjr',0DH,0AH,'$'
PCC db 'PC Convertible',0DH,0AH,'$'
_h db 'h',0DH,0AH,'$'
VERSION db 'Version: 00.00',0DH,0AH,'$'
OEM db 'OEM S/N: $'
USER db 'USER S/N: 000000h$'
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
BEGIN:

mov AX,0F000h
mov es,ax
mov bl, es:[0FFFEh]
mov dx, offset _TYPE
mov AH,09h
 int 21h

cmp bl,0ffh
je _pc
cmp bl,0feh
je _xt
cmp bl,0fbh
je _xt
cmp bl,0fch
je __at
cmp bl,0fah
je _ps30
cmp bl,0fch
je _ps50
cmp bl,0f8h
je _ps80
cmp bl,0fdh
je _pcjr
cmp bl,0f9h
je _pcc
jmp printhex
_pc:
	mov DX,offset PC
	jmp print
_xt:
	mov DX,offset PC_XT
	jmp print
__at:
	mov DX,offset _AT
	jmp print
_ps30:	
	mov DX,offset PS30
	jmp print
_ps50:	
	mov DX,offset PS50
	jmp print
_ps80:	
	mov DX,offset PS80
	jmp print	
_pcjr:	
	mov DX,offset PCjr
	jmp print
_pcc:	
	mov DX,offset PCC
	jmp print	
	
 print:
 mov AH,09h
 int 21h
 jmp ver
 printhex:
mov al,bl
 call BYTE_TO_HEX
 mov dx,ax
 mov ah, 02h
 int 21h
xchg dh,dl
 int 21h
 mov dx,offset _h
 mov AH,09h
 int 21h
 
 ver:
 mov ax,ds
 mov es,ax
 
 mov ah,30h
 int 21h

 mov dx,ax
 mov si,10
 add si,offset VERSION
 call BYTE_TO_DEC
 mov al,dh 
 add si, 3
 call BYTE_TO_DEC
 
  mov dx,offset VERSION
 mov AH,09h
 int 21h
 
 mov dx,offset OEM
 mov AH,09h
 int 21h
 
 mov al,bh
 call BYTE_TO_HEX
 mov dx,ax
 mov ah, 02h
 int 21h
 xchg dh,dl
 int 21h
 mov dx,offset _h
 mov AH,09h
 int 21h
 

 mov di,15
 add di,offset USER
 mov ax,cx
 call WRD_TO_HEX
 mov al,bl
 call BYTE_TO_HEX
 mov [di-2], ax
 
 mov dx,offset USER
 mov AH,09h
 int 21h
 
; Выход в DOS
 xor AL,AL
 mov AH,4Ch
 int 21H
TESTPC ENDS
 END START ;конец модуля, START - точка входа
TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
   ORG 100H
START: JMP BEGIN
; Данные
type_pc db 'IBM PC type: PC', 0Dh, 0Ah, '$'
type_pc_xt db 'IBM PC type: PC/XT', 0Dh, 0Ah, '$'
type_at db 'IBM PC type: AT or PS2 (50 or 60)', 0Dh, 0Ah, '$'
type_ps30 db 'IBM PC type: PS2 30', 0Dh, 0Ah, '$'
type_ps80 db 'IBM PC type: PS2 80', 0Dh, 0Ah, '$'
type_pcjr db 'IBM PC type: PСjr', 0Dh, 0Ah, '$'
type_pc_convertible db 'IBM PC type: PC Convertible', 0Dh, 0Ah, '$'
type_undefined db 'Undefined IBM PC type code:   h', 0Dh, 0Ah, '$'

version db 'MS-DOS version:  .  ', 0Dh, 0Ah, '$'
oem_number db 'OEM serial number:   ', 0Dh, 0Ah, '$'
user_number db 'User serial number:       h$'

; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
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
print proc near
   mov AH,09h
   int 21h
   ret
print endp

pc_type_defenition proc near
   mov ax, 0f000h 
	mov es, ax
	mov al, es:[0fffeh]

	cmp al, 0FFh
	je pc
	cmp al, 0FEh
	je pc_xt
	cmp al, 0FBh
	je pc_xt
	cmp al, 0FCh
	je pc_at
	cmp al, 0FAh
	je ps30
	cmp al, 0F8h
	je ps80
	cmp al, 0FDh
	je pcjr
	cmp al, 0F9h
	je pc_convertible

   call BYTE_TO_HEX
	mov bx, offset type_undefined
	mov [bx+28], ax
	mov dx, offset type_undefined
   jmp print_type

pc:
	mov dx, offset type_pc
	jmp print_type

pc_xt:
	mov dx, offset type_pc_xt
	jmp print_type

pc_at:
	mov dx, offset type_at
	jmp print_type

ps30:
	mov dx, offset type_ps30
	jmp print_type

ps80:
	mov dx, offset type_ps80
	jmp print_type

pcjr:
	mov dx, offset type_pcjr
	jmp print_type

pc_convertible:
	mov dx, offset type_pc_convertible

print_type:
	call print
	ret
pc_type_defenition endp

version_defenition proc near
	mov ah, 30h
	int 21h
	push ax
	
	mov si, offset version
	add si, 16
	call BYTE_TO_DEC
   pop ax
   mov al, ah
   add si, 3
	call BYTE_TO_DEC
	mov dx, offset version
	call print
   
	mov si, offset oem_number
	add si, 19
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset oem_number
	call print
	
	mov di, offset user_number
	add di, 25
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset user_number
	call print
	ret
version_defenition endp

; Код
BEGIN:
   call pc_type_defenition
   call version_defenition

   xor AL,AL
   mov AH,4Ch
   int 21H
TESTPC ENDS
END START 
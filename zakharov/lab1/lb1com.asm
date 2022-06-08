TESTPC  SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 	ORG 100H
START:  JMP BEGIN

; Данные
TYPE_PC DB  'Type of my PC: PC', 0DH, 0AH,'$'
TYPE_PC_XT DB 'Type of my PC: PC/XT', 0DH,0AH,'$'
TYPE_AT db  'Type of my PC: AT', 0DH,0AH,'$'
TYPE_PS2_M30 DB 'Type of my PC: PS2 model 30', 0DH, 0AH,'$'
TYPE_PS2_M50_M60 DB 'Type of my PC: PS2 model 50 or 60', 0DH, 0AH,'$'
TYPE_PS2_M80 DB 'Type of my PC: PS2 model 80: ', 0DH, 0AH,'$'
TYPE_PС_jr DB 'Type of my PC: PСjr', 0DH, 0AH,'$'
TYPE_PC_CNV DB 'Type of my PC: PC Convertible', 0DH, 0AH,'$'
MS_DOS DB 'Version MS DOS:  .  ', 0DH, 0AH,'$'
SERIAL_NUMBER_OEM DB 'Serial number OEM:       ', 0DH, 0AH,'$'
USER_NUMBER DB 'User serial number:       ', 0DH, 0AH, '$'
ERROR DB 'Error! The byte value does not match the PC type values'


; Процедуры
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
; Байт в AL переводится в два символа шест. числа в AX
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX ; В AL старшая цифра
	pop CX ; В AH младшая цифра
	ret
BYTE_TO_HEX ENDP

;-------------------------------
WRD_TO_HEX PROC near
; Перевод в 16 с/с 16-ти разрядного числа
; В AX - число, DI - адрес последнего символа
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
; Перевод в 10 с/с, SI - адрес поля младшей цифры
 	push CX
 	push DX
 	xor AH,AH
 	xor DX,DX
 	mov CX,10
loop_bd:div CX
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
end_l:  pop DX
 	pop CX
 	ret
BYTE_TO_DEC ENDP



PRINT_STRING PROC near
	push ax
   	mov AH,09h
   	int 21h
	pop ax
   	ret
PRINT_STRING endp


PRINT_PC_TYPE PROC near

   	mov ax, 0f000h  ; Получаем информацию о типе ПК
	mov es, ax
	mov al, es:[0fffeh]

; --------------------------------------------------
; Сравнение:
	cmp al, 0ffh 
	je print_pc

	cmp al, 0feh
	je print_pc_xt

	cmp al, 0fbh
	je print_pc_xt

	cmp al, 0fch
	je print_pc_at

	cmp al, 0fah
	je print_pc_ps2_m30

	cmp al, 0fch
	je print_pc_ps2_m50_m60

	cmp al, 0f8h
	je print_pc_ps2_m80

	cmp al, 0fdh
	je print_pc_jr

	cmp al, 0f9h
	je print_pc_cnv

	mov dx, offset ERROR  ; Вызывается ошибка, если значение байта не совпадает со значениями типа ПК
    	jmp print_type


print_pc:
	mov dx, offset TYPE_PC
	jmp print_type

print_pc_xt:
	mov dx, offset TYPE_PC_XT
	jmp print_type

print_pc_at:
	mov dx, offset TYPE_AT
	jmp print_type

print_pc_ps2_m30:
	mov dx, offset TYPE_PS2_M30
	jmp print_type

print_pc_ps2_m50_m60:
	mov dx, offset TYPE_PS2_M50_M60
	jmp print_type

print_pc_ps2_m80:
	mov dx, offset TYPE_PS2_M80
	jmp print_type

print_pc_jr:
	mov dx, offset TYPE_PС_jr
	jmp print_type

print_pc_cnv:
	mov dx, offset TYPE_PC_CNV
	jmp print_type

print_type:
	call PRINT_STRING

	ret

PRINT_PC_TYPE ENDP



PRINT_OS_VERSION PROC near
    	push ax ; Сохранение значений регистров
    	push bx
    	push cx
    	push dx
	push si
	push di

	mov ah, 30h ; Определении версии MS DOS 
	int 21h
	
	mov si, offset MS_DOS; Версия ОС
	add si, 16
	call BYTE_TO_DEC
  	mov al, ah
   	add si, 3
	call BYTE_TO_DEC
	mov dx, offset MS_DOS
	call PRINT_STRING
	
	mov si, offset SERIAL_NUMBER_OEM ; Серийный номер ОЕМ
	add si, 21
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset SERIAL_NUMBER_OEM
	call PRINT_STRING
	
	mov di, offset USER_NUMBER  ; Серийный номер пользователя
	add di, 25
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset USER_NUMBER
	call PRINT_STRING

    	pop dx ; Восстановление значений регистров
    	pop cx
    	pop bx
    	pop ax
	pop si
	pop di

	ret
PRINT_OS_VERSION ENDP


BEGIN:
   call PRINT_PC_TYPE
   call PRINT_OS_VERSION

   xor al, al
   mov ah, 4Ch
   int 21H


TESTPC ENDS

END START

TESTPC SEGMENT

   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
   ORG 100h
START: 
	jmp BEGIN

; data
PC_m db  'PC',0Dh,0Ah,'$'
XT_m db 'PC/XT',0Dh,0Ah,'$'
AT_m db  'AT',0Dh,0Ah,'$'
PS2_model30_m db 'PS2 model 30',0Dh,0Ah,'$'
PS2_model80_m db 'PS2 model 80',0Dh,0Ah,'$'
PCjr_m db 'PСjr',0Dh,0Ah,'$'
PC_convertible_m db 'PC Convertible',0Dh,0Ah,'$'
PC_custom_m db '  ', 0Dh, 0Ah, '$' 
DOS_ver db '  .  ', 0Dh, 0Ah, '$'
OEM db '   ', 0Dh, 0Ah, '$'
USER db '                     ', '$'
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
   cmp AL, 0h
   je zero
   xor AH,AH
   xor DX,DX
   mov CX,10
loop_bd:
   div CX
   add DL,30h
   mov [SI],DL
   dec SI
   xor DX,DX
   cmp AX,10
   jae loop_bd
   cmp AL,00h
   or AL,30h
   mov [SI],AL
   jmp end_l
zero:
   or AL, 30h
   mov[SI], AL
end_l:
   pop DX
   pop CX
   ret
BYTE_TO_DEC ENDP
;-------------------------------
model_print PROC near
	mov AH,9h
	int 21h
	ret

model_print ENDP
;-----------------------------------
PC_ver PROC near
						;PC version parsing
	mov ax, 0f000h
	mov es, ax
	mov al, es:[0fffeh]

	cmp al, 0FFh
	je PC
	cmp al, 0FEh
	je XT
	cmp al, 0FBh
	je XT
	cmp al, 0FCh
	je AT
	cmp al, 0FAh
	je PS2_model30
	cmp al, 0F8h
	je PS2_model80
	cmp al, 0FDh
	je PCjr
	cmp al, 0F9h
	je PC_convertible
	jmp PC_custom

	PC:
		mov dx, offset PC_m
		jmp model_output
	XT:
		mov dx, offset XT_m
		jmp model_output
	AT:
		mov dx, offset AT_m
		jmp model_output
	PS2_model30:
		mov dx, offset PS2_model30_m
		jmp model_output
	PS2_model80:
		mov dx, offset PS2_model80_m
		jmp model_output
	PC_custom: ; ???####???
		mov si, offset PC_custom_m
		inc si
		call BYTE_TO_HEX
		mov dx, offset PC_custom_m
		jmp model_output
	PCjr:
		mov dx, offset PCjr_m
		jmp model_output
	PC_convertible:
		mov dx, offset PC_convertible_m
	model_output:
		call model_print
		ret	
PC_ver ENDP
;----------------------------------------
OS_ver PROC near
	mov AH, 30h
	int 21h
	push ax
	mov si, offset DOS_ver
	inc si
	call BYTE_TO_DEC
	pop ax
	add si, 4
	call BYTE_TO_DEC
	mov dx, offset DOS_ver
	call model_print
	ret

OS_ver endp
;---------------------------------
OEM_num PROC near
	mov si, offset OEM
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset OEM
	call model_print
	ret
OEM_num endp
;------------------------------------
USER_num PROC near
	mov di, offset USER
	add di, 5
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset USER
	call model_print
	ret
USER_num ENDP
;-------------------------------
; Code
BEGIN:
	call PC_ver
	call OS_ver
	call OEM_num
	call USER_num
	xor AL,AL
	mov AH,4Ch
	int 21H

TESTPC ENDS
END START
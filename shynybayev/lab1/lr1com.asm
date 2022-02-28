TESTPC SEGMENT

   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
   ORG 100h
START:
	jmp BEGIN

; data
PCm db  'PC',0Dh,0Ah,'$'
XTm db 'PC/XT',0Dh,0Ah,'$'
ATm db  'AT',0Dh,0Ah,'$'
PS2_30m db 'PS2 model 30',0Dh,0Ah,'$'
PS2_80m db 'PS2 model 80',0Dh,0Ah,'$'
PS_jrm db 'PСjr',0Dh,0Ah,'$'
PCconv_m db 'PC Convertible',0Dh,0Ah,'$'
PCcust_m db '  ', 0Dh, 0Ah, '$'
DOSver db '  .  ', 0Dh, 0Ah, '$'
OEm db '   ', 0Dh, 0Ah, '$'
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
	je PS2_30
	cmp al, 0F8h
	je PS2_80
	cmp al, 0FDh
	je PC_jr
	cmp al, 0F9h
	je PC_conv
	jmp PC_cust

	PC:
		mov dx, offset PCm
		jmp model_out
	XT:
		mov dx, offset XTm
		jmp model_out
	AT:
		mov dx, offset ATm
		jmp model_out
	PS2_30:
		mov dx, offset PS2_30m
		jmp model_out
	PS2_80:
		mov dx, offset PS2_80m
		jmp model_out
	PC_cust: 
		mov si, offset PCcust_m
		inc si
		call BYTE_TO_HEX
		mov dx, offset PCcust_m
		jmp model_out
	PC_jr:
		mov dx, offset PS_jrm
		jmp model_out
	PC_conv:
		mov dx, offset PCconv_m
	model_out:
		call model_print
		ret
PC_ver ENDP
;----------------------------------------
OS_ver PROC near
	mov AH, 30h
	int 21h
	push ax
	mov si, offset DOSver
	inc si
	call BYTE_TO_DEC
	pop ax
	add si, 4
	call BYTE_TO_DEC
	mov dx, offset DOSver
	call model_print
	ret

OS_ver endp
;---------------------------------
OEM_num PROC near
	mov si, offset OEm
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset OEm
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
stk segment stack
	db 128 dup (49)
stk ends
prog segment
assume cs:prog, ds:data, ss:stk

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
									; байт в al переводится в два символа шестн. числа в ax
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX 				;в al старшая цифра
	pop CX 							;в AH младшая
	ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
									;перевод в 16 с/с 16-ти разрядного числа
									; в ax - число, DI - адрес последнего символа
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
	end_l:pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP

Def_PCType proc near
	
	mov ax, 0f000h
	mov es, ax
	mov al, es:[0fffeh]

	cmp al, 0ffh
		je case_pc
	cmp al, 0feh
		je case_pc_xt
	cmp al, 0fbh
		je case_pc_xt
	cmp al, 0fch
		je case_pc_at
	cmp al, 0fah
		je case_pc_ps2_30
	cmp al, 0f8h
		je case_pc_ps2_80
	cmp al, 0fdh
		je case_pcjr
	cmp al, 0f9h
		je case_pc_conv
	
	case_pc:
		mov dx, offset pc
		jmp print_type

	case_pc_xt:
		mov dx, offset pc_xt
		jmp print_type
		
	case_pc_at:
		mov dx, offset pc_at
		jmp print_type
		
	case_pc_ps2_30:
		mov dx, offset pc_ps2_30
		jmp print_type
		
	case_pc_ps2_80:
		mov dx, offset pc_ps2_80
		jmp print_type

	case_pcjr:
		mov dx, offset pc_pcjr
		jmp print_type

	case_pc_conv:
		mov dx, offset pc_conv
		jmp print_type

	print_type:
		call PrintProc
	
	ret
Def_PCType endp

Def_SysVer proc near

	mov ah, 30h
	int 21h
									; MS-dos Version
	mov si, offset ms_dos_ver
	add si, 17
	call BYTE_TO_DEC
	mov ah, al
	add si, 3
	call BYTE_TO_DEC
	mov dx, offset ms_dos_ver
	call PrintProc
	
									; OEM
	mov si, offset oem_sn
	add si, 20
	mov ah, bh
	call BYTE_TO_DEC
	mov dx, offset oem_sn
	call PrintProc
	
									; user serial number
	mov di, offset user_sn
	add di, 25
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset user_sn
	call PrintProc
	
	ret
Def_SysVer endp

PrintProc proc near
	mov ah, 09h
	int 21h
	ret
PrintProc endp

;-------------------------------
main proc far

	mov ax, data
	mov ds, ax

	call Def_PCType
	call Def_SysVer

	xor al,al
	mov AH,4Ch
	int 21H
	main ENDP
prog ends

data segment

	pc db 'PC type: PC', 0dh, 0ah, '$'
	pc_xt db 'PC type: PC/XT', 0dh, 0ah, '$'
	pc_at db 'PC type: AT or PS2 (model 50 or 60)', 0dh, 0ah, '$'
	pc_ps2_30 db 'PC type: PS2 model 30', 0dh, 0ah, '$'
	pc_ps2_80 db 'PC type: PS2 model 80', 0dh, 0ah, '$'
	pc_pcjr db 'PC type: PCjr', 0dh, 0ah, '$'
	pc_conv db 'PC type: PC Convertible', 0dh, 0ah, '$'
	ms_dos_ver db 'MS-DOS version:   .  ', 0dh, 0ah, '$'
	oem_sn db 'OEM serial number:   ', 0dh, 0ah, '$'
	user_sn db 'User serial number:       h', 0dh, 0ah, '$'
	
data ends
	end main
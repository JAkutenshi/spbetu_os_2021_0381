; Шаблон текста программы на ассемблере для модуля типа .COM
TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: 
JMP BEGIN
; ДАННЫЕ
_INACCESSIBLEMEMORY db  'Segment address of inaccessible memory:     h', 0Dh, 0Ah, '$'
_ENVIRONMENTADDRESS db 'Segment address of environment:     h', 0Dh, 0Ah, '$'
_TAIL db  'Command line tail:', 0Dh, 0Ah, '$'
_ENVIRONMENTCONTENTS db 'Contents of the environment area:', 0Dh, 0Ah, '$'
_MODULEPATH db 'Path of the loaded module: $'
_S_N db 0Dh, 0Ah, '$' 
;ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX PROC near
	and al,0Fh
 	cmp al,09
 	jbe NEXT
 	add al,07
NEXT: 
	add al,30h
 	ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; байт в AL переводится в два символа шестн. числа в AX
 	push cx
 	mov ah,al
 	call TETR_TO_HEX
 	xchg al,ah
 	mov cl,4
 	shr al,cl
 	call TETR_TO_HEX ;в AL старшая цифра
 	pop cx ;в AH младшая
 	ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
 	push bx
 	mov bh,ah
 	call BYTE_TO_HEX
 	mov [di],ah
 	dec di
 	mov [di],al
 	dec di
 	mov al,bh
 	call BYTE_TO_HEX
 	mov [di],ah
	dec di
 	mov [di],al
 	pop bx
 	ret
WRD_TO_HEX ENDP
;--------------------------------------------------

PUTS PROC near
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
PUTS ENDP

PUTC PROC near
	push ax
	mov ah, 02h
	int 21h
	pop ax
	ret
PUTC ENDP

PUTS_N PROC near
	push dx
	mov dx, offset _S_N
	call PUTS
	pop dx
	ret
PUTS_N ENDP

INACCESSIBLE_MEMORY PROC near
	mov di, offset _INACCESSIBLEMEMORY
	add di, 43
	mov ax, ds:[2h]
	call WRD_TO_HEX
	mov [di], ax
	mov dx, offset _INACCESSIBLEMEMORY
	call PUTS
	ret
INACCESSIBLE_MEMORY ENDP

ENVIRONMENT_ADDRESS PROC near
	mov di, offset _ENVIRONMENTADDRESS
	add di, 35
	mov ax, ds:[2Ch]
	call WRD_TO_HEX
	mov [di], ax
	mov dx, offset _ENVIRONMENTADDRESS
	call PUTS
	ret
ENVIRONMENT_ADDRESS ENDP

TAIL PROC near
	mov dx, offset _TAIL
	call PUTS
	mov ah, 13h
	mov cx, 0
	mov cl, ds:[80h]
	cmp cl, 0
	je empty
	lea di, ds:[81h]

cycle:
	mov dl, [di]
	call PUTC
	inc di
	loop cycle
	call PUTS_N
	jmp tail_end

empty: 
	call PUTS_N

tail_end:
	ret
TAIL ENDP
	
	
ENVIRONMENTCONTENTS_MODULEPATH PROC near
	mov dx, offset _ENVIRONMENTCONTENTS
	call PUTS
	mov es, ds:[2Ch]
	mov di, 0

reading:
	mov dl, es:[di]
	cmp dl, 0
	jne read_content
	call PUTS_N
	inc di
	mov dl, es:[di]
	cmp dl, 0
	je end_content

read_content:	
	call PUTC
	inc di
	jmp reading
	
end_content:
	add di, 3
	mov dx, offset _MODULEPATH
	call PUTS
	call PUTS_N

read_path:	
	mov dl, es:[di]
	cmp dl, 0
	je end_path
	call PUTC
	inc di
	jmp read_path

end_path:
	ret
ENVIRONMENTCONTENTS_MODULEPATH ENDP

; КОД
BEGIN:
	call INACCESSIBLE_MEMORY
	call ENVIRONMENT_ADDRESS
	call TAIL
	call ENVIRONMENTCONTENTS_MODULEPATH

; Выход в DOS

	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
END START  
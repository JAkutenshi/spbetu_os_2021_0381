TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 	ORG 100H
START: JMP BEGIN
;Данные
	MEM_ADRESS db  'Address of unavailable memory:     h', 0Dh, 0Ah, '$'
	ENV_ADRESS db 'Address of environment:     h', 0Dh, 0Ah, '$'
	TAIL db  'Command line tail:', 0Dh, 0Ah, '$'
	CONTENT db 'Content:', 0Dh, 0Ah, '$'
	MOD_PATH db 'Path: $'
	_STR db 0Dh, 0Ah, '$' 
;Процедуры
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
 	call TETR_TO_HEX 	; в AL старшая цифра
 	pop cx 				; в AH младшая
 	ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
; перевод в 16-ю с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего числа
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

WRITESTRING PROC near
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
WRITESTRING ENDP

PUTC PROC near
	; push ax
	mov ah, 02h
	int 21h
	; pop ax
	ret
PUTC ENDP

PUTSTR PROC near
	; push dx
	mov dx, offset _STR
	call WRITESTRING
	; pop dx
	ret
PUTSTR ENDP

PSP_UNAVAILABLE_MEMORY PROC near
	mov di, offset MEM_ADRESS
	add di, 34
	mov ax, ds:[2h]
	call WRD_TO_HEX
	mov [di], ax
	mov dx, offset MEM_ADRESS
	call WRITESTRING
	ret
PSP_UNAVAILABLE_MEMORY ENDP

ENVIRONMENT PROC near
	mov di, offset ENV_ADRESS
	add di, 27
	mov ax, ds:[2Ch]
	call WRD_TO_HEX
	mov [di], ax
	mov dx, offset ENV_ADRESS
	call WRITESTRING
	ret
ENVIRONMENT ENDP

PSP_TAIL PROC near
	mov dx, offset TAIL
	call WRITESTRING
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
	call PUTSTR
	jmp tail_end

empty: 
	call PUTSTR

tail_end:
	ret
PSP_TAIL ENDP
	
	
MODULE_PATH PROC near
	mov dx, offset CONTENT
	call WRITESTRING
	mov es, ds:[2Ch]
	mov di, 0

reading:
	mov dl, es:[di]
	cmp dl, 0
	jne read_content
	call PUTSTR
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
	mov dx, offset MOD_PATH
	call WRITESTRING
	call PUTSTR

read_path:	
	mov dl, es:[di]
	cmp dl, 0
	je end_path
	call PUTC
	inc di
	jmp read_path

end_path:
	ret
MODULE_PATH ENDP

BEGIN:
	call PSP_UNAVAILABLE_MEMORY
	call ENVIRONMENT
	call PSP_TAIL
	call MODULE_PATH

	xor AL,AL

	mov AH,01h
    int 21H

	mov AH,4Ch
	int 21H
TESTPC ENDS
END START
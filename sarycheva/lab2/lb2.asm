LB2 SEGMENT
 ASSUME CS:LB2, DS:LB2, ES:NOTHING, SS:NOTHING
 ORG 100H
START: 
JMP BEGIN
; ДАННЫЕ
INACCESSIBLEMEMORY db  'Segment address of inaccessible memory:     h',0DH,0AH,'$'
ENVIRONMENTADDRESS db 'Segment address of environment:     h',0DH,0AH,'$'
TAIL db  'Command line tail:',0DH,0AH,'$'
ENVIRONMENTCONTENTS db 'Contents of the environment area:',0DH,0AH,'$'
MODELEPATH db 'Path of the loaded modele: $'
EMPTYTAIL db 'Command line tail is empty.', 0DH,0AH,'$'
S_ENTER db ' ',0DH, 0AH,'$' 
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

OUTPUT PROC near
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
OUTPUT ENDP

OUTPUT_SYMBOL PROC near
	push ax
	mov ah, 02H
	int 21h
	pop ax
	ret
OUTPUT_SYMBOL ENDP

OUTPUT_ENTER PROC near
	push dx
	mov dx, offset S_ENTER
	call OUTPUT
	POP dx
	ret
OUTPUT_ENTER ENDP

OUTPUT_INACCESSIBLE_MEMORY PROC near
	mov di, offset INACCESSIBLEMEMORY
	add di, 43
	mov ax, ds:[2h]
	call WRD_TO_HEX
	mov [di], ax
	mov dx, offset INACCESSIBLEMEMORY
	call OUTPUT
	ret
OUTPUT_INACCESSIBLE_MEMORY ENDP

OUTPUT_ENVIRONMENT_ADDRESS PROC near
	mov di, offset ENVIRONMENTADDRESS
	add di, 35
	mov ax, ds:[2Ch]
	call WRD_TO_HEX
	mov [di], ax
	mov dx, offset ENVIRONMENTADDRESS
	call OUTPUT
	ret
OUTPUT_ENVIRONMENT_ADDRESS ENDP

OUTPUT_TAIL PROC near
	mov dx, offset TAIL
	call OUTPUT
	mov ah, 13h
	mov cx, 0
	mov cl, ds:[80h]
	cmp cl, 0
	je empty
	lea di, ds:[81h]
cycle:
	mov dl, [di]
	call OUTPUT_SYMBOL
	inc di
	loop cycle
	call OUTPUT_ENTER
	jmp tail_end
empty: 
	mov dx, offset EMPTYTAIL
	call OUTPUT
tail_end:
	ret
OUTPUT_TAIL ENDP
	
	
OUTPUT_ENVIRONMENTCONTENTS_MODELEPATH PROC near
	mov dx, offset ENVIRONMENTCONTENTS
	call OUTPUT
	mov es, ds:[2Ch]
	mov di, 0

checking:
	mov dl, es:[di]
	cmp dl, 0
	jne output_content
	call OUTPUT_ENTER
	inc di
	mov dl, es:[di]
	cmp dl, 0
	je end_content

output_content:	
	call OUTPUT_SYMBOL
	inc di
	jmp checking
	
end_content:
	add di, 3
	mov dx, offset MODELEPATH
	call OUTPUT
	call OUTPUT_ENTER

output_path:	
	mov dl, es:[di]
	cmp dl, 0
	je end_path
	call OUTPUT_SYMBOL
	inc di
	jmp output_path

end_path:
	ret
OUTPUT_ENVIRONMENTCONTENTS_MODELEPATH ENDP

; КОД
BEGIN:
	call OUTPUT_INACCESSIBLE_MEMORY
	call OUTPUT_ENVIRONMENT_ADDRESS
	call OUTPUT_TAIL
	call OUTPUT_ENVIRONMENTCONTENTS_MODELEPATH
; Выход в DOS
	xor AL,AL
	mov AH,4Ch
	int 21H
LB2 ENDS
 END START 

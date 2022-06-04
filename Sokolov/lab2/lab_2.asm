TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: 
JMP BEGIN
; ДАННЫЕ
MEM db  'Segment address of inaccessible memory:     h', 0Dh, 0Ah, '$'
ENVIRO db 'Segment address of environment:     h', 0Dh, 0Ah, '$'
TAIL db  'Command line tail:', 0Dh, 0Ah, '$'
ENVIRO_CONTENT db 'Contents of the environment area:', 0Dh, 0Ah, '$'
MOD_PATH db 'Path of the loaded module: $'
_S_N db 0Dh, 0Ah, '$' 

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
	mov di, offset MEM
	add di, 43
	mov ax, ds:[2h]
	call WRD_TO_HEX
	mov [di], ax
	mov dx, offset MEM
	call PUTS
	ret
INACCESSIBLE_MEMORY ENDP

ENVIRONMENT_ADDRESS PROC near
	mov di, offset ENVIRO
	add di, 35
	mov ax, ds:[2Ch]
	call WRD_TO_HEX
	mov [di], ax
	mov dx, offset ENVIRO
	call PUTS
	ret
ENVIRONMENT_ADDRESS ENDP

_TAIL PROC near
	mov dx, offset TAIL
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
_TAIL ENDP
	
	
ENVIRONMENTCONTENTS_MODULEPATH PROC near
	mov dx, offset ENVIRO_CONTENT
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
	mov dx, offset MOD_PATH
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
	call _TAIL
	call ENVIRONMENTCONTENTS_MODULEPATH

; Выход в DOS

	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
END START  
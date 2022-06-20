prog segment
	assume cs:prog, ds:prog
	org 100h

begin: jmp main
	
unavailable_mem_adr db 'Unavailable mem address:     h', 0dh, 0ah, '$'
env_adr db 'Env address:     h', 0dh, 0ah, '$'
cmd_tail db 'Cmd tail:        ', 0dh, 0ah, '$'
empty_cmd_tail db 'tail line is empty', 0dh, 0ah, '$'
content db 'Content: $'
module_path db 'Module path:  ', 0dh, 0ah, '$'
_ends db 0dh, 0ah, '$'
	
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


UnAvMem PROC near
    mov ax, ds:[02h]
	lea di, unavailable_mem_adr
    add di, 28
    
	call WRD_TO_HEX
    
	mov dx, offset unavailable_mem_adr
    call PrintProc
    ret
UnAvMem ENDP

EnvAdr PROC near
    mov ax, ds:[2Ch]
    lea di, env_adr
	add di, 16
	
    call WRD_TO_HEX
    
	mov dx, offset env_adr
    call PrintProc
    ret
EnvAdr ENDP

CmdTail PROC near
    
	xor cx, cx
    mov cl, ds:[80h]
    
    lea si, cmd_tail
	add si, 16
    cmp cl, 0h
    je empty_case
    
	xor di, di
    xor ax, ax
    
	tails_content:
        mov al, ds:[81h+di]
        inc di
        mov [si], al
        inc si
        loop tails_content
		mov dx, offset cmd_tail
        jmp print
		
    empty_case:
        mov dx, offset empty_cmd_tail
    print:
        call PrintProc
        ret
		
CmdTail ENDP

EnvCont PROC near

    mov dx, offset content
    call PrintProc
    
	xor di, di
    mov ds, ds:[2Ch]
    
	scan:
        cmp byte ptr [di], 00h
        jz endStr
        mov dl, [di]
        mov ah, 02h
        int 21h
        jmp whereisend
    
	endStr:
        cmp byte ptr [di+1], 00h
        jz whereisend
        push ds
        
		mov cx, cs
        mov ds, cx
        mov dx, offset _ends
        
		call PrintProc
        pop ds
		
    whereisend:
        inc di
        cmp word ptr [di], 001h
        jz scanthepath
        jmp scan
		
    scanthepath:
        push ds
        mov ax, cs
        mov ds, ax
        mov dx, offset module_path
        call PrintProc
        pop ds
        add di, 2
		
    pathloop:
        cmp byte ptr [di], 00h
        jz outC
        mov dl, [di]
        mov ah, 02h
        int 21h
        inc di
        jmp pathloop
		
    outC:
        ret
		
EnvCont ENDP

PrintProc proc near
	mov ah, 09h
	int 21h
	ret
PrintProc endp
	
main:
	
	call UnAvMem
	call EnvAdr
	call CmdTail
	call EnvCont

	xor al,al
	mov AH,4Ch
	int 21H
prog ends
end begin
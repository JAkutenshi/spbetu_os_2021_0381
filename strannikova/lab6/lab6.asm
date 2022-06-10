AStack SEGMENT STACK
	dw 128 dup()
AStack ENDS

DATA SEGMENT
	EPB db 14 dup(0)
	FILE db "File $"
	CTRLC db 0DH,0AH,"Terminated with CTRL+C, code 000$"
	NORMAL_STR db 0DH,0AH,"Terminated with code: 000$"
	NOT_FOUND db " file not found $"
	FILENAME db "lab2.com",0
	PATH db 50 dup(0)
	NEWLINE db 0DH,0AH,'$'
	SAVE_SS dw ?
	SAVE_SP dw ?
DATA ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:NOTHING, SS:AStack
;-------------------------------
BYTE_TO_DEC PROC near
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
PRINT_INFO PROC NEAR 
	push ds
	mov ax,es
	mov ds,ax
	mov ah,02h
loop_mark:
	lodsb
	mov dl,al
	cmp dl,0
	je end_mark
	int 21h
	loop loop_mark
end_mark:
	pop ds
	ret
PRINT_INFO ENDP
;-------------------------------
COPY_FILENAME PROC NEAR 
copy_fn:			
	mov bl,FILENAME[si]
	mov PATH[di],bl
	inc si
	inc di
	cmp bl, 0
	jne copy_fn
	mov si,offset PATH
	ret	
COPY_FILENAME ENDP
;-------------------------------
COPY_DIR_PATH PROC NEAR 
copy_dir:			
	mov bl,es:[si]
	mov PATH[di],bl
	inc si
	inc di
	cmp si, ax
	jne copy_dir
	mov si,0
	ret	
COPY_DIR_PATH ENDP
;-------------------------------
ADD_PATH PROC NEAR 
	add si,3	
	push si
find_slash:
	cmp byte ptr es:[si],'\'
	jne continue
	mov ax,si
	
continue:
	inc si
	cmp byte ptr es:[si],0
	jne find_slash
	inc ax
	pop si
	mov di,0
	ret	
ADD_PATH ENDP
;-------------------------------
MAIN PROC FAR
	mov ax, DATA
	mov ds, ax
	push es
	mov si,0
	mov es, es:[2Ch]
	
env_loop:
	mov al,es:[si]
	inc si
	cmp al,0
	jne env_loop
	mov al,es:[si]
	cmp al,0
	jne env_loop
	
	call ADD_PATH
	call COPY_DIR_PATH
	call COPY_FILENAME
	
; FREE MEM	
	pop es				
	mov bx, offset codeend
	mov ax, es
	sub bx, ax
	mov cl, 4
	shr bx, cl
	mov AH,4ah
	int 21H
	
	jc exit_mark
	
	push ds
	push es
	
	mov word ptr EPB[2], es
	mov word ptr EPB[4], 80h
	
	
	mov ax,ds
	mov es,ax
	mov dx,offset  PATH
	mov bx,offset EPB
	mov SAVE_SS, ss
	mov SAVE_SP, sp
	mov ax, 4B00h
	int 21h
	mov ss, SAVE_SS
	mov sp, SAVE_SP
	
	pop es
	pop ds
	
	jnc noerr
	
	mov ax,ds
	mov es,ax
	mov ah,09h
	mov dx, offset FILE
	int 21h
	mov si, offset PATH
	mov cx, -1
	call PRINT_INFO
	
	mov ah,09h
	mov dx, offset NOT_FOUND
	int 21h
	jmp exit_mark
	
noerr:
	mov ah,4dh
	int 21h	
	cmp ah,0
	je normal
	mov si, offset CTRLC
	add si, 32
	call BYTE_TO_DEC
	
	mov ah,09h
	mov dx, offset CTRLC
	int 21h
	jmp exit_mark
	
normal:	
	mov si, offset NORMAL_STR
	add si, 26
	call BYTE_TO_DEC
	
	mov ah,09h
	mov dx, offset NORMAL_STR
	int 21h
	
exit_mark:
	mov ah,4ch
	int 21h   
	
codeend:	
MAIN ENDP
CODE ENDS
END MAIN
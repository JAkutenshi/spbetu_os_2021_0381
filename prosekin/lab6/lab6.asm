ENV_OFFSET EQU 2Ch
CMD EQU 80h

AStack SEGMENT STACK
	dw 128 dup()
AStack ENDS

DATA SEGMENT
	EPB db 14 dup(0)
	FILE db "File $"
	CTRLC db 0DH,0AH,"Terminated with CTRL+C, code 000$"
	NORMAL_TERMINATE db 0DH,0AH,"Terminated with code: 000$"
	FILE_NOT_FOUND db " not found $"
	FILENAME db "LAB2.com",0
	PATH_FILE db 50 dup(0)
	NEW_LINE db 0DH,0AH,'$'
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
end_l: pop DX
 pop CX
 ret
BYTE_TO_DEC ENDP

PRINTSTR PROC NEAR
push ds
mov ax,es
mov ds,ax
mov ah,02h
_loop:
lodsb
mov dl,al
cmp dl,0
je _end
int 21h
loop _loop
_end:
pop ds

ret
PRINTSTR ENDP


MAIN PROC FAR
	
	mov ax, DATA
	mov ds, ax
	push es
	
	mov si,0
	mov es, es:[ENV_OFFSET]
	_env_loop:
	mov al,es:[si]
	inc si
	cmp al,0
	jne _env_loop
	mov al,es:[si]
	cmp al,0
	jne _env_loop	
	
	add si,3
	push si
	_find_slash:
	cmp byte ptr es:[si],'\'
	jne _continue
	mov ax,si
	_continue:
	inc si
	cmp byte ptr es:[si],0
	jne _find_slash
	inc ax
	pop si
	mov di,0
	_copy_dir:
	mov bl,es:[si]
	mov PATH_FILE[di],bl
	inc si
	inc di
	cmp si, ax
	jne _copy_dir
	mov si,0
	_copy_filename:
	mov bl,FILENAME[si]
	mov PATH_FILE[di],bl
	inc si
	inc di
	cmp bl, 0
	jne _copy_filename
	
	mov si,offset PATH_FILE
	
	pop es
	mov bx, offset _codeend
	mov ax, es
	sub bx, ax
	mov cl, 4
	shr bx, cl
	mov AH,4ah
	int 21H
	
	jc _exit
	
	push ds
	push es
	
	mov word ptr EPB[2], es
	mov word ptr EPB[4], CMD
	
	
	mov ax,ds
	mov es,ax
	mov dx,offset  PATH_FILE
	mov bx,offset EPB
	mov SAVE_SS, ss
	mov SAVE_SP, sp
	mov ax, 4B00h
	int 21h
	mov ss, SAVE_SS
	mov sp, SAVE_SP
	
	pop es
	pop ds
	
	jnc _noerr
	
	mov ax,ds
	mov es,ax
	mov ah,09h
	mov dx, offset FILE
	int 21h
	mov si, offset PATH_FILE
	mov cx, -1
	call PRINTSTR
	
	mov ah,09h
	mov dx, offset FILE_NOT_FOUND
	int 21h
	jmp _exit
	_noerr:
	
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
	jmp _exit
	normal:
	
	mov si, offset NORMAL_TERMINATE
	add si, 26
	call BYTE_TO_DEC
	
	mov ah,09h
	mov dx, offset NORMAL_TERMINATE
	int 21h
	_exit:
	mov ah,4ch
	int 21h   
_codeend:	
MAIN ENDP
CODE ENDS
END MAIN

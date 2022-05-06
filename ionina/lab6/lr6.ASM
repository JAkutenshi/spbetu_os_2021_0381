AStack SEGMENT STACK
	dw 128 dup()
AStack ENDS

DATA SEGMENT
	EPB db 14 dup(0)
	FILE db "File $"
	CCTRL db 0DH,0AH,"Terminated with CTRL+C, code 000$"
	NORM db 0DH,0AH,"Terminated with code: 000$"
    NAMEFILE db "LR2.com",0
	NOT_FOUND db " Not found $"
	PATH db 50 dup(0)
	NEWLINE db 0DH,0AH,'$'
	SAVE_SS dw ?
	SAVE_SP dw ?
DATA ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:NOTHING, SS:AStack

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

NAMEFILE_COPY PROC NEAR 
clone_name:			
	mov bl,NAMEFILE[si]
	mov PATH[di],bl
	inc si
	inc di
	cmp bl, 0
	jne clone_name
	mov si,offset PATH
	ret	
NAMEFILE_COPY ENDP

DIR_PATH_COPY PROC NEAR 
clone_p:			
	mov bl,es:[si]
	mov PATH[di],bl
	inc si
	inc di
	cmp si, ax
	jne clone_p
	mov si,0
	ret	
DIR_PATH_COPY ENDP

PATH_ADD PROC NEAR 
	add si,3	
	push si
flag_sl:
	cmp byte ptr es:[si],'\'
	jne go_on
	mov ax,si
	
go_on:
	inc si
	cmp byte ptr es:[si],0
	jne flag_sl
	inc ax
	pop si
	mov di,0
	ret	
PATH_ADD ENDP


WRITE PROC NEAR 
	push ds
	mov ax,es
	mov ds,ax
	mov ah,02h

m_loop:
	lodsb
	mov dl,al
	cmp dl,0
	je endll
	int 21h
	loop m_loop

endll:
	pop ds
	ret

WRITE ENDP

MAIN PROC FAR
	mov ax, DATA
	mov ds, ax
	push es
	mov si,0
	mov es, es:[2Ch]
	
loop_e:
	mov al,es:[si]
	inc si
	cmp al,0
	jne loop_e
	mov al,es:[si]
	cmp al,0
	jne loop_e
	
	call PATH_ADD
	call DIR_PATH_COPY
	call NAMEFILE_COPY
	
	pop es				
	mov bx, offset endl
	mov ax, es
	sub bx, ax
	mov cl, 4
	shr bx, cl
	mov AH,4ah
	int 21H
	
	jc exit
	
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
	
	jnc no_err
	mov ax,ds
	mov es,ax
	mov ah,09h
	mov dx, offset FILE
	int 21h
	mov si, offset PATH
	mov cx, -1
	call WRITE
	
	mov ah,09h
	mov dx, offset NOT_FOUND
	int 21h
	jmp exit
	
no_err:
	mov ah,4dh
	int 21h	
	cmp ah,0
	je f_normal
	mov si, offset CCTRL
	add si, 32
	call BYTE_TO_DEC
	
	mov ah,09h
	mov dx, offset CCTRL
	int 21h
	jmp exit
	
f_normal:	
	mov si, offset NORM
	add si, 26
	call BYTE_TO_DEC
	mov ah,09h
	mov dx, offset NORM
	int 21h
	
exit:
	mov ah,4ch
	int 21h   
	
endl:	
MAIN ENDP
CODE ENDS
END MAIN
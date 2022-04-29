CODE SEGMENT
ASSUME CS:CODE, DS:DATA, ES:NOTHING, SS:AStack

INTERRUPT PROC FAR
 	jmp start
 	PSP dw ?
 	KEEP_IP dw ?
 	KEEP_CS dw ?
 	ID dw 3452h
 	KEEP_SS dw ?
 	KEEP_SP dw ?
 	KEEP_AX dw ?
 	REQ_KEY db 3bh
 	dw 32 dup()
 	STACK_END dw ? 
 	
 	start:
 	mov KEEP_SS, ss
 	mov KEEP_SP, sp
 	mov KEEP_AX, ax
 	mov ax, cs
 	mov ss, ax
 	mov sp, offset STACK_END
 	push bx
 	push cx
 	push dx
 	push di
 	push bp
 	push ds
 	in al,60h
        cmp al,REQ_KEY
        je do
        call dword ptr cs:KEEP_IP
        jmp _end_

 	do:
 	in al,61H 
 	mov ah,al 
 	or al,80h 
 	out 61H,al
 	xchg ah,al
 	out 61H,al
 	mov al,20H
 	out 20H,al
  
 	do_again:
 	mov ah,05h 
 	mov cl,'K' 
 	mov ch,00h 
 	int 16h 
 	or al,al 
 	jz _end_
 	mov ah,0ch
 	mov al,00h
 	int 21h
 	jmp do_again

 	_end_: 		
 	pop ds
 	pop bp
 	pop di
 	pop dx
 	pop cx
 	pop bx
 	mov ax, KEEP_AX
 	mov ss, KEEP_SS
 	mov sp, KEEP_SP
 	mov al, 20h
 	out 20h, al
 	iret
 	endl:	
INTERRUPT ENDP

LOADING proc near
 	mov PSP,es
 	MOV AH, 35H 
 	MOV AL, 09H 
 	INT 21H
 	MOV KEEP_IP, BX 
 	MOV KEEP_CS, ES 

 	PUSH DS
 	MOV DX, OFFSET INTERRUPT 
 	MOV AX, SEG INTERRUPT 
 	MOV DS, AX 
 	MOV AH, 25H 
 	MOV AL, 09H
 	INT 21H 
 	POP DS
 	
 	mov DX, offset endl 
 	mov cl,4
 	shr dx,cl
 	inc dx
 	mov ax,cs
        sub ax,PSP
        add dx,ax
 	mov al,0
 	mov AH,31h
 	
 	int 21h
 	ret
LOADING endp

CHECK_FLAG proc 
 	mov si,0
 	flag:
 	mov bl, es:[81h+si]
 	cmp bl, UNLOADFLAG[si]
 	jne false
 	inc si
 	cmp UNLOADFLAG[si], 0dh
 	je true
 	jmp flag
 	
 	true:
 	mov ax, si
 	cmp al, es:[80h]
 	jne false
 	mov al,1
 	ret

 	false:
 	mov al,0
 	ret
CHECK_FLAG endp

ISLOADED proc
 	push bx
 	push es
 	mov ah,35h
 	mov al,09h
 	int 21h
 	
 	mov ax, es:[ID]
 	cmp ax, 3452h
 	je done
 	mov al,0
 	pop es
 	pop bx
 	ret

 	done:
 	mov al,1
 	pop es
 	pop bx
 	ret
ISLOADED endp


UNLOADING proc 
 	CLI
 	PUSH DS
 	MOV DX, es:[KEEP_IP]
 	MOV AX, es:[KEEP_CS]
 	MOV DS, AX
 	MOV AH, 25H
 	MOV AL, 09H
 	INT 21H
 	POP DS
 	STI
 	
 	mov ax, es:[PSP]	
 	mov es, ax
 	push es
 	mov ax, es:[2ch]
 	mov es,ax
 	mov ah,49h
 	int 21h
 	pop es
 	int 21h
 	ret
UNLOADING endp


MAIN PROC FAR
 	mov ax, DATA
 	mov ds, ax
 	
 	call CHECK_FLAG
 	mov bx, ax	
 	call ISLOADED
 	cmp al,0
 	je not_done
 	cmp bl, 0 
 	jne unload
 	mov ah,09h
 	mov dx, offset ALREADY_LOADED_STR
 	int 21h
 	jmp finish
 	
 	not_done:
 	cmp bl, 0 
 	je load
 	mov ah,09h
 	mov dx, offset NOTLOADED_STR
 	int 21h 
 	jmp finish
 	
 	
 	unload:
 	mov ah,09h
 	mov dx, offset UNLOADING_STR
 	int 21h
 	
 	mov ah,35h
 	mov al,09h
 	int 21h
 	call UNLOADING
 	jmp finish

 	load:
 	mov ah,09h
 	mov dx, offset LOADING_STR
 	int 21h
 	call LOADING

 	finish:
 	mov ah,4ch
 	int 21h    
MAIN ENDP
CODE ENDS


AStack SEGMENT STACK
 	dw 128 dup()
AStack ENDS

DATA SEGMENT
 	UNLOADFLAG db " /un",0dh
 	LOADING_STR db "Loading...",0Dh,0Ah,'$'
 	NOTLOADED_STR db "Not loaded",0Dh,0Ah,'$'
 	ALREADY_LOADED_STR db "Already loaded",0Dh,0Ah,'$'
 	UNLOADING_STR db "Unloading...",0Dh,0Ah,'$'
DATA ENDS

END MAIN

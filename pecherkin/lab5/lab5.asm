;ПРОЦЕДУРЫ
;-----------------------------------------------------


CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:NOTHING, SS:AStack


INTERRUPT PROC FAR
	jmp int_start
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
	
	int_start:
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
    je do_req
    call dword ptr cs:KEEP_IP
    jmp end_int
	do_req:
	
	in al,61H 
	mov ah,al 
	or al,80h 
	out 61H,al
	xchg ah,al
	out 61H,al
	mov al,20H
	out 20H,al
 
	try_again:
	mov ah,05h 
	mov cl,'D' 
	mov ch,00h 
	int 16h 
	or al,al 
	jz end_int
	mov ah,0ch
	mov al,00h
	int 21h
	jmp try_again
	end_int:
		
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
	int_end:	
INTERRUPT ENDP

LOAD proc near
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
	
	mov DX, offset int_end ; размер в байтах 
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
LOAD endp

CHECK_FLAG proc 
	mov si,0
	_flagloop:
	mov bl, es:[81h+si]
	cmp bl, UNLOADFLAG[si]
	jne ret_false
	inc si
	cmp UNLOADFLAG[si], 0dh
	je ret_true
	
	jmp _flagloop
	
	ret_true:
	mov ax, si
	cmp al, es:[80h]
	jne ret_false
	mov al,1
	ret
	ret_false:
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
	je loaded
	mov al,0
	pop es
	pop bx
	ret
	loaded:
	mov al,1
	pop es
	pop bx
	ret
ISLOADED endp


UNLOAD proc 

	CLI
	PUSH DS
	MOV DX, es:[KEEP_IP]
	MOV AX, es:[KEEP_CS]
	MOV DS, AX
	MOV AH, 25H
	MOV AL, 09H
	INT 21H ; восстанавливаем вектор
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
UNLOAD endp




;-------------------------------
; КОД
MAIN PROC FAR
	mov ax, DATA
	mov ds, ax
	
	call CHECK_FLAG
	mov bx, ax	
	call ISLOADED

	cmp al,0
	je notloaded
	
	cmp bl, 0 
	jne _unload
	mov ah,09h
	mov dx, offset ALREADY_LOADED_STR
	int 21h
	jmp _end
	
	notloaded:
	cmp bl, 0 
	je _load
	mov ah,09h
	mov dx, offset NOTLOADED_STR
	int 21h 
	jmp _end
	
	
	_unload:
	mov ah,09h
	mov dx, offset UNLOADING_STR
	int 21h
	
	mov ah,35h
	mov al,09h
	int 21h
	call UNLOAD
	jmp _end
	_load:
	
	mov ah,09h
	mov dx, offset LOADING_STR
	int 21h
	call LOAD
	_end:
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

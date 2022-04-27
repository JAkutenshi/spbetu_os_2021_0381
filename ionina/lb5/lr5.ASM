;----------------------------------------------------
CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:NOTHING, SS:AStack
;-----------------------------------------------------

INTERRUPTION PROC FAR
	jmp begin

	PSP dw ?
	IP_KEEP dw ?
	CS_KEEP dw ?
	ID dw 3452h
	SS_KEEP dw ?
	SP_KEEP dw ?
	AX_KEEP dw ?
	REQ_KEY db 3bh
	dw 32 dup()
	END_STACK dw ? 
	
	begin:
	mov SS_KEEP, ss
	mov SP_KEEP, sp
	mov AX_KEEP, ax
	mov ax, cs
	mov ss, ax
	mov sp, offset END_STACK
	
	push bx
	push cx
	push dx
	push di
	push bp
	push ds
	
	in al,60h
	
    	cmp al,REQ_KEY
   	je req_start
    	call dword ptr cs:IP_KEEP
    	jmp endl_int

	req_start:
	in al,61H 
	mov ah,al 
	or al,80h 
	out 61H,al
	xchg ah,al
	out 61H,al
	mov al,20H
	out 20H,al
 
	once_more:
	mov ah,05h 
	mov cl,'A' 
	mov ch,00h 
	int 16h 
	or al,al 
	jz endl_int
	mov ah,0ch
	mov al,00h
	int 21h
	jmp once_more

	endl_int:	
	pop ds
	pop bp
	pop di
	pop dx
	pop cx
	pop bx
	
	mov ax, AX_KEEP
	mov ss, SS_KEEP
	mov sp, SP_KEEP
	
	mov al, 20h
	out 20h, al
	iret
	endl:	
INTERRUPTION ENDP

LOADING proc near
	mov PSP,es
	MOV AH, 35H 
	MOV AL, 09H 
	INT 21H

	MOV IP_KEEP, BX 
	MOV CS_KEEP, ES 

	PUSH DS
	MOV DX, OFFSET INTERRUPTION 
	MOV AX, SEG INTERRUPTION 
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

MARKER proc 
	mov si,0

	loop_mark:
	mov bl, es:[81h+si]
	cmp bl, STR_NOMARKER[si]
	jne false
	inc si
	cmp STR_NOMARKER[si], 0dh
	je true
	jmp loop_mark
	
	true:
	mov ax, si
	cmp al, es:[80h]
	jne false
	mov al,1
	ret
	false:
	mov al,0
	ret
MARKER endp


IS_LOADING proc
	push bx
	push es
	mov ah,35h
	mov al,09h
	int 21h
	mov ax, es:[ID]
	cmp ax, 3452h
	je load_l
	mov al,0
	pop es
	pop bx
	ret

	load_l:
	mov al,1
	pop es
	pop bx
	ret
IS_LOADING endp


UNLOADING proc 
	CLI
	PUSH DS
	MOV DX, es:[IP_KEEP]
	MOV AX, es:[CS_KEEP]
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
;--------------------------------------------
MAIN PROC FAR
	mov ax, DATA
	mov ds, ax
	call MARKER
	mov bx, ax	
	call IS_LOADING
	cmp al,0
	je no_load
	
	cmp bl, 0 
	jne unloading_m
	mov ah,09h
	mov dx, offset STR_IS_LOADING
	int 21h
	jmp endll
	
	no_load:
	cmp bl, 0 
	je load
	mov ah,09h
	mov dx, offset STR_NO_LOADING
	int 21h 
	jmp endll
	
	
	unloading_m:
	mov ah,09h
	mov dx, offset STR_UNLOADINGING
	int 21h
	mov ah,35h
	mov al,09h
	int 21h
	call UNLOADING
	jmp endll

	load:
	mov ah,09h
	mov dx, offset STR_LOADING
	int 21h
	call LOADING
	endll:
	mov ah,4ch
	int 21h    
MAIN ENDP
CODE ENDS

AStack SEGMENT STACK
	dw 128 dup()
AStack ENDS

DATA SEGMENT
	STR_NOMARKER db " /un",0dh
	STR_LOADING db "Interrupt is loaded",0Dh,0Ah,'$'
    STR_IS_LOADING db "Interrupt already loaded",0Dh,0Ah,'$'
    STR_UNLOADINGING db "Interrupt is unloaded",0Dh,0Ah,'$'
	STR_NO_LOADING db "Interrupt isn`t loaded",0Dh,0Ah,'$'
DATA ENDS
END MAIN

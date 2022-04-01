MY_STACK SEGMENT STACK
	DW 64 DUP(?)
MY_STACK ENDS

DATA SEGMENT
	INT_NOT_LOAD DB 'Interruption did not load.', 0dh, 0ah, '$'
	INT_IS_UNLOADED DB 'Interruption was unloaded.', 0dh, 0ah, '$'
	INT_LOADED DB 'Interruption has already loaded.', 0dh, 0ah, '$'
	INT_IS_LOADING DB 'Interruption is loading.', 0dh, 0ah, '$'
DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE, DS:DATA, SS:MY_STACK

WRITE_STRING proc near
    push ax
    mov ah, 9h
    int 21h
    pop ax
    ret
WRITE_STRING endp


start:
ROUT proc far
    jmp start_proc
    SAVED_PSP DW 0
    SAVED_IP DW 0
   	SAVED_CS DW 0
    SAVED_SS DW 0
	SAVED_SP DW 0
	SAVED_AX DW 0

    INDEX DW 1337h
    TIMER DB 'Timer: 0000$'
    BStack DW 64 DUP(?)
start_proc:
    mov SAVED_SP, sp
    mov SAVED_AX, ax
    mov ax, ss
    mov SAVED_SS, ss

    mov ax, SAVED_AX

    mov sp, offset start_proc

    mov ax, seg BStack
    mov ss, ax

    push bx
   	push cx
   	push dx

    mov ah,3h
	mov bh,0h
	int 10h
    push dx

    push si
    push cx
    push ds
    push ax
    push bp

    mov ax, SEG TIMER
    mov ds,ax
    mov si, offset TIMER

    add si, 6
    mov cx, 4

timer_inc:
    mov bp, cx
    mov ah, [si+bp]
    inc ah
    cmp ah, 3ah
    jl timer_inc_end
    mov ah, 30h
    mov [si+bp], ah

    loop timer_inc

timer_inc_end:
    mov [si+bp], ah

    pop bp
    pop ax
    pop ds
    pop cx
    pop si

    push es
	push bp

    mov ax, SEG TIMER
	mov es,ax
	mov ax, offset TIMER
	mov bp,ax
	mov ah,13h
	mov al,00h
    mov dh,02h
   	mov dl,09h
	mov cx,11
	mov bh,0
	int 10h

	pop bp
	pop es

	;return cursor
	pop dx
	mov ah,02h
	mov bh,0h
	int 10h

	pop dx
	pop cx
	pop bx

    mov SAVED_AX, ax
    mov sp, SAVED_SP
    mov ax, SAVED_SS
    mov ss, ax
    mov ax, SAVED_AX

    mov al, 20H
    out 20H, al

    iret
end_rout:
ROUT endp

IF_NEED_UNLOAD proc near
   	push ax
    push es

   	mov al,es:[81h+1]
   	cmp al,'/'
   	jne end_if_need_unload

   	mov al,es:[81h+2]
   	cmp al,'u'
   	jne end_if_need_unload

   	mov al,es:[81h+3]
   	cmp al,'n'
   	jne end_if_need_unload

    mov cl,1h

end_if_need_unload:
    pop es
   	pop ax
   	ret
IF_NEED_UNLOAD endp


LOAD_ROUT PROC near
   	push ax
   	push dx

    mov SAVED_PSP, es

   	mov ah,35h
	mov al,1ch
	int 21h
    mov SAVED_IP, bx
    mov SAVED_CS, es

   	push ds
   	lea dx, ROUT
   	mov ax, SEG ROUT
   	mov ds,ax
   	mov ah,25h
   	mov al,1ch
   	int 21h
   	pop ds

   	lea dx, end_rout
   	mov cl,4h
   	shr dx,cl
   	inc dx
   	add dx,100h
    xor ax, ax
   	mov ah,31h
   	int 21h

   	pop dx
   	pop ax
   	ret
LOAD_ROUT endp

UNLOAD_ROUT PROC near
   	push ax
   	push si

    cli
   	push ds
   	mov ah,35h
	mov al,1ch
    int 21h

    mov si,offset SAVED_IP
    sub si,offset ROUT
    mov dx,es:[bx+si]
	mov ax,es:[bx+si+2]
    mov ds,ax
    mov ah,25h
    mov al,1ch
    int 21h
    pop ds

    mov ax,es:[bx+si-2]
    mov es,ax
    push es

    mov ax,es:[2ch]
    mov es,ax
    mov ah,49h
    int 21h

    pop es
    mov ah,49h
    int 21h
    sti

    pop si
    pop ax
    ret
UNLOAD_ROUT endp

IF_LOADED proc near
   	push ax
   	push si

    push es
    push dx

   	mov ah,35h
   	mov al,1ch
   	int 21h

   	mov si, offset INDEX
   	sub si, offset ROUT
   	mov dx,es:[bx+si]
   	cmp dx, INDEX
   	jne end_if_loaded
   	mov ch,1h

end_if_loaded:
    pop dx
    pop es
   	pop si
   	pop ax
   	ret
IF_LOADED ENDP

MAIN proc far
    push  DS
    push  AX
    mov   AX,DATA
    mov   DS,AX

    call IF_NEED_UNLOAD
    cmp cl, 1h
    je need_unload

    call IF_LOADED
    cmp ch, 1h
    je print_rout_is_already_set
    mov dx, offset INT_IS_LOADING
    call WRITE_STRING
    call LOAD_ROUT
    jmp exit

need_unload:
    call IF_LOADED
    cmp ch, 1h
    jne print_rout_cant_be_unloaded
    call UNLOAD_ROUT
    mov dx, offset INT_IS_UNLOADED
    call WRITE_STRING
    jmp exit

print_rout_cant_be_unloaded:
    mov dx, offset INT_NOT_LOAD
    call WRITE_STRING
    jmp exit
print_rout_is_already_set:
    mov dx, offset INT_LOADED
    call WRITE_STRING
    jmp exit

exit:
    mov ah, 4ch
    int 21h
MAIN endp
CODE ends
END Main
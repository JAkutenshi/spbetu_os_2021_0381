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
    interruption_stack DW 64 DUP(?)
start_proc:
    mov SAVED_SP, sp
    mov SAVED_AX, ax
    mov SAVED_SS, ss

    mov ax, seg interruption_stack
    mov ss, ax
    mov ax, offset start_proc
    mov sp, ax

    mov ax, SAVED_AX
    
    push bx
   	push cx
   	push dx
    push si
    push cx
    push ds
    push ax

    in al, 60h
    cmp al, 18h
    je key_o
    cmp al, 19h
    je key_p
standart:
    call dword ptr cs:[SAVED_IP] ;идем к стандартному обработчику
    jmp end_rout
key_o:
    mov al, 'a'
    jmp do_req
key_p:
    mov al, 'q'

do_req:
    push ax
    in al, 61h
    mov ah, al
    or al, 80h
    out 61h, al
    xchg ah, al
    out 61h, al
    mov al, 20H
    out 20h, al
    pop ax

read_symbol:
    mov ah, 05h
    mov cl, al
    mov ch, 00h
    int 16h
    or al, al
    jz end_rout
    mov ax, 40h
    mov es, ax
    mov ax, es:[1ah]
    mov es:[1ch], ax
    jmp read_symbol

end_rout:
    pop ds
    pop es
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
	mov sp, SAVED_SP
	mov ax, SAVED_SS
	mov ss, ax
	mov ax, SAVED_AX
	mov al, 20h
	out 20h, al
	iret
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
	mov al, 09h
	int 21h
    mov SAVED_IP, bx
    mov SAVED_CS, es

   	push ds
   	lea dx, ROUT
   	mov ax, SEG ROUT
   	mov ds,ax
   	mov ah,25h
   	mov al,09h
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
	mov al,09h
    int 21h

    mov si,offset SAVED_IP
    sub si,offset ROUT
    mov dx,es:[bx+si]
	mov ax,es:[bx+si+2]
    mov ds,ax
    mov ah,25h
    mov al,09h
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
   	mov al,09h
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
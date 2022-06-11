AStack SEGMENT  STACK
          DW 256 DUP(?)
AStack ENDS

DATA SEGMENT
	LOAD_BOOL DB 0
	UNLOAD_BOOL DB 0
	LOAD_OUT db "User interrupt has loaded.$"
	LOAD_ALR_OUT db "User interrupt already loaded.$"
	UNLOAD_OUT db "User interrupt has unloaded.$"
	NONLOAD_OUT db "User interrupt is not loaded.$"
DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE, DS:DATA, SS:AStack
;-------------------------------
PRINT_STRING PROC NEAR
    	push ax
    	mov ah, 09h
    	int 21h
    	pop ax
	ret
PRINT_STRING ENDP
;-------------------------------
INTERRUPT PROC FAR
	jmp inter_str

inter_data:
	keep_ip DW 0
	keep_cs DW 0
	keep_psp DW 0
	keep_ax DW 0
	keep_ss DW 0
	keep_sp DW 0
	interrupt_stack DW 256 DUP(0)
	key DB 0
	sign DW 1234h

inter_str:
	mov keep_ax, ax
	mov keep_sp, sp
	mov keep_ss, ss
	mov ax, seg interrupt_stack
	mov ss, ax
	mov ax, offset interrupt_stack
	add ax, 256
	mov sp, ax
	
    	push ax
    	push bx
   	push cx
    	push dx
    	push si
    	push es
    	push ds

	mov ax, seg key
	mov ds, ax
    
	in al, 60h
    	cmp al, 20h	
    	je key_d
    	cmp al, 11h
    	je key_w
    	cmp al, 23h
    	je key_h

	pushf
	call dword ptr cs:keep_ip
	jmp inter_fnsh

key_d:
    	mov key, '!'
    	jmp next
key_w:
    	mov key, '$'
    	jmp next
key_h:
    	mov key, '#'

next:
    	in al, 61h
    	mov ah, al
    	or al, 80h
    	out 61h, al
    	xchg al, al
    	out 61h, al
    	mov al, 20h
    	out 20h, al
  
cout_key:
    	mov ah, 05h
    	mov cl, key
    	mov ch, 00h
    	int 16h
    	or al, al
    	jz inter_fnsh
    	mov ax, 0040h
    	mov es, ax
    	mov ax, es:[1ah]
    	mov es:[1ch], ax
    	jmp cout_key

inter_fnsh:
    	pop ds
    	pop es
    	pop si
    	pop dx
    	pop cx
    	pop bx
    	pop ax

	mov sp, keep_sp
	mov ax, keep_ss
	mov ss, ax
	mov ax, keep_ax
	mov al, 20h
	out 20h, al

	iret

INTERRUPT endp
;-------------------------------
END_I:

CHECK_LOAD PROC NEAR
	push ax
	push bx
	push si
	mov ah, 35h
	mov al, 09h
	int 21h

	mov si, offset sign
	sub si, offset INTERRUPT
	mov ax, es:[bx + si]
	cmp ax, sign
	jne load_end
	mov LOAD_BOOL, 1
    
load_end:
	pop  si
	pop  bx
	pop  ax

	ret

CHECK_LOAD ENDP
;-------------------------------
CHECK_UNLOAD PROC NEAR
    	push ax
    	push es
   	mov ax, keep_psp
   	mov es, ax
    	cmp byte ptr es:[82h], '/'
    	jne check_end
    	cmp byte ptr es:[83h], 'u'
    	jne check_end
    	cmp byte ptr es:[84h], 'n'
    	jne check_end
    	mov UNLOAD_BOOL, 1
 
check_end:
    	pop es
   	pop ax

	ret

CHECK_UNLOAD ENDP
;-------------------------------
INTERRUPT_LOAD PROC NEAR
	push ax
	push bx
	push cx
	push dx
	push ds
	push es

 	mov ah, 35h
    	mov al, 09h
    	int 21h
   	mov keep_cs, es
    	mov keep_ip, bx
    	mov ax, seg INTERRUPT
    	mov dx, offset INTERRUPT
    	mov ds, ax
    	mov ah, 25h
    	mov al, 09h

    	int 21h

    	pop ds

    	mov dx, offset END_I
    	mov cl, 4h
    	shr dx, cl
    	add dx, 10fh
    	inc dx
    	xor ax, ax
    	mov ah, 31h
    	int 21h

    	pop es
    	pop dx
    	pop cx
    	pop bx
    	pop ax

	ret
INTERRUPT_LOAD ENDP
;-------------------------------
INTERRUPT_UNLOAD PROC NEAR
   	cli
    	push ax
    	push bx
   	push dx
    	push ds
    	push es
    	push si
    
    	mov ah, 35h
    	mov al, 09h
    	int 21h
    	mov si, offset keep_ip
    	sub si, offset INTERRUPT
    	mov dx, es:[bx+si]
    	mov ax, es:[bx+si+2]
 
    	push ds
    	mov ds, ax
    	mov ah, 25h
    	mov al, 09h
    	int 21h
    	pop ds
    
    	mov ax, es:[bx+si+4]
    	mov es, ax
    	push es
    	mov ax, es:[2ch]
    	mov es, ax
    	mov ah, 49h
    	int 21h
    	pop es
    	mov ah, 49h
    	int 21h
    
    	sti
    
    	pop si
    	pop es
    	pop ds
    	pop dx
    	pop bx
    	pop ax
 
	ret

INTERRUPT_UNLOAD ENDP
;-------------------------------
BEGIN PROC
    	push ds
    	xor ax, ax
   	push ax

    	mov ax, data
    	mov ds, ax
    	mov keep_psp, es
    
    	call CHECK_LOAD
    	call CHECK_UNLOAD
    	cmp UNLOAD_BOOL, 1
    	je unload
    	mov al, LOAD_BOOL
    	cmp al, 1
    	jne load
    	mov dx, offset LOAD_ALR_OUT
    	call PRINT_STRING
    	jmp begin_end

load:
    	mov dx, offset LOAD_OUT
    	call PRINT_STRING
    	call INTERRUPT_LOAD
    	jmp  begin_end

unload:
    	cmp  LOAD_BOOL, 1
    	jne  not_loaded
    	mov dx, offset UNLOAD_OUT
    	call PRINT_STRING
    	call INTERRUPT_UNLOAD
    	jmp  begin_end

not_loaded:
    	mov  dx, offset NONLOAD_OUT
    	call PRINT_STRING

begin_end:
    	xor al, al
    	mov ah, 4ch
    	int 21h

BEGIN ENDP
CODE ENDS
END BEGIN 
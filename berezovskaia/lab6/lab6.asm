MY_STACK SEGMENT STACK
	DW 64 DUP(?)
MY_STACK ENDS

DATA SEGMENT
	params_block dw 0
                dd 0
                dd 0
                dd 0

    file_name db "LAB2.COM", 0
    SAVED_PSP dw 0
    SAVED_SP dw 0
    SAVED_SS dw 0

    new_command_line db 1h,0DH
    path_ db 128 dup(0)

    FREE_MEM_SUCСESS db "Memory is free ", 0DH, 0AH, '$'
    CONTROL_BLOCK_ERROR db "Control block was destroyed ", 0DH, 0AH, '$'
    FUNCTION_MEM_ERROR db "Not enough memory for function ", 0DH, 0AH, '$'
    WRONG_ADDRESS db "Wrong address for block of memory", 0DH, 0AH, '$'

    WRONG_NUMBER_ERROR db "Wrong function number ", 0DH, 0AH, '$'
    CANT_FIND_ERROR db "Can not find file ", 0DH, 0AH, '$'
    DISK_ERROR db "Erorror on disk ", 0DH, 0AH, '$'
    MEMORY_ERROR db "Not enough memory ", 0DH, 0AH, '$'
    WRONG_STRING_ERROR db "Wrong environment string ", 0DH, 0AH, '$'
    WRONG_FORMAT_ERROR db "Wrong format ", 0DH, 0AH, '$'

    NORMAL_END db 0DH, 0AH, "End code is:  ", 0DH, 0AH, '$'
    BREAK_END db 0DH, 0AH, "End by ctrl+break ", 0DH, 0AH, '$'
    ERROR_END db 0DH, 0AH, "End by device error ", 0DH, 0AH, '$'
    FUNCTION_END db 0DH, 0AH, "End by function 31h", 0DH, 0AH, '$'

    ERR_FLAG db 0

    DATA_END db 0
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

FREE_MEM PROC near
    push ax
    push bx
    push dx
    push cx
    
    mov ax, offset DATA_END
    mov bx, offset PROC_END
    add bx, ax
    mov cl, 4
    shr bx, cl
    add bx, 2bh

    mov ah, 4ah
    int 21h

    jnc FMS
    mov ERR_FLAG, 1

    cmp ax, 7
    je CBE
    cmp ax, 8
    je FME
    cmp ax, 9
    je WA

CBE:
    mov dx, offset CONTROL_BLOCK_ERROR
    call WRITE_STRING
    jmp FREE_MEM_END
FME:
    mov dx, offset FUNCTION_MEM_ERROR
    call WRITE_STRING
    jmp FREE_MEM_END
WA:
    mov dx, offset WRONG_ADDRESS
    call WRITE_STRING
    jmp FREE_MEM_END
FMS:
    mov dx, offset FREE_MEM_SUCСESS
    call WRITE_STRING
    
FREE_MEM_END:
    pop cx
    pop dx
    pop bx
    pop ax
    ret
FREE_MEM ENDP

PATH PROC 
	push ax
	push bx
	push cx 
	push dx
	push di
	push si
	push es
	
	mov ax, SAVED_PSP
	mov es, ax
	mov es, es:[2ch]
	mov bx, 0
	
find_path:
	inc bx
	cmp byte ptr es:[bx-1], 0
	jne find_path
	cmp byte ptr es:[bx+1], 0 
	jne find_path	
	add bx, 2
	mov di, 0
	
find_loop:
	mov dl, es:[bx]
	mov byte ptr [path_ + di], dl
	inc di
	inc bx
	cmp dl, 0
	je end_find_loop
	cmp dl, '\'
	jne find_loop
	mov cx, di
	jmp find_loop

end_find_loop:
	mov di, cx
	mov si, 0
	
end_f:
	mov dl, byte ptr [file_name + si]
	mov byte ptr [path_ + di], dl
	inc di 
	inc si
	cmp dl, 0 
	jne end_f
		
	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax

	ret
PATH ENDP



LOAD PROC
    push ax
	push bx
	push cx
	push dx
	push ds
	push es
	
	mov SAVED_SP, sp
	mov SAVED_SS, ss	
	mov ax, DATA
	mov es, ax
    mov bx, offset params_block
	mov dx, offset new_command_line
	mov [bx+2], dx
	mov [bx+4], ds 
	mov dx, offset path_
	mov ax, 4b00h
	int 21h 
	
	mov ss, SAVED_SS
	mov sp, SAVED_SP
	pop es
	pop ds

    jnc LOAD_SUCCESS
    cmp ax, 1
    je E_1
    cmp ax, 2
    je E_2
    cmp ax, 5
    je E_5
    cmp ax, 8
    je E_8
    cmp ax, 10
    je E_10
    cmp ax, 11
    je E_11
E_1:
    mov dx, offset WRONG_NUMBER_ERROR
    call WRITE_STRING
    jmp LOAD_END
E_2:
    mov dx, offset CANT_FIND_ERROR
    call WRITE_STRING
    jmp LOAD_END
E_5:
    mov dx, offset DISK_ERROR
    call WRITE_STRING
    jmp LOAD_END
E_8:
    mov dx, offset MEMORY_ERROR
    call WRITE_STRING
    jmp LOAD_END
E_10:
    mov dx, offset WRONG_STRING_ERROR
    call WRITE_STRING
    jmp LOAD_END
E_11:
    mov dx, offset WRONG_FORMAT_ERROR
    call WRITE_STRING
    jmp LOAD_END

LOAD_SUCCESS:
    mov ah, 4dh
    mov al, 00h
    int 21h

    cmp ah, 0
    je NEND
    cmp ah, 1
    je BEND
    cmp ah, 2
    je EEND
    cmp ah, 3
    je FEND
NEND:
    mov di, offset NORMAL_END
    add di, 15
    mov [di], al
    mov dx, offset NORMAL_END
    call WRITE_STRING
    jmp LOAD_END

BEND:
    mov dx, offset BREAK_END
    call WRITE_STRING
    jmp LOAD_END
EEND:
    mov dx, offset ERROR_END
    call WRITE_STRING
    jmp LOAD_END
FEND:
    mov dx, offset FUNCTION_END
    call WRITE_STRING

LOAD_END:
	pop dx
	pop cx
	pop bx
	pop ax
    ret
LOAD ENDP

MAIN PROC far
    push dx
    push ax
    mov ax, DATA
    mov ds, ax
    mov SAVED_PSP, es

    call FREE_MEM
    cmp ERR_FLAG, 1
    je MAIN_END
    call PATH
    call LOAD

MAIN_END:
    xor al, al
    mov ah, 4ch
    int 21h

PROC_END:
MAIN endp
CODE ends
END Main
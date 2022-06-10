MY_STACK SEGMENT STACK
	DW 64 DUP(?)
MY_STACK ENDS

DATA SEGMENT
	params_block dw 0
                dd 0
                dd 0
                dd 0
    new_command_line db 1h,0DH
    path_ db 128 dup(0)
    overlay_address dd 0
    file_overlay1 db "overlay1.ovl", 0
    file_overlay2 db "overlay2.ovl", 0
    SAVED dw 0
    cur_overlay dw 0
    SAVED_SP dw 0
    SAVED_SS dw 0
    DTA db 43 dup(0); Буффер для DTA
    SAVED_PSP dw 0

    FREE_MEM_SUCСESS db "Memory is free", 0DH, 0AH, '$'
    CONTROL_BLOCK_ERROR db "Control block was destroyed", 0DH, 0AH, '$'
    FUNCTION_MEM_ERROR db "Not enough memory for function", 0DH, 0AH, '$'
    WRONG_ADDRESS db "Wrong address for block of memory", 0DH, 0AH, '$'

    WRONG_NUMBER_ERROR db "Wrong function number", 0DH, 0AH, '$'
    CANT_FIND_ERROR db "Can not find file 1", 0DH, 0AH, '$'
    PATH_ERROR db "Can not find path 1", 0DH, 0AH, '$'
    OPEN_ERROR db "Too much oppened files", 0DH, 0AH, '$'
    ACCESS_ERROR db "No access for file", 0DH, 0AH, '$'
    NOT_ENOUGH_MEM_ERROR db "Not enough memory", 0DH, 0AH, '$'
    ENVIRONMENT_ERROR db "Wrong environment", 0DH, 0AH, '$'

    CANT_FIND_ERROR2 db "Can not find file 2", 0DH, 0AH, '$'
    PATH_ERROR2 db "Can not find path 2", 0DH, 0AH, '$'
    
    NORMAL_END db "Load is successful", 0DH, 0AH, '$'
    NORMAL_ALLOC_END db "Allocation was successful", 0DH, 0AH, '$'

    
    
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
    pop dx
    pop bx
    pop cx
    pop ax
    ret
FREE_MEM ENDP

PATH proc near
    push ax
   	push bx
   	push cx
   	push dx
   	push di
   	push si
   	push es

   	mov SAVED, dx   
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

find_loop_1:
   	mov dl, es:[bx]
   	mov byte ptr [path_ + di], dl
   	inc di
   	inc bx
   	cmp dl, 0
   	je end_find_loop
   	cmp dl, '\'
   	jne find_loop_1
   	mov cx, di
   	jmp find_loop_1

end_find_loop:
   	mov di, cx
   	mov si, SAVED

find_loop_2:
   	mov dl, byte ptr[si]
   	mov byte ptr [path_ + di], dl
   	inc di
   	inc si
   	cmp dl, 0
   	jne find_loop_2

   	pop es
   	pop si
   	pop di
   	pop dx
   	pop cx
   	pop bx
   	pop ax
   	ret

PATH endp

ALLOCATE_MEMORY PROC near
    push ax
	push bx
	push cx
	push dx
    push di

	mov dx, offset DTA
	mov ah, 1ah
	int 21h

	mov dx, offset path_
	mov ah, 4eh
	int 21h

    jnc successful_alloc

    cmp ax, 2
    je cant_find
    cmp ax, 3
    je path_err

cant_find:
    mov dx, offset CANT_FIND_ERROR2
    call WRITE_STRING
    jmp allocate_end
path_err:
    mov dx, offset PATH_ERROR2
    call WRITE_STRING
    jmp allocate_end
successful_alloc:
	mov di, offset DTA
    mov dx, [di + 1ch]
    mov ax, [di + 1ah]
    mov bx, 10h
    div bx
    add ax, 1h
    mov bx, ax
    mov ah, 48h
    int 21h
    mov bx, offset overlay_address
    mov cx, 0000h
    mov [bx], ax
    mov [bx + 2], cx
	mov dx, offset NORMAL_ALLOC_END
	call WRITE_STRING
allocate_end:
    pop di
    pop dx
	pop cx
	pop bx
	pop ax
	ret

ALLOCATE_MEMORY ENDP

LOAD PROC near
    push ax
	push bx
	push cx
	push dx
	push ds
	push es
	
	mov ax, DATA
	mov es, ax
    mov bx, offset overlay_address
	mov dx, offset path_
	mov ax, 4b03h
	int 21h 
	
    jnc LOAD_SUCCESS
    cmp ax, 1
    je E_1
    cmp ax, 2
    je E_2
    cmp ax, 3
    je E_3
    cmp ax, 4
    je E_4
    cmp ax, 6
    je E_6
    cmp ax, 8
    je E_8
    cmp ax, 10
    je E_10
E_1:
    mov dx, offset WRONG_NUMBER_ERROR
    call WRITE_STRING
    jmp LOAD_END
E_2:
    mov dx, offset CANT_FIND_ERROR
    call WRITE_STRING
    jmp LOAD_END
E_3:
    mov dx, offset PATH_ERROR
    call WRITE_STRING
    jmp LOAD_END
E_4:
    mov dx, offset OPEN_ERROR
    call WRITE_STRING
    jmp LOAD_END
E_6:
    mov dx, offset ACCESS_ERROR
    call WRITE_STRING
    jmp LOAD_END
E_8:
    mov dx, offset NOT_ENOUGH_MEM_ERROR
    call WRITE_STRING
    jmp LOAD_END
E_10:
    mov dx, offset ENVIRONMENT_ERROR
    call WRITE_STRING
    jmp LOAD_END

LOAD_SUCCESS:
    mov dx, offset NORMAL_END
    call WRITE_STRING

    mov ax, word ptr overlay_address
    mov es, ax
   	mov word ptr overlay_address, 0
   	mov word ptr overlay_address + 2, ax
   	call overlay_address
   	mov es, ax
   	mov ah, 49h
   	int 21h

LOAD_END:
    pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
    ret
LOAD ENDP

FOR_OVERLAY PROC near
    push dx
    call PATH
    mov dx, offset path_
    call ALLOCATE_MEMORY
    call LOAD
    pop dx
    ret
FOR_OVERLAY ENDP

MAIN PROC far
    push dx
    push ax
    mov ax, DATA
    mov ds, ax

    mov SAVED_PSP, es

    call FREE_MEM
    cmp ERR_FLAG, 1
    je MAIN_END
    
    mov dx, offset file_overlay1
    call FOR_OVERLAY
    mov dx, offset file_overlay2
    call FOR_OVERLAY

MAIN_END:
    mov ah, 4ch
    int 21h

PROC_END:
MAIN endp
CODE ends
END Main
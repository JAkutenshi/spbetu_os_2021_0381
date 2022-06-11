
MY_STACK SEGMENT STACK
	DW 64 DUP(?)
MY_STACK ENDS

DATA SEGMENT
    CLEAR_MEMORY db "MEMORY CLEAR", 0DH, 0AH, '$'
    CNTRL_BLOCK db "Ctrl block disable ", 0DH, 0AH, '$'
    
    END_1 db 0DH, 0AH,  "PROGRAMM END:  ", 0DH, 0AH, '$'
    END_2 db 0DH, 0AH,  "PROGRAMM END BY CTRL BREAK", 0DH, 0AH, '$'
    END_3 db 0DH, 0AH,  "PROGRAMM END BY dEVICE ERROR ", 0DH, 0AH, '$'
    END_4 db 0DH, 0AH,  "PROGRAMM END BY FUNCTION 31h", 0DH, 0AH, '$'
    
    ERROR_1 db "ERROR MEMORY", 0DH, 0AH, '$'
    ERROR_2 db "ERROR WRONG ADDRESS", 0DH, 0AH, '$'
    ERROR_3 db "ERROR FUNCTION ", 0DH, 0AH, '$'
    ERROR_4 db "ERROR FILE", 0DH, 0AH, '$'
    ERROR_5 db "ERROR DISK ", 0DH, 0AH, '$'
    ERROR_6 db "ERROR NO MEMMORY ", 0DH, 0AH, '$'
    ERROR_7 db "ERROR STR ", 0DH, 0AH, '$'
    ERROR_8 db "ERROR FORMAT", 0DH, 0AH, '$'
    
    PTH_FILE db "LR2.COM", 0
    
	par dw 0
                dd 0
                dd 0
                dd 0

    PPP dw 0
    PD dw 0
    PDD dw 0
    POINT_E db 0
    
    LINE_CMD db 1h,0DH
    pa db 128 dup(0)

    DATA_END db 0
DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE, DS:DATA, SS:MY_STACK

PRINT_STR proc near
    mov ah, 9h
    int 21h
    ret
PRINT_STR endp


STRT PROC
    ;push ss
    ;push sp
    push ax
	push bx
	push cx
	push dx
	push ds
	push es

	mov PD, sp
	mov PDD, ss
	mov ax, DATA
	mov es, ax
    mov bx, offset par
	mov dx, offset LINE_CMD
	mov [bx+2], dx
	mov [bx+4], ds
	mov dx, offset pa
	mov ax, 4b00h
	int 21h

	mov ss, PDD
	mov sp, PD
	pop es
	pop ds

    jnc SCCSS
    cmp ax, 1
    je ERR_3
    cmp ax, 2
    je ERR_4
    cmp ax, 5
    je ERR_5
    cmp ax, 8
    je ERR_6
    cmp ax, 10
    je ERR_7
    ;cmp ax, 9
    cmp ax, 11
    je ERR_8
ERR_3:
    mov dx, offset ERROR_3
    call PRINT_STR ;call
    jmp TO_END
ERR_4:
    mov dx, offset ERROR_4
    call PRINT_STR
    jmp TO_END
ERR_5:
    mov dx, offset ERROR_5
    call PRINT_STR
    jmp TO_END
ERR_6:
    mov dx, offset ERROR_6
    call PRINT_STR
    jmp TO_END
ERR_7:
    mov dx, offset ERROR_7
    call PRINT_STR
    jmp TO_END
ERR_8:
    mov dx, offset ERROR_8
    call PRINT_STR
    jmp TO_END

SCCSS:
    mov ah, 4dh
    mov al, 00h
    int 21h

    cmp ah, 0
    je OK
    cmp ah, 1
    je ERR_END_1
    cmp ah, 2
    je ERR_END_2
    cmp ah, 3
    je F_END
    
ERR_END_1:
    mov dx, offset END_2
    call PRINT_STR
    jmp TO_END
ERR_END_2:
    mov dx, offset END_3
    call PRINT_STR
    jmp TO_END
   
OK:
    mov di, offset END_1
    add di, 15
    mov [di], al
    mov dx, offset END_1
    call PRINT_STR
    jmp TO_END

F_END:
    mov dx, offset END_4
    call PRINT_STR


TO_END:
	pop dx
	pop cx
	pop bx
	pop ax
    ret
STRT ENDP

PATH PROC 
	push ax
	push bx
	push cx 
	push dx
	push di
	push si
	push es
	
	mov ax, PPP
	mov es, ax
	mov es, es:[2ch]
	mov bx, 0
	
READ_PTH:
	inc bx
	cmp byte ptr es:[bx-1], 0
	jne READ_PTH
	cmp byte ptr es:[bx+1], 0 
	jne READ_PTH	
	add bx, 2
	mov di, 0
	
CICLE:
	mov dl, es:[bx]
	mov byte ptr [pa + di], dl
	inc di
	inc bx
	cmp dl, 0
	je CICLE_FINISH
	cmp dl, '\'
	jne CICLE
	mov cx, di
	jmp CICLE

CICLE_FINISH:
	mov di, cx
	mov si, 0
	
FINISH:
	mov dl, byte ptr [PTH_FILE+si]
	mov byte ptr [pa+di], dl
	inc di 
	inc si
	cmp dl, 0 
	jne FINISH
	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
PATH ENDP


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

    jnc PRINT_STRING
    mov POINT_E, 1

    cmp ax, 7
    je CTRL_BLOCK
    cmp ax, 8
    je ERROR_MEMORY
    cmp ax, 9
    je ERROR_ADDRESS

ERROR_ADDRESS:
    mov dx, offset ERROR_2
    call PRINT_STR
    jmp CLEAR
PRINT_STRING:
    mov dx, offset CICLE_FINISH
    call PRINT_STR
CTRL_BLOCK:
    mov dx, offset CNTRL_BLOCK
    call PRINT_STR
    jmp CLEAR
ERROR_MEMORY:
    mov dx, offset ERROR_1
    call PRINT_STR
    jmp CLEAR

CLEAR:
    pop cx
    pop dx
    pop bx
    pop ax
    ret
FREE_MEM ENDP

MAIN PROC far
    push dx
    push ax
    mov ax, DATA
    mov ds, ax
    mov PPP, es

    call FREE_MEM
    cmp POINT_E, 1
    je MAIN_END
    call PATH
    call STRT

MAIN_END:
    xor al, al
    mov ah, 4ch
    int 21h

PROC_END:
MAIN endp
CODE ends
END Main


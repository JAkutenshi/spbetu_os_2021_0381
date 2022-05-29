DATA SEGMENT
	MEM_DT db 43 dup(0)
	MEM_F db 0
	CLEAR_P db 128 dup(0)
	OVL dd 0
	PSP_ dw 0
	PR dw 0
	
	OK db  'LOAD SUCCESS', 0dh, 0ah, '$'
	OK_MEM_ALLOC db  'MEMORY ALLOCATION SUCCESS', 0dh, 0ah, '$'
	OK_FREE db 'MEMORY FEED' , 0dh, 0ah, '$'
	ERROR_MCB db 'ERROR MCB', 0dh, 0ah, '$'
	ERROR_MEMMORY_FUNCTION db 'ERROR NO MEMORY FOR FUNCTION', 0dh, 0ah, '$'
	ERROR_FUNCT db 'ERROR FUNCTION', 0dh, 0ah, '$'
	ERROR_FILE db 'ERROR FILE', 0dh, 0ah, '$'
	ERROR_ROUTE db 'ERROR ROUTE', 0dh, 0ah, '$'
	ERROR_FILES db 'ERROR MANY FILES', 0dh, 0ah, '$'
	ERROR_ADDRESS db 'ERROR ADDRESS', 0dh, 0ah, '$'
	ERROR_MEMORY db 'ERROR MEMORY INSUFFICIENT', 0dh, 0ah, '$'
	ERROR_STR db 'ERROR WRONG STR', 0dh, 0ah, '$'
	ERROR_FILE_ALL db  'EEROR NO FILE' , 0dh, 0ah, '$'
	ERROR_ACCESS db 'ERROR ACCESS', 0dh, 0ah, '$'
	FILE_OV_1 db "OV_1.exe", 0
	FILE_OV_2 db "OV_2.exe", 0
	END_OF_FILE db 0dh, 0ah, '$'
	end_data db 0
DATA ENDS

AStack SEGMENT STACK
	dw 128 dup(?)
AStack ENDS

CODE SEGMENT

ASSUME cs:CODE, ds:DATA, ss:AStack

LOAD_P proc near
	push ax
	push bx
	push cx
	push dx
	push ds
	push es

	mov ax, data
	mov es, ax
	mov bx, offset OVL
	mov dx, offset CLEAR_P
	mov ax, 4b03h
	int 21h

	jnc LOADS_OK

ERROR_1:
	cmp ax, 1
	jne ERROR_2
	mov dx, offset END_OF_FILE
	call PRINT_STR
	mov dx, offset ERROR_FUNCT
	call PRINT_STR
	jmp FREE_LOAD
ERROR_2:
	cmp ax, 2
	jne ERROR_3
	mov dx, offset ERROR_FILE
	call PRINT_STR
	jmp FREE_LOAD
ERROR_3:
	cmp ax, 3
	jne ERROR_4
	mov dx, offset END_OF_FILE
	call PRINT_STR
	mov dx, offset ERROR_ROUTE
	call PRINT_STR
	jmp FREE_LOAD
ERROR_4:
	cmp ax, 4
	jne ERROR_5
	mov dx, offset ERROR_FILES
	call PRINT_STR
	jmp FREE_LOAD
ERROR_5:
	cmp ax, 5
	jne ERROR_6
	mov dx, offset ERROR_ACCESS
	call PRINT_STR
	jmp FREE_LOAD
ERROR_6:
	cmp ax, 8
	jne ERROR_7
	mov dx, offset ERROR_MEMORY
	call PRINT_STR
	jmp FREE_LOAD
ERROR_7:
	cmp ax, 10
	mov dx, offset ERROR_STR
	call PRINT_STR
	jmp FREE_LOAD

LOADS_OK:
	mov dx, offset OK
	call PRINT_STR

	mov ax, word ptr OVL
	mov es, ax
	mov word ptr OVL, 0
	mov word ptr OVL+2, ax

	call OVL
	mov es, ax
	mov ah, 49h
	int 21h

FREE_LOAD:
	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	ret
LOAD_P ENDP

PRINT_STR proc near
 	mov ah, 09h
 	int 21h
 	ret
PRINT_STR ENDP

FREE_MEM proc near
	push ax
	push bx
	push cx
	push dx

	mov ax, offset end_data
	mov bx, offset EXIT
	add bx, ax

	mov cl, 4
	shr bx, cl
	add bx, 2bh
	mov ah, 4ah
	int 21h

	jnc FREE_ERROR
	mov MEM_F, 1

MCB_ERROR:
	cmp ax, 7
	jne MEMORY_FUNCTION_ERROR
	mov dx, offset ERROR_MCB
	call PRINT_STR
	jmp END_FF

MEMORY_FUNCTION_ERROR:
	cmp ax, 8
	jne ADDRESS_ERROR
	mov dx, offset ERROR_MEMMORY_FUNCTION
	call PRINT_STR
	jmp END_FF

ADDRESS_ERROR:
	cmp ax, 9
	mov dx, offset ERROR_ADDRESS
	call PRINT_STR
	jmp END_FF

FREE_ERROR:
	mov MEM_F, 1
	mov dx, offset OK_FREE
	call PRINT_STR

END_FF:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
FREE_MEM ENDP

F_PATH proc near
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	push es

	mov PR, dx

	mov ax, PSP_
	mov es, ax
	mov es, es:[2ch]
	mov bx, 0

FIND_FF:
	inc bx
	cmp byte ptr es:[bx-1], 0
	jne FIND_FF

	cmp byte ptr es:[bx+1], 0
	jne FIND_FF

	add bx, 2
	mov di, 0

CYCLE:
	mov dl, es:[bx]
	mov byte ptr [CLEAR_P+di], dl
	inc di
	inc bx
	cmp dl, 0
	je CYCLE_END
	cmp dl, '\'
	jne CYCLE
	mov cx, di
	jmp CYCLE
CYCLE_END:
	mov di, cx
	mov si, PR

F_N:
	mov dl, byte ptr [si]
	mov byte ptr [CLEAR_P+di], dl
	inc di
	inc si
	cmp dl, 0
	jne F_N


	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
F_PATH endp

ALLOC_MEM proc near
	push ax
	push bx
	push cx
	push dx

	push dx
	mov dx, offset MEM_DT
	mov ah, 1ah
	int 21h
	pop dx
	mov cx, 0
	mov ah, 4eh
	int 21h

	jnc OK_FINISH

ERROR_ALLFILE:
	cmp ax, 2
	mov dx, offset ERROR_FILE_ALL
	call PRINT_STR
	jmp CLEAR_MM

OK_FINISH:
	push di
	mov di, offset MEM_DT
	mov bx, [di+1ah]
	mov ax, [di+1ch]
	pop di
	push cx
	mov cl, 4
	shr bx, cl
	mov cl, 12
	shl ax, cl
	pop cx
	add bx, ax
	add bx, 1
	mov ah, 48h
	int 21h
	mov word ptr OVL, ax
	mov dx, offset OK_MEM_ALLOC
	call PRINT_STR

CLEAR_MM:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
ALLOC_MEM endp

begin_ovl proc
	push dx
	call F_PATH
	mov dx, offset CLEAR_P
	call ALLOC_MEM
	call LOAD_P
	pop dx
	ret
begin_ovl endp

F_BEGIN proc far
	push ds
	xor ax, ax
	push ax
	mov ax, data
	mov ds, ax
	mov PSP_, es
	call FREE_MEM
	cmp MEM_F, 0
	je _end

	mov dx, offset FILE_OV_1
	call begin_ovl
	mov dx, offset END_OF_FILE
	call PRINT_STR
	mov dx, offset FILE_OV_2
	call begin_ovl

_end:
	xor al, al
	mov ah, 4ch
	int 21h

F_BEGIN ENDP

EXIT:
CODE ENDS
END F_BEGIN

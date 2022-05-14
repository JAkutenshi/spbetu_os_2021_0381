ENV_OFFSET EQU 2Ch
DTA_SIZE_OFFSET EQU 1Ah

AStack SEGMENT STACK
 	DW 64 DUP(?)   
AStack ENDS

DATA  SEGMENT
 	OVERLAY1_NAME db 'o1.exe',0
 	OVERLAY2_NAME db 'o2.exe',0
 	ERROR_MCB_DESTR db "Error: MCB destroyed$"
 	ERROR_NOT_ENOUGH_MEM db "Error: Not enough memory$"
 	ERROR_WRONG_ADDR db "Error: Wrong block address$"
 	ERROR_FILE_NOT_FOUND db "Error: File not found$"
 	ERROR_PATH_NOT_FOUND db "Error: Path not found$"
 	ERROR_F_DOESNT_EXIST db "Error: Wrong function$"
 	ERROR_TOO_MANY_FILES db "Error: Too many files are opened$"
 	ERROR_NO_PERMISSION db "Error: No permission$"
 	NEW_LINE db 0dh,0ah,'$'
 	PATH db 50 dup(0)
        DTA db 43 dup(0)
 	EPB dw 2 dup(0)
 	OVERLAY_ADDR dd 0
 	err db 0
DATA ENDS

CODE SEGMENT
 	ASSUME CS:CODE,DS:DATA,SS:AStack
 	
FREE_MEM PROC NEAR
 	push ax
 	push bx
 	push cx
 	push dx
 	mov bx, offset _codeend
 	mov ax, es
 	sub bx, ax
 	mov cl, 4
 	shr bx, cl
 	mov AH,4ah
 	int 21H
 	jnc finish_free
 	cmp ax, 7
 	je case7_free
 	cmp ax, 8
 	je case8_free
 	cmp ax, 9
 	je case9_free
 	jmp finish_free
 	
	case7_free:
 	mov dx, offset ERROR_MCB_DESTR
 	jmp print_free
 	
	case8_free:
 	mov dx, offset ERROR_NOT_ENOUGH_MEM
 	jmp print_free
 	
 	case9_free:
 	mov dx, offset ERROR_WRONG_ADDR
 	jmp print_free
 	
 	print_free:
 	mov ah,09h
 	int 21h
 	mov err,1

 	finish_free:
 	pop dx
 	pop cx
 	pop bx
 	pop ax
 	ret
FREE_MEM ENDP	
 	
GET_PATH PROC NEAR
 	push si
 	mov si,0
 	mov es, es:[ENV_OFFSET]

	env_loop:
 	mov al,es:[si]
 	inc si
 	cmp al,0
 	jne env_loop
 	mov al,es:[si]
 	cmp al,0
 	jne env_loop	
 	add si,3
 	push si

	search_slash:
 	cmp byte ptr es:[si],'\'
 	jne next
 	mov ax,si

 	next:
 	inc si
 	cmp byte ptr es:[si],0
 	jne search_slash
 	inc ax
 	pop si
 	mov di,0

 	dirr:		
 	mov bl,es:[si]
 	mov PATH[di],bl
 	inc si
 	inc di
 	cmp si, ax
 	jne dirr
 	pop si
					
 	filename:			
 	mov bl,[si]
 	mov PATH[di],bl
 	inc si
 	inc di
 	cmp bl, 0
 	jne filename
 	ret
GET_PATH ENDP	
 	
GET_FILESIZE PROC NEAR	
 	push cx
 	push dx
 	mov dx, offset DTA
 	mov ah, 1ah
 	int 21h
 	
 	mov cx, 0
 	mov dx,offset PATH
 	mov ah, 4eh
 	int 21h
 	
 	jnc no_err_filesize
 	cmp ax, 2
 	je case2_filesize
 	cmp ax, 3
 	je case3_filesize

 	case2_filesize:
 	mov dx, offset ERROR_FILE_NOT_FOUND
 	jmp print_filesize

 	case3_filesize:
 	mov dx, offset ERROR_PATH_NOT_FOUND

 	print_filesize:
 	mov err, 1
 	mov ah,09h
 	int 21h

 	no_err_filesize:	
 	mov ax, word ptr DTA[DTA_SIZE_OFFSET]
 	mov dx, word ptr DTA[DTA_SIZE_OFFSET+2]
 	mov cl,4
 	shr ax, cl	
 	mov cl, 12
 	shl dx, cl
 	add ax, dx
 	add ax, 1
 	pop dx
 	pop cx		
 	ret
GET_FILESIZE ENDP	
 		
MALLOC PROC NEAR 
 	push bx
 	push dx
 	mov bx, ax
 	mov ah,48h
 	int 21h
 	jnc no_err_malloc
 	mov dx, offset ERROR_NOT_ENOUGH_MEM
 	mov ah,09h
 	int 21h
 	mov err, 1
 	jmp finish_malloc

 	no_err_malloc:
 	mov EPB[0], ax
 	mov EPB[2], ax

 	finish_end:
 	pop dx
 	pop bx
 	ret
MALLOC ENDP	
 	
LOAD PROC NEAR	
 	push ax
 	push es
 	push bx
 	push dx
 	mov dx, offset PATH
 	mov ax, ds
 	mov es, ax
 	mov bx, offset EPB
 	mov ax, 4b03h
 	int 21h
 	jnc no_err_load
 	cmp ax, 1
 	je case1_load
 	cmp ax, 2
 	je case2_load
 	cmp ax, 3
 	je case3_load
 	cmp ax, 4
 	je case4_load
 	cmp ax, 5
 	je case5_load
 	cmp ax, 8
 	je case8_load

 	case1_load:
 	mov dx, offset ERROR_F_DOESNT_EXIST
 	jmp print_err

 	case2_load:
 	mov dx, offset ERROR_FILE_NOT_FOUND
 	jmp print_err
	
 	case3_load:
 	mov dx, offset ERROR_PATH_NOT_FOUND
 	jmp print_err

 	case4_load:
 	mov dx, offset ERROR_TOO_MANY_FILES
 	jmp print_err

	case5_load:
 	mov dx, offset ERROR_NO_PERMISSION
 	jmp print_err

 	case8_load:
 	mov dx, offset ERROR_NOT_ENOUGH_MEM

 	print_err:
 	mov ah,09h
 	mov err,1
 	int 21h
 	jmp finish_load

 	no_err_load:
 	mov ax, EPB[2]
 	mov word ptr OVERLAY_ADDR+2, ax 
 	call OVERLAY_ADDR
 	mov es,ax
 	mov ah, 49h
 	int 21h

 	finish_load:
 	pop dx
 	pop bx
 	pop es
 	pop ax
 	ret
LOAD ENDP 	
 	 	
PRINT_STR PROC NEAR
 	push ds
 	mov ax,es
 	mov ds,ax
 	mov ah,02h

 	_loop_:
 	lodsb
 	mov dl,al
 	cmp dl,0
 	je finish
 	int 21h
 	loop _loop_

 	finish:
 	pop ds
 	ret
PRINT_STR ENDP	
 	
MAIN PROC FAR
 	mov ax, DATA
 	mov ds, ax
 	push es
 	call FREE_MEM
 	cmp err,0
 	jne _exit_
 	
 	mov si,offset OVERLAY1_NAME
 	call GET_PATH	
 	call GET_FILESIZE
 	cmp err,0
 	jne _o1
 	call MALLOC
 	cmp err,0
 	jne _o1
 	call LOAD

 	_o1:
 	mov dx, offset NEW_LINE
 	mov ah,09h
 	int 21h
 	pop es
 	mov err,0
 	mov si,offset OVERLAY2_NAME
 	call GET_PATH	
 	call GET_FILESIZE
 	cmp err,0
 	jne _exit_
 	call MALLOC
 	cmp err,0
 	jne _exit_
 	call LOAD
 	
 	_exit_:	
 	xor al,al
 	mov ah,4ch
 	int 21h  

 	_codeend:
MAIN ENDP
CODE ENDS
END MAIN 

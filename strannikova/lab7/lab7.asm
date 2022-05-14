ENV_OFFSET EQU 2Ch
DTA_SIZE_OFFSET EQU 1Ah

AStack SEGMENT STACK
	DW 64 DUP(?)   
AStack ENDS

DATA  SEGMENT
	OVERLAY1 db 'ol1.exe',0
	OVERLAY2 db 'ol2.exe',0
	MCB_DESTR db "Error: MCB destroyed$"
	NOT_ENOUGH_MEM db "Error: Not enough memory$"
	WRONG_ADDR db "Error: Wrong block address$"
	FILE_NOT_FOUND db "Error: File not found$"
	PATH_NOT_FOUND db "Error: Path not found$"
	F_DOESNT_EXIST db "Error: Wrong function$"
	TOO_MANY_FILES db "Error: Too many files are opened$"
	NO_PERMISSION db "Error: No permission$"
	ENVIROMENT_ERROR db "Error: Incorrect enviroment$"
	NEW_LINE db 0dh,0ah,'$'
	PATH db 50 dup(0)
    DTA db 43 dup(0)
	EPB dw 2 dup(0)
	OVERLAY_ADDR dd 0
	err db 0
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE,DS:DATA,SS:AStack
	
FREE PROC NEAR
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
	jnc free_end
	cmp ax, 7
	je free_case7
	cmp ax, 8
	je free_case8
	cmp ax, 9
	je free_case9
	jmp free_end
	
free_case7:
	mov dx, offset MCB_DESTR
	jmp free_print
	
free_case8:
	mov dx, offset NOT_ENOUGH_MEM
	jmp free_print
	
free_case9:
	mov dx, offset WRONG_ADDR
	jmp free_print
	
free_print:
	mov ah,09h
	int 21h
	mov err,1
free_end:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
FREE ENDP	
; ----------------------------------------------------------
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
find_slash:
	cmp byte ptr es:[si],'\'
	jne continue
	mov ax,si
continue:
	inc si
	cmp byte ptr es:[si],0
	jne find_slash
	inc ax
	pop si
	mov di,0
copy_dir:			
	mov bl,es:[si]
	mov PATH[di],bl
	inc si
	inc di
	cmp si, ax
	jne copy_dir
	pop si					
copy_filename:			
	mov bl,[si]
	mov PATH[di],bl
	inc si
	inc di
	cmp bl, 0
	jne copy_filename
	
	ret
GET_PATH ENDP	
; ----------------------------------------------------------	
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
	
	jnc filesize_noerr
	cmp ax, 2
	je filesize_case2
	cmp ax, 3
	je filesize_case3
filesize_case2:
	mov dx, offset FILE_NOT_FOUND
	jmp filesize_print
filesize_case3:
	mov dx, offset PATH_NOT_FOUND
filesize_print:
	mov err, 1
	mov ah,09h
	int 21h
filesize_noerr:	
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
; ----------------------------------------------------------		
MALLOC PROC NEAR 
	push bx
	push dx
	mov bx, ax
	mov ah,48h
	int 21h
	jnc malloc_noerr
	mov dx, offset NOT_ENOUGH_MEM
	mov ah,09h
	int 21h
	mov err, 1
	jmp malloc_end
malloc_noerr:
	mov EPB[0], ax
	mov EPB[2], ax
malloc_end:
	pop dx
	pop bx
	ret
MALLOC ENDP	
; ----------------------------------------------------------	
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
	jnc no_error
	cmp ax, 1
	je case1
	cmp ax, 2
	je case2
	cmp ax, 3
	je case3
	cmp ax, 4
	je case4
	cmp ax, 5
	je case5
	cmp ax, 8
	je case6
	cmp ax, 10
	je case7
case1:
	mov dx, offset F_DOESNT_EXIST
	jmp print_mark
case2:
	mov dx, offset FILE_NOT_FOUND
	jmp print_mark
case3:
	mov dx, offset PATH_NOT_FOUND
	jmp print_mark
case4:
	mov dx, offset TOO_MANY_FILES
	jmp print_mark
case5:
	mov dx, offset NO_PERMISSION
	jmp print_mark
case6:
	mov dx, offset NOT_ENOUGH_MEM
	jmp print_mark
case7:
	mov dx, offset ENVIROMENT_ERROR
	jmp print_mark
print_mark:
	mov ah,09h
	mov err,1
	int 21h
	jmp _load_end
no_error:
	mov ax, EPB[2]
	mov word ptr OVERLAY_ADDR+2, ax 
	call OVERLAY_ADDR
	
	mov es,ax
	mov ah, 49h
	int 21h
_load_end:
	pop dx
	pop bx
	pop es
	pop ax
	ret
LOAD ENDP 	
; ----------------------------------------------------------
PRINTSTR PROC NEAR 
	push ds
	mov ax,es
	mov ds,ax
	mov ah,02h
loop_mark:
	lodsb
	mov dl,al
	cmp dl,0
	je end_mark
	int 21h
	loop loop_mark
end_mark:
	pop ds
	ret
PRINTSTR ENDP	
; ----------------------------------------------------------	
MAIN PROC FAR
	mov ax, DATA
	mov ds, ax
	push es
	call FREE
	cmp err,0
	jne _exit
	
	mov si,offset OVERLAY1
	call GET_PATH	
	call GET_FILESIZE
	cmp err,0
	jne ol1
	call MALLOC
	cmp err,0
	jne ol1
	call LOAD
ol1:
	mov dx, offset NEW_LINE
	mov ah,09h
	int 21h
	pop es
	mov err,0
	mov si,offset OVERLAY2
	call GET_PATH	
	call GET_FILESIZE
	cmp err,0
	jne _exit
	call MALLOC
	cmp err,0
	jne _exit
	call LOAD
	
_exit:	
	xor al,al
	mov ah,4ch
	int 21h  
_codeend:
MAIN ENDP
CODE ENDS
END MAIN
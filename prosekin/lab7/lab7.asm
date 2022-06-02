ENV_OFFSET EQU 2Ch
DTA_SIZE_OFFSET EQU 1Ah

AStack SEGMENT STACK
	DW 64 DUP(?)   
AStack ENDS

DATA  SEGMENT
	overlay_first db 'ol1.exe',0
	overlay_second db 'ol2.exe',0
	destroyed_mcb db "Error: MCB destroyed$"
	not_enough_memory db "Error: Not enough memory$"
	wrong_address db "Error: Wrong block address$"
	not_found_file db "Error: File not found$"
	not_found_path db "Error: Path not found$"
	func_not_exists db "Error: Wrong function$"
	lots_of_files db "Error: Too many files are opened$"
	no_permission db "Error: No permission$"
	env_err db "Error: Incorrect enviroment$"
	new_line db 0dh,0ah,'$'
	path db 50 dup(0)
    dta db 43 dup(0)
	epb dw 2 dup(0)
	overlay_address dd 0
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
	mov dx, offset destroyed_mcb
	jmp free_print
	
free_case8:
	mov dx, offset not_enough_memory
	jmp free_print
	
free_case9:
	mov dx, offset wrong_address
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
	mov path[di],bl
	inc si
	inc di
	cmp si, ax
	jne copy_dir
	pop si					
copy_filename:			
	mov bl,[si]
	mov path[di],bl
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
	mov dx, offset dta
	mov ah, 1ah
	int 21h
	
	mov cx, 0
	mov dx,offset path
	mov ah, 4eh
	int 21h
	
	jnc filesize_noerr
	cmp ax, 2
	je filesize_case2
	cmp ax, 3
	je filesize_case3
filesize_case2:
	mov dx, offset not_found_file
	jmp filesize_print
filesize_case3:
	mov dx, offset not_found_path
filesize_print:
	mov err, 1
	mov ah,09h
	int 21h
filesize_noerr:	
	mov ax, word ptr dta[DTA_SIZE_OFFSET]
	mov dx, word ptr dta[DTA_SIZE_OFFSET+2]
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
	mov dx, offset not_enough_memory
	mov ah,09h
	int 21h
	mov err, 1
	jmp malloc_end
malloc_noerr:
	mov epb[0], ax
	mov epb[2], ax
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
	mov dx, offset path
	mov ax, ds
	mov es, ax
	mov bx, offset epb
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
	mov dx, offset func_not_exists
	jmp print_mark
case2:
	mov dx, offset not_found_file
	jmp print_mark
case3:
	mov dx, offset not_found_path
	jmp print_mark
case4:
	mov dx, offset lots_of_files
	jmp print_mark
case5:
	mov dx, offset no_permission
	jmp print_mark
case6:
	mov dx, offset not_enough_memory
	jmp print_mark
case7:
	mov dx, offset env_err
	jmp print_mark
print_mark:
	mov ah,09h
	mov err,1
	int 21h
	jmp _load_end
no_error:
	mov ax, epb[2]
	mov word ptr overlay_address+2, ax 
	call overlay_address
	
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
	
	mov si,offset overlay_first
	call GET_PATH	
	call GET_FILESIZE
	cmp err,0
	jne ol1
	call MALLOC
	cmp err,0
	jne ol1
	call LOAD
ol1:
	mov dx, offset new_line
	mov ah,09h
	int 21h
	pop es
	mov err,0
	mov si,offset overlay_second
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
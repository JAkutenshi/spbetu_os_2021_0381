ASTACK SEGMENT STACK
   DW 200 DUP(?)
ASTACK ENDS

DATA SEGMENT
    ALREADY_LOADED_STR db 'Interruption was already loaded :)', 0DH, 0AH, '$'
    SUCCESS_LOADED_STR db 'Loading of interruption went successfully :)', 0DH, 0AH, '$'
    NOT_LOADED_STR db 'Interruption was not loaded :(', 0DH, 0AH, '$'
    RESTORED_STR db 'Interruption is restored now', 0DH, 0AH, '$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:ASTACK

;------------------------------------
PRINT_INFO PROC NEAR
	push AX
	mov AH, 9
	int 21h
	pop AX
	ret
PRINT_INFO ENDP
;------------------------------------
INTERRUPTION PROC FAR
	jmp begin_mark
	KEY db 0h
	SHIFT db 0h
	SIGNATURE dw 7777h
	KEEP_IP dw 0
	KEEP_CS dw 0
	ADDRESS_OF_PSP dw ?
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_AX dw 0
	STACK dw 16 dup(?)

begin_mark:
	mov KEEP_SS, SS
	mov KEEP_SP, SP
	mov KEEP_AX, AX
	mov ax, cs
	mov ss, ax
	mov SP, offset begin_mark
	
	push bx
	push cx
	push dx
	push di
	push bp
	push ds
	
	in al,60h
    cmp al, 10h ; 'q'
    je check
    call dword ptr cs:KEEP_IP
    jmp output

check:
	in al,61H 
	mov ah,al 
	or al,80h 
	out 61H,al
	xchg ah,al
	out 61H,al
	mov al,20H
	out 20H,al
 
check_again:
	mov ah,05h 
	mov cl,'N' 
	mov ch,00h 
	int 16h 
	or al,al 
	jz output
	mov ah,0ch
	mov al,00h
	int 21h
	jmp check_again
	
output:	
	pop ds
	pop bp
	pop di
	pop dx
	pop cx
	pop bx
	
	mov ax, KEEP_AX
	mov ss, KEEP_SS
	mov sp, KEEP_SP
	
	mov al, 20h
	out 20h, al
	iret
the_end:	

INTERRUPTION ENDP
;------------------------------------
CHECK_KEY PROC NEAR
	push AX
	push BP
	mov CL, 0h
	mov BP, 81h
	mov AL, ES:[BP + 1]
	cmp AL, '/'
	jne exit
	mov AL, ES:[BP + 2]
	cmp AL, 'u'
	jne exit
	mov AL, ES:[BP + 3]
	cmp AL, 'n'
	jne exit
	mov CL, 1h

exit:
	pop BP
	pop AX
	ret
CHECK_KEY ENDP
;------------------------------------
ALREADY_LOADED PROC NEAR
	push AX
	push DX
	push ES
	push SI
	mov CL, 0h
	mov AH, 35h
	mov AL, 09h
	int 21h
	mov SI, offset SIGNATURE
	sub SI, offset INTERRUPTION
	mov DX, ES:[BX+SI]
	cmp DX, SIGNATURE
	jne local_end
	mov CL, 1h 

local_end:
	pop SI
	pop ES
	pop DX
	pop AX
	ret
ALREADY_LOADED ENDP
;------------------------------------
LOAD PROC NEAR
	push AX
	push CX
	push DX
	call ALREADY_LOADED
	cmp CL, 1h
	je loaded
	mov address_of_psp, ES
	mov AH, 35h
	mov AL, 09h
	int 21h
	mov KEEP_CS, ES
	mov KEEP_IP, BX
	push ES
	push BX
	push DS
	lea DX, INTERRUPTION
	mov AX, seg INTERRUPTION
	mov DS, AX
	mov AH, 25h
	mov AL, 09h
	int 21h
	pop DS
	pop BX
	pop ES
	mov DX, offset SUCCESS_LOADED_STR
	call PRINT_INFO
	lea DX, the_end
	mov CL, 4h
	shr DX, CL
	inc DX 
	add DX, 100h
	xor AX,AX
	mov AH, 31h
	int 21h
	jmp end_load

loaded:
	mov DX, offset ALREADY_LOADED_STR
	call PRINT_INFO

end_load:
	pop DX
	pop CX
	pop AX
	ret
LOAD ENDP
;------------------------------------
UNLOAD PROC NEAR
	push AX
	push SI
	call ALREADY_LOADED
	cmp CL, 1h
	jne not_loaded
	cli
	push DS
	push ES
	mov AH, 35h
	mov AL, 09h
	int 21h
	mov SI, offset KEEP_IP
	sub SI, offset INTERRUPTION
	mov DX, ES:[BX+SI]
	mov AX, ES:[BX+SI+2]
	mov DS, AX
	mov AH, 25h
	mov AL, 09h
	int 21h
	mov AX, ES:[BX+SI+4]
	mov ES, AX
	push ES
	mov AX, ES:[2ch]
	mov ES, AX
	mov AH, 49h
	int 21h
	pop ES
	mov AH, 49h
	int 21h
	pop ES
	pop DS
	sti
	mov DX, offset RESTORED_STR
	call PRINT_INFO
	jmp end_unload

not_loaded:
	mov DX, offset NOT_LOADED_STR
	call PRINT_INFO

end_unload:
	pop SI
	pop AX
	ret
UNLOAD ENDP
;------------------------------------
MAIN PROC FAR
	mov AX, DATA
	mov DS, AX
	call CHECK_KEY
	cmp CL, 0h
	jne unload_key
	call LOAD
	jmp end_mark

unload_key:
	call UNLOAD

end_mark:
	xor AL, AL
	mov AH, 4ch
	int 21h
MAIN ENDP

CODE ENDS

END MAIN
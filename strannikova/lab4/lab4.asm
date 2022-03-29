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
; Установка позиции курсора
SET_CURSOR PROC NEAR
	mov ah,02h
	mov bh,0
; DH,DL = строка, колонка (считая от 0)
	mov dh,0 
	mov dl,0
	int 10h ; выполнение.
	ret
SET_CURSOR ENDP
;------------------------------------
; 03H читать позицию и размер курсора
GET_CURSOR PROC NEAR
	mov ah, 03h
	mov bh, 0
	int 10h
	ret
GET_CURSOR ENDP
;------------------------------------
INTERRUPTION PROC FAR
	jmp begin_mark
	COUNT_STR db 'Number of interrupts: 0000$'
	SIGNATURE dw 7777h
	KEEP_IP dw 0
	KEEP_CS dw 0
	ADDRESS_OF_PSP dw ?
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_AX dw 0
	STACK dw 16 dup(?)

begin_mark:
	mov KEEP_SP, SP
	mov KEEP_AX, AX
	mov AX, SS
	mov KEEP_SS, AX
	mov AX, KEEP_AX
	mov SP, offset begin_mark
	mov AX, seg STACK
	mov SS, AX
	push AX 
	push CX 
	push DX

	call GET_CURSOR
	push DX
	call SET_CURSOR
	push SI
	push CX
	push DS
	push BP
	mov AX, seg COUNT_STR
	mov DS, AX
	mov SI, offset COUNT_STR
	add SI, 21
	mov CX, 4

count_loop:
	mov BP, CX
	mov AH, [SI+BP]
	inc AH
	mov [SI+BP], AH
	cmp AH, 3ah
	jne output
	mov AH, 30h
	mov [SI+BP], AH
	loop count_loop

output:
	pop BP
	pop DS
	pop CX
	pop SI
	push ES
	push BP
	mov AX, seg COUNT_STR
	mov ES,AX
	mov AX, offset COUNT_STR
	mov BP,AX
	mov AH, 13h 
	mov AL, 00h
	mov CX, 26
	mov BH,0
	int 10h
	pop BP
	pop ES
	pop DX
	mov AH,02h
	mov BH,0h
	int 10h

	pop DX 
	pop CX 
	pop AX 
	mov KEEP_AX, AX
	mov SP, KEEP_SP
	mov AX, KEEP_SS
	mov SS, AX
	mov AX, KEEP_AX
	mov AL, 20h	
	out 20h, AL	
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
	mov AL, 1ch
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
	mov AL, 1ch
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
	mov AL, 1ch
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
	jne NOT_LOADED_STR
	cli
	push DS
	push ES
	mov AH, 35h
	mov AL, 1ch
	int 21h
	mov SI, offset KEEP_IP
	sub SI, offset INTERRUPTION
	mov DX, ES:[BX+SI]
	mov AX, ES:[BX+SI+2]
	mov DS, AX
	mov AH, 25h
	mov AL, 1ch
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
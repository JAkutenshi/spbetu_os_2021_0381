AStack    SEGMENT  STACK
          DW 512 DUP(?)    
AStack    ENDS

DATA SEGMENT
    	ALREADY_LOAD DB 'Interrupt already loaded',0DH,0AH,'$'
    	WAS_STR DB 'User interrupt set',0DH,0AH,'$'
    	RESTORE_STR DB 'Interruption restored',0DH,0AH,'$'
DATA ENDS
CODE SEGMENT
    	ASSUME CS:CODE, DS:DATA, SS:AStack
 
PRINT PROC near
   	 push ax
    	mov ah, 09h
    	int 21h
    	pop ax
    	ret
PRINT ENDP

;функция вывода строки по адресу ES:BP на экран 
outputBP proc
    	push ax
    	push bx
    	push dx
    	push CX
    	mov ah,13h	; функция
    	mov al,1	;sub function code
    	mov bh,0	; видео страница
    	int 10h
    	pop CX
    	pop dx
    	pop bx
    	pop ax
    	ret
outputBP endp

; Установка позиции курсора
; установка на строку 25 делает курсор невидимым 
setCurs proc

    	push ax
    	push bx
    	push dx
    	push CX
    	mov ah,02h
    	mov bh,0
    	int 10h	 ;выполнение
    	pop CX
    	pop dx
    	pop bx
    	pop ax
    	ret
setCurs endp

getCurs proc

    	push ax
   	push bx
   	push CX
    	mov ah,03h
    	mov bh,0
   	int 10h	 ;выполнение
    	pop CX
    	pop bx
    	pop ax
    	ret
getCurs endp

COUNTER_UPDATE PROC

    	push CX
   	mov CX, 7

    	num_check:
	mov AH, [DI]
	cmp AH, ' '
	je num_set
	cmp AH, '9'
	jl num_update
	mov AH, '0'
	mov [DI], AH
	dec DI
	dec CX
	cmp CX, 0
	jne num_check

    	num_set:
	mov AH, '1'
	mov [DI], AH
	jmp endl

    	num_update:
	push DX
	pop DX
	inc AH
	mov [DI], AH

    	endl:
	pop CX
	ret
COUNTER_UPDATE ENDP

;обработчик
INTERRUPTION  PROC Far
	jmp st_end
	PSP_START DW (?)
	KEEP_CS DW (?) 
	KEEP_IP DW (?) 
	
	SIGNATURE dw 0714h
	
	KEEP_SS dw (?)
	KEEP_SP dw (?)
	KEEP_AX dw (?)
	
	STR_COUNT db 'Count of interrupts:   0000'
	
	NEW_STACK dw 512 dup (?)

	st_end:
	mov KEEP_SS, SS
	mov KEEP_SP, SP
	mov KEEP_AX, AX
	
	mov AX, CS
	mov SS, AX
	mov SP, offset st_end
	
	push BX
	push CX
	push DX
	push DI
	push SI
	push BP
	push DS
	push ES
	
	mov AX, seg STR_COUNT
	mov DS, AX
	lea DI, STR_COUNT
	add DI, 26
	call COUNTER_UPDATE
	
	call getCurs
	push DX
	mov DX, 0
	call setCurs

	mov AX, SEG STR_COUNT
	mov ES, AX
	mov BP, offset STR_COUNT
	mov CX, 27
	call outputBP
	
	pop DX
	call setCurs

	pop ES
	pop DS
	pop BP
	pop SI
	pop DI
	pop DX
	pop CX
	pop BX
	
	mov SS, KEEP_SS
	mov SP, KEEP_SP
	mov AX, KEEP_AX
	mov AL, 20h
	out 20h, AL
	IRET
	s_endl:
INTERRUPTION  ENDP

SET_INTERRUPTION PROC Near

    	mov PSP_START, ES
    	mov AH, 35h
    	mov AL, 1Ch
    	int 21h
    	mov KEEP_IP, BX
    	mov KEEP_CS, ES

    	push DS
    	mov DX, offset INTERRUPTION 
    	mov AX, SEG INTERRUPTION 
    	mov DS, AX
   	mov AH, 25h
    	mov AL, 1Ch
    	int 21h
    	pop DS

    	mov DX, offset s_endl
    	mov CL, 4
    	shr DX, CL
    	inc DX

    	mov AX, CS
    	sub AX, PSP_START
    	add DX, AX

    	mov AL, 0
    	mov AH, 31h
    	int 21h

    	ret
SET_INTERRUPTION ENDP

CONTROL_END PROC Near

    	push CX
    	mov CX, 0
   	 mov CL, ES:[80h]
    	cmp CX, 0
	je no_end
   	inc CX

	mov BL, ES:[80h+1]
	cmp BL, '/'

	mov BL, ES:[80h+2]
	cmp BL, 'u'
	
	mov BL, ES:[80h+2]
	cmp BL, 'n'
	mov BL, 1
	jmp end_cont

    	no_end:
	mov BL, 0
	
    	end_cont:
	pop CX
	ret
CONTROL_END ENDP

USER_CHECK PROC

   	push ES
    	push BX
    	mov AH, 35h
    	mov AL, 1Ch
    	int 21h

    	mov AX, ES:[SIGNATURE]
    	cmp AX, 0714h
    	jne us_not
    	mov AL, 1
    	jmp us_endl

    	us_not:
    	mov AL, 0

    	us_endl:
    	pop BX
    	pop ES
   	 ret
USER_CHECK ENDP

STAND_INTERRUPT PROC

    	mov AH, 35h
    	mov AL, 1Ch
   	 int 21h

    	CLI
    	push DS

    	mov DX, ES:[KEEP_IP]
    	mov AX, ES:[KEEP_CS]
    	mov DS, AX
    	mov AL, 1Ch
    	mov AH, 25h
    	int 21h
    	pop DS

    	STI

    	mov AX, ES:[PSP_START]
    	mov ES, AX
    	push ES

    	mov AX, ES:[2Ch]
    	mov ES, AX
    	mov AH, 49h
    	int 21h
    	pop ES
    	mov AH, 49h
    	int 21h
    	ret
STAND_INTERRUPT ENDP

Main PROC FAR    
                        
   	push DS
   	sub AX, AX
    	push AX
    	mov AX, DATA
    	mov DS, AX

    	call USER_CHECK
    	call CONTROL_END

    	cmp AL, 1
    	je us
    	lea DX, WAS_STR

    	call PRINT
    	call SET_INTERRUPTION

    	jmp fin

    	us:
	lea DX, ALREADY_LOAD
	call PRINT
	cmp BL, 1
	jne fin
	
	lea DX, RESTORE_STR
	call PRINT
	call STAND_INTERRUPT

    	fin:
    	xor AL, AL
   	mov AH, 4Ch
    	int 21h
    
Main ENDP
CODE ENDS

END Main 

UNAVALIABLE_OFFSET EQU 2h
ENV_OFFSET EQU 2Ch
TAIL_LEN EQU 80h
TAIL_OFFSET EQU 81h
TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN

UNAVAIL_MEM db 'Unavaliable segment: 0000h',0DH,0AH,'$'
ENVIRONMENT_MSG db 'Environment segment: 0000h',0DH,0AH,'$'
CMD_LINE_TAIL db 'CMD Tail:',0DH,0AH,'$'
ENV_CONTENT db 'Environment Contents:',0DH,0AH,'$'
PATH db 'Path: ','$'
NEW_LINE db 0DH,0AH,'$'

;-----------------------------------------------------
TETR_TO_HEX PROC near
 and AL,0Fh
 cmp AL,09
 jbe NEXT
 add AL,07
NEXT: add AL,30h
 ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
 push CX
 mov AH,AL
 call TETR_TO_HEX
 xchg AL,AH
 mov CL,4
 shr AL,CL
 call TETR_TO_HEX
 pop CX ;в AH младшая
 ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
 push BX
 mov BH,AH
 call BYTE_TO_HEX
 mov [DI],AH
 dec DI
 mov [DI],AL
 dec DI
 mov AL,BH
 call BYTE_TO_HEX
 mov [DI],AH
 dec DI
 mov [DI],AL
 pop BX
 ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
 push CX
 push DX
 xor AH,AH
 xor DX,DX
 mov CX,10
loop_bd: div CX
 or DL,30h
 mov [SI],DL
 dec SI
 xor DX,DX
 cmp AX,10
 jae loop_bd
 cmp AL,00h
 je end_l
 or AL,30h
 mov [SI],AL
end_l: pop DX
 pop CX
 ret
BYTE_TO_DEC ENDP

PRINT PROC NEAR
	add di, dx
	call WRD_TO_HEX
	mov ah,09h
	int 21h
	ret
PRINT ENDP



PRINTSTR PROC NEAR
push ds
mov ax,es
mov ds,ax
mov ah,02h
_loop:
lodsb
mov dl,al
cmp dl,0
je _end
int 21h
loop _loop
_end:
pop ds

ret
PRINTSTR ENDP



BEGIN:

mov di,24
mov dx, offset UNAVAIL_MEM
mov ax, DS:[UNAVALIABLE_OFFSET]
call PRINT	

mov di,24
mov dx, offset ENVIRONMENT_MSG
mov ax, DS:[ENV_OFFSET]
call PRINT

mov ah,09h
mov dx, offset CMD_LINE_TAIL
int 21h

mov si, TAIL_OFFSET	; tail
mov cl, ds:[TAIL_LEN]
call PRINTSTR

mov ah,09h
mov dx, offset NEW_LINE
int 21h

mov ah,09h
mov dx, offset ENV_CONTENT
int 21h

mov cx, -1
mov si, 0
mov es, DS:[ENV_OFFSET]
_env_loop:
call PRINTSTR
mov ah,02h
mov dl,' '
int 21h
mov al,es:[si]
cmp al,0
jne _env_loop

mov ah,09h
mov dx, offset NEW_LINE
int 21h

mov ah,09h	;print path
mov dx, offset PATH
int 21h

add si,3
call PRINTSTR

 xor AL,AL

 mov ah,01h
 int 21h
 mov AH,4Ch
 int 21H
TESTPC ENDS
 END START
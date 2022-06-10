TESTPC SEGMENT

ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
ORG 100h

START: 
	jmp BEGIN

; data
FM db 'First byte of forbidden to modify memory:     h', 13,10, '$'
SE db 'segment of environment for process:     h', 13,10,'$'
CLT db 'CLT contains:                            ', 13,10,'$'
EMPTYCLT db 'Command-line tail is empty!', 13,10,'$'
CONTENT db 13,10,'Content:',13,10, '$'
ENDL db 13, 10, '$'
PATH db 13,10,'Path:  ',13,10,'$'

; procedures
TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP



BYTE_TO_HEX PROC near

   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;в AL старшая цифра
   pop CX ;в AH младшая
   ret
BYTE_TO_HEX ENDP

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


out_print PROC near
	mov AH,9h
	int 21h
	ret
out_print ENDP


GetForbiddenMemAdress PROC near
	mov ax, ds:[02h]
	mov di, offset FM
	add di, 2Dh
	call WRD_TO_HEX
	mov dx, offset FM
	call out_print
	ret
GetForbiddenMemAdress ENDP


GetSegEnvProcAdress PROC near
	mov ax, ds:[2Ch]
	mov di, offset SE
	add di, 27h
	call WRD_TO_HEX
	mov dx, offset SE
	call out_print
	ret
GetSegEnvProcAdress ENDP

GetCommandLineTail PROC near
	mov BX, 81h
	xor CX, CX
    mov CL, ES:[80h]
    cmp CL, 0
	je empty_cycle
	mov dx, offset CLT
	call out_print
	mov ah, 02h
	cycle:
		mov DL, ES:[BX]
	    int 21h
	    inc BX
	    loop cycle
	  
		mov DL, 0Dh
	    int 21h
	    mov DL, 0AH
	    int 21h
		jmp end_cycle
		empty_cycle:
			mov dx, offset EMPTYCLT
			call out_print
		end_cycle:
			ret
GetCommandLineTail ENDP


GetEnvContent PROC near
   mov dx, offset CONTENT
   call out_print
   sub di, di
   mov ds, ds:[2Ch]
next_line:
	cmp byte ptr [di], 00h
	je line_end
	mov dl, [di]
	mov ah, 02h
	int 21h
	jmp path_detected
line_end:
	cmp byte ptr [di+1],00h
	je path_detected
	push ds
	mov cx, cs
	mov ds, cx
	mov dx, offset ENDL
	call out_print
	pop ds
path_detected:
	inc di
	cmp word ptr [di], 0001h
	je content_end
	jmp next_line
content_end:
	ret
GetEnvContent ENDP


getPath PROC near
	push ds
	mov ax, cs
	mov ds, ax
	mov dx, offset PATH
	call out_print
	pop ds
	add di, 2
path_cyc:
	cmp byte ptr [di], 00h
	je complete
	
	mov dl, [di]
	mov ah, 02h
	int 21h
	
	inc di
	jmp path_cyc
complete:
	ret
getPath ENDP


; Code
BEGIN:
	call GetForbiddenMemAdress
	call GetSegEnvProcAdress
	call GetCommandLineTail
	call GetEnvContent
	call getPath
	xor AL,AL
	mov AH,4Ch
	int 21H

TESTPC ENDS
END START
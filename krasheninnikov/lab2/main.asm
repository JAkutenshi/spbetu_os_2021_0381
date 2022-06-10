TESTPC SEGMENT

ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
ORG 100h

START: 
	jmp BEGIN

; data
FB db 'First byte of forbidden to modify memory:     h', 13,10, '$'
S db 'segment of environment for process:     h', 13,10,'$'
CONTAINS db 'CLT contains:$'
EMPTY db 'Command-line tail is empty!', 13,10,'$'
CONTENT db 13,10,'Content:',13,10, '$'
END_OF_LINE db 13, 10, '$'
PATH db 13,10,'Path:  ',13,10,'$'

; Процедуры


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
;байт в AL переводится в два символа шест. числа в AX
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


output PROC near
	mov AH,9h
	int 21h
	ret
output ENDP


MEMADRESSFORB PROC near
	mov ax, ds:[02h]
	mov di, offset FB
	add di, 2Dh
	call WRD_TO_HEX
	mov dx, offset FB
	call output
	ret
MEMADRESSFORB ENDP



PROCADRESSENV PROC near
	mov ax, ds:[2Ch]
	mov di, offset S
	add di, 27h
	call WRD_TO_HEX
	mov dx, offset S
	call output
	ret
PROCADRESSENV ENDP



CMNDLINETAIL PROC near
    mov BX, 81h
    xor CX, CX
    mov CL, ES:[80h]
    cmp CL, 0
	je empty_tail 
	mov dx, offset CONTAINS
	call output
	mov ah, 02h
TAIL:
    mov DL, ES:[BX]
    int 21h
    inc BX
    loop TAIL
    
	mov DL, 0Dh
    int 21h
    mov DL, 0AH
    int 21h
	jmp ending
	empty_tail:
		mov dx, offset EMPTY
		call output
	ending:
		ret
CMNDLINETAIL ENDP



ENVCONTENT PROC near
   mov dx, offset CONTENT
   call output
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
	mov dx, offset END_OF_LINE
	call output
	pop ds
path_detected:
	inc di
	cmp word ptr [di], 0001h
	je content_end
	jmp next_line
content_end:
	ret
ENVCONTENT ENDP



PTH PROC near
	push ds
	mov ax, cs
	mov ds, ax
	mov dx, offset PATH
	call output
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
PTH ENDP



; Code
BEGIN:
	call MEMADRESSFORB
	call PROCADRESSENV
	call CMNDLINETAIL
	call ENVCONTENT
	call PTH
	xor AL,AL
	mov AH,4Ch
	int 21H

TESTPC ENDS
END START 

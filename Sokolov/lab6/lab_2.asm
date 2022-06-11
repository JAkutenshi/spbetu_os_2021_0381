TESTPC SEGMENT

ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
ORG 100h

START: 
	jmp BEGIN

; data
FMA db 'First byte of forbidden to modify memory:     h', 13,10, '$'
SEP db 'segment of environment for process:     h', 13,10,'$'
CLT db 'CLT contains:                            ', 13,10,'$'
EMPTYCLT db 'Command-line tail is empty!', 13,10,'$'
CONTENT db 13,10,'Content:',13,10, '$'
ENDL db 13, 10, '$'
PATH db 13,10,'Path:  ',13,10,'$'

; ���������
;-------------------------------

TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP

;-------------------------------

BYTE_TO_HEX PROC near
;���� � AL ����������� � ��� ������� ����. ����� � AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;� AL ������� �����
   pop CX ;� AH �������
   ret
BYTE_TO_HEX ENDP

;-------------------------------
WRD_TO_HEX PROC near
;������� � 16 �/� 16-�� ���������� �����
; � AX - �����, DI - ����� ���������� �������
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

;-------------------------------
printer PROC near
	mov AH,9h
	int 21h
	ret
printer ENDP
;-------------------------------

GetForbiddenMemAdress PROC near
	mov ax, ds:[02h]
	mov di, offset FMA
	add di, 2Dh
	call WRD_TO_HEX
	mov dx, offset FMA
	call printer
	ret
GetForbiddenMemAdress ENDP

;-------------------------------

GetSegEnvProcAdress PROC near
	mov ax, ds:[2Ch]
	mov di, offset SEP
	add di, 27h
	call WRD_TO_HEX
	mov dx, offset SEP
	call printer
	ret
GetSegEnvProcAdress ENDP

;-------------------------------

GetCommandLineTail PROC near
	sub al, al
	mov al, ds:[80h]
	cmp al, 0h
	je empty_tail
	mov si, offset CLT
	add si, 0Fh 
	cycle:
		cmp al, 0h
		je not_empty
		dec al
		mov bl, ds:[81h+di]
		inc di
		mov [si], bl
		inc si
	empty_tail:
		mov dx, offset EMPTYCLT
		jmp ending
	not_empty:
		mov dx, offset CLT
	ending:
		call printer
		ret
GetCommandLineTail ENDP

;-------------------------------

GetEnvContent PROC near
   mov dx, offset CONTENT
   call printer
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
	call printer
	pop ds
path_detected:
	inc di
	cmp word ptr [di], 0001h
	je content_end
	jmp next_line
content_end:
	ret
GetEnvContent ENDP

;-------------------------------

GetPath PROC near
	push ds
	mov ax, cs
	mov ds, ax
	mov dx, offset PATH
	call printer
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
GetPath ENDP

;-------------------------------

; Code
BEGIN:
	call GetForbiddenMemAdress
	call GetSegEnvProcAdress
	call GetCommandLineTail
	call GetEnvContent
	call GetPath
	xor AL,AL
	mov AH,4Ch
	int 21H

TESTPC ENDS
END START
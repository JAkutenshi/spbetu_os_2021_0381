TESTPC SEGMENT

ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
ORG 100h

START: 
	jmp BEGIN

; data
FM_a db 'First byte of forbidden to modify memory:     h', 13,10, '$'
SE_p db 'segment of environment for process:     h', 13,10,'$'
CL_t db 'CLT contains:                            ', 13,10,'$'
EMPTY_clt db 'Command-line tail is empty!', 13,10,'$'
cont db 13,10,'Content:',13,10, '$'
N db 13, 10, '$'
str db 13,10,'Path:  ',13,10,'$'

; Процедуры
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

;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
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
	mov di, offset FM_a
	add di, 2Dh
	call WRD_TO_HEX
	mov dx, offset FM_a
	call printer
	ret
GetForbiddenMemAdress ENDP

;-------------------------------

GetSegEnvProcAdress PROC near
	mov ax, ds:[2Ch]
	mov di, offset SE_p
	add di, 27h
	call WRD_TO_HEX
	mov dx, offset SE_p
	call printer
	ret
GetSegEnvProcAdress ENDP

;-------------------------------

GetCommandLineTail PROC near
	sub al, al
	mov al, ds:[80h]
	cmp al, 0h
	je empty_tail
	mov si, offset CL_t
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
		mov dx, offset EMPTY_clt
		jmp ending
	not_empty:
		mov dx, offset CL_t
	ending:
		call printer
		ret
GetCommandLineTail ENDP

;-------------------------------

GetEnvcont PROC near
   mov dx, offset cont
   call printer
   sub di, di
   mov ds, ds:[2Ch]
next_line:
	cmp byte ptr [di], 00h
	je line_end
	mov dl, [di]
	mov ah, 02h
	int 21h
	jmp str_detected
line_end:
	cmp byte ptr [di+1],00h
	je str_detected
	push ds
	mov cx, cs
	mov ds, cx
	mov dx, offset N
	call printer
	pop ds
str_detected:
	inc di
	cmp word ptr [di], 0001h
	je cont_end
	jmp next_line
cont_end:
	ret
GetEnvcont ENDP

;-------------------------------

Getstr PROC near
	push ds
	mov ax, cs
	mov ds, ax
	mov dx, offset str
	call printer
	pop ds
	add di, 2
str_cyc:
	cmp byte ptr [di], 00h
	je complete
	
	mov dl, [di]
	mov ah, 02h
	int 21h
	
	inc di
	jmp str_cyc
complete:
	ret
Getstr ENDP

;-------------------------------

; Code
BEGIN:
	call GetForbiddenMemAdress
	call GetSegEnvProcAdress
	call GetCommandLineTail
	call GetEnvcont
	call Getstr
	xor AL,AL
	mov AH,4Ch
	int 21H

TESTPC ENDS
END START
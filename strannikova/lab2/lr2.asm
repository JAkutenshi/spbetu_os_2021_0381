TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN
; ДАННЫЕ
UNAVAILABLE_MEM db 'Segment address of unavailable memory:     h$'
ENVIRONMENT db  'Segment address of the environment:     h$'
TAIL db  'Command Line Tail: $'
AREA db  'Contents of the environment area: $'
PATH db  'The path of the loaded module: $'
NEW_STRING db ' ',0DH,0AH,'$'
NO_SYMBOLS db 'no symbols$'

;ПРОЦЕДУРЫ
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
; байт в AL переводится в два символа шестн. числа в AX
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
;--------------------------------------------------
; КОД
; Вывод значений
PRINT_ENTER PROC NEAR
	mov DX, OFFSET NEW_STRING
	call OUTPUT
	ret
PRINT_ENTER ENDP
;--------------------------------------------
OUTPUT PROC near
	mov AH, 09h
	int 21h
	ret
OUTPUT ENDP	
;--------------------------------------------
unavailable_mem_sa PROC NEAR
	mov DI, OFFSET UNAVAILABLE_MEM 
	add DI, 42
	mov AX, DS:[2h]
	call WRD_TO_HEX
	mov DX, OFFSET UNAVAILABLE_MEM
	call OUTPUT
	call PRINT_ENTER
	ret
unavailable_mem_sa ENDP
;--------------------------------------------
environment_address PROC NEAR
	mov DI, OFFSET ENVIRONMENT 
	add DI, 39
	mov AX, DS:[2Ch]
	call WRD_TO_HEX
	mov DX, OFFSET ENVIRONMENT
	call OUTPUT
	call PRINT_ENTER
	ret
environment_address ENDP
;--------------------------------------------	
command_line_tail PROC NEAR
	mov DX, OFFSET TAIL
	call OUTPUT
	xor CX, CX
	mov CL, DS:[80h] ; количество символов в хвосте
	cmp CL, 0h
	je empty
	mov si, 81h
main_loop:
	mov DL, DS:[SI]
	call print_symbol
	inc SI
	loop main_loop
exit:
	call PRINT_ENTER
	ret
empty:
	mov DX, OFFSET NO_SYMBOLS
	call OUTPUT
	jmp exit
command_line_tail ENDP
;--------------------------------------------
print_symbol PROC NEAR
	push AX
	mov AH, 02H
	int 21h
	pop AX
	ret
print_symbol ENDP
;--------------------------------------------
environment_area_and_path PROC NEAR
	mov DX, OFFSET AREA
	call OUTPUT
	call PRINT_ENTER
	mov ES, DS:[2Ch]
	xor DI, DI
	mov AX, ES:[DI]
	cmp AX, 00h
	je finding_path 
	add DI, 2
reading:
	mov DL, AL
	call print_symbol
	mov AL, AH
	mov AH, ES:[DI]
	inc DI
	cmp AX, 00H
	jne reading
	
finding_path:
	mov DL, 0DH
	call print_symbol
	mov DL, 0AH
	call print_symbol
	mov DX, OFFSET PATH
	call OUTPUT
	add DI, 2
	mov DL, ES:[DI]
	inc DI
	
path_loop:
	call print_symbol
	mov DL, ES:[DI]
	inc DI
	cmp DL, 00H
	jne path_loop
	call PRINT_ENTER
	ret	
environment_area_and_path ENDP
;--------------------------------------------	
BEGIN:
	call unavailable_mem_sa
	call environment_address
	call command_line_tail
	call environment_area_and_path
; Выход в DOS
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
	END START 
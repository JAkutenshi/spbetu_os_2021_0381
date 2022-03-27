TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
   ORG 100H
START: JMP BEGIN
; Данные                 
AVAILABLE_MEMORY db 13,10,'Amount of available memory: $'
EXTENDED_MEMORY db 13,10,'Size of extended memory: $'
STR_BYTES db ' bytes $'
MCB_TYPE db 13,10,'MCB:0   $'
ADRESS db 'MCB Adress:        $'
OWNER db 'PSP owner address:       $'
AREA_SIZE db 'Area size: $'
MCB_SD_SC db 'SD/SC: $' 
NEWLINE db 0DH,0AH,'$'

; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-----------------------------------------------------
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
;-----------------------------------------------------
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
;-----------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
   push CX
   push DX
   xor AH,AH
   xor DX,DX
   mov CX,10
loop_bd:
   div CX
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
end_l:
   pop DX
   pop CX
   ret
BYTE_TO_DEC ENDP
;-----------------------------------------------------
PRINT_INFO PROC near
   push AX
   mov AH,09h
   int 21h
   pop AX
   ret
PRINT_INFO ENDP
;-------------------------------
CONVERT PROC
	xor cx, cx 
	mov bx, 10 
nxt:
	mov si, ax 
	mov ax, dx 
	xor dx, dx
	div bx 
	mov di, ax 
	mov ax, si 
	div bx 
	push dx 
	inc cx 
	mov dx, di 
	push ax
	or ax, dx
	pop ax
	jnz nxt
	
	; Вывод
	mov AH, 02h
output:
	pop DX 
    add DL, '0' 
    int 21h
	loop output
	
	ret
CONVERT ENDP
;-------------------------------
GET_EXTENDED_MEM PROC
	mov dx, offset EXTENDED_MEMORY
    call PRINT_INFO 
	
	mov al, 31h
    out 70h, al
    in al, 71h
    mov ah, al
    mov al, 30h
    out 70h, al
    in al, 71h

    mov bx,1024
    mul bx
	call CONVERT
	mov dx, offset STR_BYTES
    call PRINT_INFO
	
	ret
GET_EXTENDED_MEM ENDP
;-------------------------------
GET_AVAILABLE_MEM PROC
	mov dx, offset AVAILABLE_MEMORY
    call PRINT_INFO 
	
	mov ah, 48h
	mov bx, 0ffffh
	int 21h
	mov ax, bx
	
	mov bx, 16
    mul bx
	call CONVERT
	mov dx, offset STR_BYTES
    call PRINT_INFO 
	
	ret
GET_AVAILABLE_MEM ENDP
;-------------------------------
PRINT_CHAR PROC
	mov dl,es:[di+8]
	mov ah,02h
	int 21h
	inc di
	ret
PRINT_CHAR ENDP
;-------------------------------
GET_BLOCK_CHAIN PROC
	mov ah, 52h
	int 21h
	mov ax, es:[bx-2]
	mov es, ax
	xor cx, cx
	inc cx
paragraph:
	lea si, MCB_TYPE
	add si, 7
	mov al, cl
	push cx
	call BYTE_TO_DEC
	lea dx, MCB_TYPE
	call PRINT_INFO

	mov ax, es
	lea di, ADRESS
	add di, 16
	call WRD_TO_HEX
	lea dx, ADRESS
	call PRINT_INFO

	xor ah, ah
	mov al, es:[0]
	push ax
	mov ax, es:[1]
	lea di, OWNER
	add di, 22
	call WRD_TO_HEX
	lea dx, OWNER
	call PRINT_INFO
	mov ax, es:[3]	
	mov dx, offset AREA_SIZE
	call PRINT_INFO
	
	mov bx, 16
    mul bx
	call CONVERT
	mov dx, offset STR_BYTES
    call PRINT_INFO 
	mov dx, offset NEWLINE
    call PRINT_INFO 
	
	xor dx, dx
	lea dx , MCB_SD_SC 
	call PRINT_INFO
	mov cx, 8
	xor di, di
   
char_loop:
	call PRINT_CHAR
	loop char_loop
	
	mov ax, es:[3]	
	mov bx, es
	add bx, ax
	inc bx
	mov es,bx
	pop ax
	pop cx
	inc cx
	cmp al, 5Ah
	je exit
	cmp al, 4Dh 
	jne exit
	jmp paragraph

exit:
	ret
GET_BLOCK_CHAIN ENDP
;-------------------------------
; Код
BEGIN:
	call GET_AVAILABLE_MEM
	call GET_EXTENDED_MEM
	call GET_BLOCK_CHAIN

	mov dx, offset NEWLINE
    call PRINT_INFO
	
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
END START
TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
.386
 ORG 100H
START: 
JMP BEGIN
; ДАННЫЕ
AMOUNTAVAILABLEMEMORY db  'Amount of available memory: $'
MEMORYSIZE db 'Extended memory size: $'
MSB db  'Memory control blocks:',0DH,0AH,'$'
NUMBER_MSB db ' $'
TYPE_MSB db '  Type:   h$'
ADRESS_MSB db '  MSB adress:     h$'
ADRESS_PSP db '  PSP adress:     h$'
SIZE_MSB db '  MSB size: $'
TEXT db '  text: $'
S_ENTER db ' ',0DH, 0AH,'$'
S_BYTES db ' bytes $'
 
;ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX PROC near
 and AL,0Fh
 cmp AL,09
 jbe NEXT
 add AL,07
NEXT: 
	add AL,30h
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

OUTPUT PROC near	
   push ax
   mov ah,09h
   int 21h
   pop ax
   ret
OUTPUT ENDP

OUTPUT_SYMBOL PROC near
	push ax
	mov ah, 02H
	int 21h
	pop ax
	ret
OUTPUT_SYMBOL ENDP

OUTPUT_ENTER PROC near
	push dx
	mov dx, offset S_ENTER
	call OUTPUT
	POP dx
	ret
OUTPUT_ENTER ENDP

OUTINT proc  near
oi1:      
xor     cx, cx    
mov     ebx, 10
oi2:  
xor     dx,dx    
div     ebx
push    dx    
inc     cx    
test    eax, eax    
jnz     oi2 
mov     ah, 02h
oi3:
pop     dx
add     dl, '0'    
int     21h
loop    oi3        
ret  
ret  
OUTINT endp
OUTPUT_AVAILABLE_MEMORY PROC near
	mov dx, offset AMOUNTAVAILABLEMEMORY
	call OUTPUT
	mov ah, 48h	
	mov bx, 0ffffh
	int 21h
	mov ax, bx
	mov ebx, 16
	mul ebx
	call OUTINT
	mov dx, offset S_BYTES
	call OUTPUT
	call OUTPUT_ENTER
	ret
OUTPUT_AVAILABLE_MEMORY ENDP

OUTPUT_MEMORYSIZE PROC near
	mov dx, offset MEMORYSIZE
	call OUTPUT
	mov al,30h ; запись адреса ячейки CMOS
	out 70h,al
	in al,71h ; чтение младшего байта
	mov bl, al ; размера расширенной памяти
	mov al,31h ; запись адреса ячейки CMOS
	out 70h,al
	in al,71h 
	mov ebx, 1024
	mul ebx
	call OUTINT
	mov dx, offset S_BYTES
	call OUTPUT
	call OUTPUT_ENTER
	ret
OUTPUT_MEMORYSIZE ENDP

OUTPUT_MSB PROC near
	push es
	push di
	mov dx, offset MSB
	call OUTPUT
	mov ah, 52h 
	int 21h
	mov ax, es:[bx-2]
	mov es, ax
	xor cx, cx	
	push cx
output_block:
	mov dx, offset NUMBER_MSB
	call OUTPUT
	pop cx 
	inc cx
	push cx
	mov ax, cx
	call OUTINT
	
	mov di, offset TYPE_MSB
	add di, 8
	mov al, es:[0]
	call BYTE_TO_HEX
	mov [di], ax
	mov dx, offset TYPE_MSB
	call OUTPUT
	
	mov di, offset ADRESS_MSB
	add di, 17
	mov ax, es
	call WRD_TO_HEX
	mov dx, offset ADRESS_MSB
	call OUTPUT
	
	mov di, offset ADRESS_PSP
	add di, 17
	mov ax, es:[1]
	call WRD_TO_HEX
	mov dx, offset ADRESS_PSP
	call OUTPUT 

	mov dx, offset SIZE_MSB
	call OUTPUT
	mov ax, es:[3]
	mov ebx, 16
	mul ebx
	call OUTINT
	xor di, di
	mov cx, 8
	mov dx, offset TEXT
	call OUTPUT
test_output:
	mov dl, es:[di+8]
	call OUTPUT_SYMBOL
	inc di
	loop test_output
	
	call OUTPUT_ENTER
	mov al, es:[0]
	cmp al, 5Ah
	je exit
	mov ax, es
	add ax, es:[3]
	inc ax
	mov es, ax
	jmp output_block
	
exit:
	pop di
	pop es
	ret	
OUTPUT_MSB ENDP

; КОД
BEGIN:
	mov bx,4096
	mov AH,4ah
	int 21H
	mov bx,4096
	mov AH,48h
	int 21H
	call OUTPUT_AVAILABLE_MEMORY
	call OUTPUT_MEMORYSIZE
	call OUTPUT_MSB
; Выход в DOS
 xor AL,AL
 mov AH,4Ch
 int 21H
TESTPC ENDS
 END START ;конец модуля, START - точка входа
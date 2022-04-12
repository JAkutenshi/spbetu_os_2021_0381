LAB3 SEGMENT
 ASSUME CS:LAB3, DS:LAB3, ES:NOTHING, SS:NOTHING
.386
 ORG 100H
START: JMP BEGIN



;ДАННЫЕ
SIZE_AVAILABLE_MEMORY db  'Amount of available memory: $'
SIZE_EXTENDED_MEMORY db 'Extended memory size: $'
MEMORY_CONTROL_BLOCKS db  'Memory control blocks:',0DH,0AH,'$'
MCB_TYPE db 'Type:   h$'
MCB_ADRESS db '  MCB adress:     h$'
MCB_SIZE db '  MCB size: $'
PSP_ADRESS db '  PSP adress:     h$'
SC_SD db '  SCSD: $'
PRINT_ENTER db ' ',0DH, 0AH,'$'
PRINT_BYTES db ' bytes $'
 



;ПРОЦЕДУРЫ
;-------------------------------
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

;-------------------------------
BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX
	pop CX
	ret
BYTE_TO_HEX ENDP
;-------------------------------

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
;-------------------------------


;-------------------------------
PRINT PROC near	
   push AX
   mov AH,09h
   int 21h
   pop AX
   ret
PRINT ENDP
;-------------------------------

;-------------------------------
PRINT_SYM PROC near
	push AX
	mov AH, 02H
	int 21h
	pop AX
	ret
PRINT_SYM ENDP
;-------------------------------

;-------------------------------
PRINT_ENT PROC near
	push DX
	mov DX, OFFSET PRINT_ENTER
	call PRINT
	POP DX
	ret
PRINT_ENT ENDP
;-------------------------------

;-------------------------------
NEW_INTEGER PROC near      
	xor cx, cx    
	mov ebx, 10
m_1:  
	xor dx,dx    
	div ebx
	push dx    
	inc cx    
	test eax, eax    
	jnz m_1 
	mov ah, 02h
m_2:
	pop dx
	add dl, '0'    
	int 21h
	loop m_2        
	ret  
	ret  
NEW_INTEGER ENDP
;-------------------------------

;-------------------------------
PRINT_AVAIL_MEM PROC near
	mov dx, OFFSET SIZE_AVAILABLE_MEMORY
	call PRINT
	mov ah, 48h	
	mov bx, 0FFFFh
	int 21h
	mov ax, bx
	mov ebx, 16
	mul ebx
	call NEW_INTEGER
	mov dx, OFFSET PRINT_BYTES
	call PRINT
	call PRINT_ENT
	ret
PRINT_AVAIL_MEM ENDP
;-------------------------------

;-------------------------------
PRINT_MEM_SIZE PROC near
	mov dx, OFFSET SIZE_EXTENDED_MEMORY
	call PRINT
	mov al,30h
	out 70h,al
	in al,71h
	mov bl, al
	mov al,31h
	out 70h,al
	in al,71h 
	mov ebx, 1024
	mul ebx
	call NEW_INTEGER
	mov dx, OFFSET PRINT_BYTES
	call PRINT
	call PRINT_ENT
	ret
PRINT_MEM_SIZE ENDP
;-------------------------------

;-------------------------------
PRINT_MCB PROC near
	push es
	push di
	mov dx, OFFSET MEMORY_CONTROL_BLOCKS
	call PRINT
	mov ah, 52h 
	int 21h
	mov ax, es:[bx-2]
	mov es, ax

m_print_information:
	mov di, OFFSET MCB_TYPE
	add di, 6
	mov al, es:[0]
	call BYTE_TO_HEX
	mov [di], ax
	mov dx, OFFSET MCB_TYPE
	call PRINT
	
	mov di, OFFSET MCB_ADRESS
	add di, 17
	mov ax, es
	call WRD_TO_HEX
	mov dx, OFFSET MCB_ADRESS
	call PRINT
	
	mov di, OFFSET PSP_ADRESS
	add di, 17
	mov ax, es:[1]
	call WRD_TO_HEX
	mov dx, OFFSET PSP_ADRESS
	call PRINT 

	mov dx, OFFSET MCB_SIZE
	call PRINT
	mov ax, es:[3]
	mov ebx, 16
	mul ebx
	call NEW_INTEGER
	xor di, di
	mov cx, 8
	mov dx, OFFSET SC_SD
	call PRINT

m_print:
	mov dl, es:[di+8]
	call PRINT_SYM
	inc di
	loop m_print
	
	call PRINT_ENT
	mov al, es:[0]
	cmp al, 5Ah
	je exit
	mov ax, es
	add ax, es:[3]
	inc ax
	mov es, ax
	jmp m_print_information
	
exit:
	pop di
	pop es
	ret	
PRINT_MCB ENDP
;-------------------------------


;КОД
BEGIN:
	mov BX,4096
	mov AH,4ah
	int 21H
	call PRINT_AVAIL_MEM
	call PRINT_MEM_SIZE
	call PRINT_MCB

;Выход в DOS
 xor AL,AL
 mov AH,4Ch
 int 21H
LAB3 ENDS
 END START ;конец модуля, START - точка входа
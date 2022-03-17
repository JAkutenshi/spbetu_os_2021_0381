; Шаблон текста программы на ассемблере для модуля типа .COM
TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
; ДАННЫЕ
MCB_TYPE db 'MCB Type: $'
MCB_TEXT db ' Text: $'
MCB_RESERVED db 'Reserved: $'
FREE_BLOCK db 'Owner: free $'
NOTENOUGHMEM db 'Not enough memory',0DH,0AH,'$'
DOS_BLOCK db 'Owner: DOS $'
MCB_ADDR db ' MCB Address: 0000h $'
OWNER_ADDR db 'Owner: 0000h $'
AVALIABLE_MEM_MSG db 'Avaliable memory: $'
BLOCK_LEN_MSG db 'Length: $'
BYTES_MSG db ' bytes$'
EXTENDED_MEM_MSG db 'Extended memory: $'
NEWLINE db 0DH,0AH,'$'
;ADR db '0000h : $'
;LEN db '0000h',0DH,0AH,'$'
MCB db 16 dup()
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
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
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
;-------------------------------
; КОД

PRINT PROC NEAR ;ax-num di-offset ,dx-string
	push es
	push bx
	push ax
	mov bx,ds
	mov es,bx
	add di, dx
	call WRD_TO_HEX
	mov ah,09h
	int 21h
	pop ax
	pop bx
	pop es
	ret
PRINT ENDP



PRINTSTR PROC NEAR ;si-str cx-len
push es
mov ax,ds
mov es,ax
mov ah,02h
_loop:
lodsb
mov dl,al
cmp dl,0
je _end
int 21h
loop _loop
_end:
pop es

ret
PRINTSTR ENDP

NEXTMCB PROC
mov si, 0
_mcbcopyloop:
mov al, es:[si]
mov [si+offset MCB], al
inc si
cmp si,16
jl _mcbcopyloop
ret
NEXTMCB ENDP

TO_STR PROC NEAR 
	push DS
	mov CX, 0	; Обнуляем счетчик цифр
	mov AX, SS	; Назначаем сегмент стека как сегмент данных
	mov DS, AX	; Для использования si
	mov AX, 10	
	push AX		; Загружаем в стек делитель
	sub sp, 4	; Выделяем место для управляющего слова FPU и остатка от деления
	mov si,sp
	fstcw [si]	; Читаем управляющий регистр FPU
	pop AX
	and AX, 0F3FFh	
	or AX , 0400h	; устанавливаем округление вниз
	push AX
	fclex			;Сбрасываем исключения FPU
	fldcw [si]		;Загружаем управляющее слово FPU
	add si,2		;Устанавливаем индекс на остаток
	pop AX
	fild word ptr[si+2]	;Загрузка делителя
	fild dword ptr[si+8]	;Загрузка делимого(отсчеты таймера)
	_divloop:
	inc CX		;Считаем цифры
	FPREM		;Вычисляем остаток
	fistp word ptr[si]	;Сохраняем остаток
	fild dword ptr[si+8]	;Загружаем делимое
	fidiv word ptr[si+2]	;Делим на 10
	fist dword ptr[si+8]	; Сохраняем обратно в стек
	mov DX ,[si]	; Получаем остаток
	add DL,'0'		; Переводим в символ
	push DX			;Добавляем на вершину стека
	mov AX,[si+8]	
	or AX,[si+10]	; Проверяем частное на равенство нулю
	cmp AX, 0
	jne _divloop	; Если не ноль - повторяем деление
	_print:
	pop DX		; Достаем цифру из стека
	mov AH,02h	
	int 21h		; Печатаем символ
	loop _print	; Пока CX>0 повторяем
	add sp,4	; Удаляем из стека остаток и делитель
	pop DS		;Восстанавливаем сегмент

	ret
TO_STR ENDP

PRINT_AVALIABLE_MEM PROC NEAR
	mov bx,0ffffh
	mov AH,48h
	int 21H	
	mov ax,bx
	
	mov bx,16
	mul bx
	
	push dx
	push ax
	
	mov dx, offset AVALIABLE_MEM_MSG
	mov ah,09h
	int 21h
	
	call TO_STR	 
	add sp, 4
	
	mov dx, offset BYTES_MSG
	mov ah,09h
	int 21h
	mov dx, offset NEWLINE
	mov ah,09h
	int 21h
	ret
PRINT_AVALIABLE_MEM ENDP

PRINT_EXTENDED_MEM PROC NEAR
	;читаем расширенную память
	mov al,31h
	out 70h,al
	in al,71h
	mov ah,al
	
	mov al,30h
	out 70h,al
	in al,71h
	
	mov bx,1024
	mul bx
	
	push dx
	push ax
	
	mov dx, offset EXTENDED_MEM_MSG
	mov ah,09h
	int 21h
	
	call TO_STR	 
	add sp, 4
	
	mov dx, offset BYTES_MSG
	mov ah,09h
	int 21h
	mov dx, offset NEWLINE
	mov ah,09h
	int 21h
	ret
PRINT_EXTENDED_MEM ENDP

PRINT_MCB_BYTE PROC NEAR ;dx- msg 
push ax
	mov ah, 0
	mov al, MCB[si]
	call BYTE_TO_HEX
	mov bx,ax
	;mov dx, offset MCB_TYPE
	mov ah, 09h
	int 21h

	mov dl,bl		
	mov AH,02h	
	int 21h	
	
	mov dl,bh		
	mov AH,02h	
	int 21h	
	
	mov dl,'h'		
	mov AH,02h	
	int 21h	
	
	;mov dx, offset NEWLINE
	;mov ah, 09h
	;int 21h
	
	pop ax
	ret
PRINT_MCB_BYTE ENDP

PRINT_MCB_LEN PROC NEAR
	mov ax, MCB[03h]
	mov bx,16
	mul bx
	
	push dx
	push ax
	
	mov dx, offset BLOCK_LEN_MSG
	mov ah,09h
	int 21h
	
	call TO_STR	 
	add sp, 4
	
	mov dx, offset BYTES_MSG
	mov ah,09h
	int 21h
	
	mov dx, offset NEWLINE
	mov ah,09h
	int 21h
	
	ret
PRINT_MCB_LEN ENDP


PRINT_MCB PROC NEAR	
	push ax
	mov dx, offset MCB_TYPE
	mov si,0
	call PRINT_MCB_BYTE
	
	
	mov ax, es
	mov di, 17
	mov dx, offset MCB_ADDR
	call PRINT
		
	mov ax, MCB[01h]
	cmp ax,0
	je _freeblock
	cmp ax,8
	je _dosblock
	
	mov di, 10
	mov dx, offset OWNER_ADDR
	call PRINT
	jmp	_printlen
	_freeblock:	
	mov dx, offset FREE_BLOCK
	mov ah,09h
	int 21h
	jmp	_printlen
	_dosblock:
	mov dx, offset DOS_BLOCK
	mov ah,09h
	int 21h
	jmp	_printlen

	_printlen:	
	
	call PRINT_MCB_LEN
	
	mov dx, offset MCB_RESERVED
	mov si,5
	call PRINT_MCB_BYTE
	
	
	mov dx, offset MCB_TEXT
	mov ah, 09h
	int 21h
	
	mov si, offset MCB+8
	mov cx, 8
	call PRINTSTR
	
	
	pop ax
	ret
PRINT_MCB ENDP

BEGIN:
; освобождаем память
;mov bx,4096
;mov AH,4ah
;int 21H

;mov bx,4096
;mov AH,48h
;int 21H
jnc _jc
mov dx, offset NOTENOUGHMEM
mov ah, 09h
int 21h
_jc:
call PRINT_AVALIABLE_MEM
call PRINT_EXTENDED_MEM

mov AH,52h
int 21H

mov ax, es:[bx-2]
mov es,ax
mov ax, es:[0000h]
jmp first
_readblock:

mov dx, offset NEWLINE
mov ah, 09h
int 21h
first:
call NEXTMCB
 
mov ax,es

call PRINT_MCB

push ax

pop ax

inc ax
add ax, MCB[03h]
mov es,ax


mov al, MCB[00h]
cmp al, 5ah 
jne _readblock
mov ax,ds
mov es,ax
; Выход в DOS

 xor AL,AL
 mov AH,4Ch
 int 21H
TESTPC ENDS
 END START ;конец модуля, START - точка входа
AStack    SEGMENT  STACK
          DW  200 DUP(?)
AStack    ENDS

DATA      SEGMENT
ALREADY_INSTALLED db   'User interruption has already installed.', 13,10, '$' 
NOW_INSTALL      db 'User interruption is installed now', 13,10, '$' 
NOT_INSTALL      db 'User interruption is not installed', 13,10, '$' 
UNLOAD_INTERRUPT db 'Unload interruption', 13,10, '$' 
UNLOAD_MESSAGE   db   ' /un$'  
DATA      ENDS

CODE      SEGMENT
        ASSUME DS:DATA, CS:CODE, SS:AStack	
;функция вывода символа из AL
CONVERSION proc 
	push ax
	push bx
	push cx
	push dx
	push di
oi1:      
	xor     cx, cx    
	mov     bx, 10
oi2:  
	xor     dx,dx    
	div     bx
	push    dx    
	inc     cx    
	test    ax, ax    
	jnz     oi2 
oi3:
	pop ax
	add al, '0' 
	mov [di], al
	inc di
	loop    oi3 
	pop di
 	pop dx
	pop cx
	pop bx
	pop ax
	ret
CONVERSION endp

OUTPUT PROC near
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
OUTPUT ENDP

;функция вывода строки по адресу ES:BP на экран
OUTPUT_STR proc
	push ax
	push bx
	push dx
	push cx
	mov ah,13h ; функция
	mov al,1 ; sub function code
	mov bh,0 ; видео страница
	mov dh,0 ; DH,DL = строка, колонка (считая от 0)
	mov dl,0
	int 10h
	pop cx
	pop dx
	pop bx
	pop ax
	ret
OUTPUT_STR endp

SET_CURS proc
	push ax
	push bx
	push dx
	push cx
	mov ah,02h
	mov bh,0
	int 10h ; выполнение.
	pop cx
	pop dx
	pop bx
	pop ax
	ret
SET_CURS endp

GET_CURS proc
	push ax
	push bx
	push cx
	mov ah,03h
	mov bh,0
	int 10h
	pop cx
	pop bx
	pop ax
	ret
GET_CURS endp

NEW_INTERRUPTION PROC FAR ;не дописано
	jmp start
	MESSAGE db 'Count timer signals:      $'
	SIGNATURE dw 6789h
	OLD_INT   dd    0 
	PSP_ADDRESS dw ?
	COUNT dw 0
	OLD_SS    dw 0
	OLD_SP    dw 0
	OLD_AX    dw 0
	NEW_STACK     dw 16 dup(?)	
start:
	mov OLD_SP, sp
	mov OLD_AX, ax
	mov ax, ss
	mov OLD_SS, ax
	mov ax, OLD_AX
	mov ax, SEG MESSAGE
	mov ds, ax
	mov sp, offset start
	mov ax, seg NEW_STACK
	mov ss, ax
	mov di, offset MESSAGE
	add di, 21
	push ax
	push di
	push ds
	mov ax, COUNT
	cmp COUNT, 0ffffh
	jne next
	mov ax, 0
next:
	inc ax
	mov COUNT, ax
	call CONVERSION
	push es
	push bx
	push cx
	push bp
	push dx
	call GET_CURS
	push dx
	mov dx, 0
	call SET_CURS
	mov ax, seg MESSAGE
	mov es, ax
	mov bp, offset MESSAGE
	mov cx, 26
	call OUTPUT_STR
	pop dx
	call SET_CURS
	pop dx
	pop bp
	pop cx
	pop bx
	pop es
	pop ds
	pop di
	pop ax
	mov OLD_AX, AX
	mov sp, OLD_SP
	mov ax, OLD_SS
	mov ss, ax
	mov ax, OLD_AX
	mov AL, 20H  ; загрузка в регистр ISR кода 20
	out 20H, AL  ;для разрешения прерываний более низкого уровня
	IRET
end_int:
NEW_INTERRUPTION ENDP
	
CHECK_TAIL PROC near
	push cx
	push si
	push di
	push dx
	mov cx, 0
	mov cl, es:[80h]
	cmp cl, 4
	jne false
	mov si, 0
	mov di, 81h
cycle:
	mov dl, es:[di]
	cmp dl, UNLOAD_MESSAGE[si]
	jne false
	inc di
	inc si
	loop cycle
	mov al, 0
	jmp exit
false: 
	mov al, 1
exit:
	pop dx
	pop di
	pop si
	pop cx
	ret
CHECK_TAIL ENDP	

CHECK_INSTALL PROC near	
	push ax
	push es
	push bx
	push si
	mov cl, 0h
	mov ah, 35H  ; функция для получения вектора
	mov al, 1CH  ; номер вектора
	int 21H 
	mov si, offset SIGNATURE
	sub si, offset NEW_INTERRUPTION
	mov ax, es:[bx+si]
	cmp ax, SIGNATURE
	jne exit_check
	mov cl, 1h
exit_check:
	pop si
	pop bx
	pop es
	pop ax
	ret
CHECK_INSTALL ENDP

UNLOAD PROC NEAR
	push cx
	push dx
	push ax
	call CHECK_INSTALL
	cmp cl, 0
	je no_install
	CLI      ; отключение реакции на внешние прерывания
	push ds  ; сохраняем в стек адрес смещения данных
	mov AH, 35h
	mov AL, 1Ch
	int 21h
	mov dx, es:[word ptr OLD_INT]  ;  в DX адрес смещения обработчика прерывания
	mov ax, es:[word ptr OLD_INT+2] ; в DS адрес сегмента
	mov ds, ax  ; старого обработчика прерывания
	mov ah, 25H   ; функция установки вектора
	mov al, 1CH   ; номер вектора
	int 21H   ; восстанавливает исходное прерывание
	mov AX, ES:[PSP_ADDRESS]
	mov ES, AX
	push ES
	mov AX, ES:[2Ch]
	mov ES, AX
	mov AH, 49h
	int 21h
	pop ES
	mov AH, 49h
	int 21h
	pop ds   ; возвращаем изначальный адрес сегмента данных
	STI  ;восстановление реакции на внешние прерывания
	mov dx, offset UNLOAD_INTERRUPT
	call OUTPUT
	jmp exit_unload
no_install:
	mov dx, offset NOT_INSTALL
	call OUTPUT
exit_unload:
	pop ax
	pop dx
	pop cx
	ret
UNLOAD ENDP	

DONT_UNLOAD PROC NEAR
	push cx
	push dx
	push ax
	call CHECK_INSTALL
	cmp cl, 0
	je no_install_now
	mov dx, offset ALREADY_INSTALLED
	call OUTPUT
	jmp exit_dont_unload
no_install_now:
	mov PSP_ADDRESS, ES
	mov AH, 35H  ; функция для получения вектора
	mov AL, 1CH  ; номер вектора
	int 21H     ; помещает в регистр ES помещает значение сегмента обработчика прерывания 16h, а в BX его смещение
	mov word ptr OLD_INT, BX  ;сохраняем смещение
	mov word ptr OLD_INT+2, ES ; сохраняем адрес сегмента
    push  DS   ; сохраняем в стек адрес смещения данных
	push es
	push bx
	mov DX, OFFSET NEW_INTERRUPTION   ; сохраняем смещение нового обработчика прерывания(процедуры)
	mov AX, SEG NEW_INTERRUPTION   ; инициализируем регистр данных
	mov DS, AX   ; сегментом нового обработчика
	mov AH, 25H  ; функция установки вектора
	mov AL, 1CH  ; номер вектора
    int 21h   ; изменяем прерывание
	pop bx
	pop es
	pop DS  ; возвращаем изначальный адрес сегмента данных
	mov dx, offset NOW_INSTALL
	call OUTPUT
	mov dx, offset end_int
	mov cl, 4
	shr dx, cl
	inc dx
	mov ax, cs
	sub ax, PSP_ADDRESS
	add dx, ax
	xor ax, ax
	mov ah, 31h
	int 21h
exit_dont_unload:
	pop ax
	pop dx
	pop cx
	ret
DONT_UNLOAD ENDP
Main      PROC  FAR
begin:
	mov ax, DATA  
	mov ds, ax	
	call CHECK_TAIL
	cmp al, 1 ;false
	je install_now ; не выгружаем
	call UNLOAD  
	jmp end_main
install_now:	
	call DONT_UNLOAD
end_main:	; Выход в DOS
	xor AL,AL
	mov AH,4Ch
	int 21H 
Main      ENDP
CODE      ENDS
          END Main
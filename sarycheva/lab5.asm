AStack    SEGMENT  STACK
          DW  128 DUP(?)
AStack    ENDS

DATA      SEGMENT
ALREADY_INSTALLED db   'User interruption has already installed.', 13,10, '$' 
NOW_INSTALL      db 'User interruption is installed now', 13,10, '$' 
NOT_INSTALL      db 'User interruption is not installed', 13,10, '$' 
UNLOAD_INTERRUPT db 'Unload interruption', 13,10, '$' 
UNLOAD_MESSAGE   db   ' /un$'  
DATA      ENDS

CODE      SEGMENT
        ASSUME DS:DATA, CS:CODE, SS:AStack,  ES:NOTHING


OUTPUT PROC near
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
OUTPUT ENDP


NEW_INTERRUPTION PROC FAR
	jmp start
	REQ_KEY db 38h
	SIGNATURE dw 6789h
	KEEP_IP dw ?
	KEEP_CS dw ?
	PSP_ADDRESS dw ?
	COUNT dw 0
	OLD_SS    dw 0
	OLD_SP    dw 0
	OLD_AX    dw 0
	NEW_STACK     dw 64 dup()	
start:
	mov OLD_SS, ss
	mov OLD_SP, sp
	mov OLD_AX, ax
	mov ax, cs
	mov ss, ax
	mov sp, offset start
	push bx
	push cx
	push dx
	push ds
	
	in al,60H 
	cmp al,REQ_KEY 
	je do_req 
	call dword ptr cs:KEEP_IP 
	jmp end_func
do_req: 
	in al,61H ;взять значение порта управления клавиатурой
	mov ah,al ; сохранить его
	or al,80h ;установить бит разрешения для клавиатуры
	out 61H,al ; и вывести его в управляющий порт
	xchg ah,al ;извлечь исходное значение порта
	out 61H,al ;и записать его обратно
	mov al,20H ;послать сигнал "конец прерывания"
	out 20H,al ; контроллеру прерываний 8259
write:
	mov ah,05h ; Код функции
	mov cl,'S' ; Пишем символ в буфер клавиатуры
	mov ch,00h 
	int 16h 
	or al,al 
	jz end_func 
	mov ah, 0ch
	mov al, 00h
	int 21h
	jmp write
		
end_func:
	pop ds
	pop dx
	pop cx
	pop bx
	
	mov ax, OLD_AX
	mov ss, OLD_SS
	mov sp, OLD_SP
	mov al, 20H  ; загрузка в регистр ISR кода 20
	out 20H, al  ;для разрешения прерываний более низкого уровня
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
	mov al, 09H  ; номер вектора
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
	mov ah, 35h
	mov al, 09h
	int 21h
	mov dx, es:[KEEP_IP]  ;  в DX адрес смещения обработчика прерывания
	mov ax, es:[KEEP_CS] ; в DS адрес сегмента
	mov ds, ax  ; старого обработчика прерывания
	mov ah, 25H   ; функция установки вектора
	mov al, 09H   ; номер вектора
	int 21H   ; восстанавливает исходное прерывание
	pop ds
	mov ax, es:[PSP_ADDRESS]
	mov es, ax
	push es
	mov ax, es:[2Ch]
	mov es, ax
	mov ah, 49h
	int 21h
	pop es
	mov ah, 49h
	int 21h
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
	mov PSP_ADDRESS, es
	mov ah, 35H  ; функция для получения вектора
	mov al, 09H  ; номер вектора
	int 21H     ; помещает в регистр ES помещает значение сегмента обработчика прерывания 16h, а в BX его смещение
	mov KEEP_IP, bx  ;сохраняем смещение
	mov KEEP_CS, es ; сохраняем адрес сегмента
    push ds   ; сохраняем в стек адрес смещения данных
	lea dx, NEW_INTERRUPTION   ; сохраняем смещение нового обработчика прерывания(процедуры)
	mov ax, SEG NEW_INTERRUPTION   ; инициализируем регистр данных
	mov ds, ax   ; сегментом нового обработчика
	mov ah, 25H  ; функция установки вектора
	mov al, 09H  ; номер вектора
    int 21h   ; изменяем прерывание
	pop ds  ; возвращаем изначальный адрес сегмента данных
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
	cmp al, 1 
	je install_now 
	call UNLOAD  
	jmp end_main
install_now:	
	call DONT_UNLOAD
end_main:	; Выход в DOS
	xor al,al
	mov ah,4Ch
	int 21H 
Main      ENDP
CODE      ENDS
          END Main
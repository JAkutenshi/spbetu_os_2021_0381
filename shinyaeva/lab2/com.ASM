TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING    
   ORG 100H    ;так как адресация начинается со смещением 100 в .com
START: JMP BEGIN      ;точка входа (метка)

; Данные
MEMORY db  'Memory segment:     ',0DH,0AH,'$'       ;сегментный адрес недоступной памяти
MEDIA db 'Segment media address:    ',0DH,0AH,'$'   ;сегментный адрес среды
TAIL db 'Tail of command line:    ',0DH,0AH,'$'     ;хвост коммандной строки
EMPTY db 'Tail of command line: [EMPTY]',0DH,0AH,'$';пустой хвост
CONTENT db 'Environment scope content:',0DH,0AH, '$'
END_STRING db 0DH,0AH, '$'
PATH db 'Path:  ',0DH,0AH, '$'

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

F1 PROC near
    mov ax, ds:[02h]     

    mov di, offset MEMORY
    add di, 19
    call WRD_TO_HEX
    mov dx, offset MEMORY
    mov AH,09h
    int 21h
    ret
F1 ENDP

F2 PROC near
    mov ax, ds:[2Ch]     

    mov di, offset MEDIA
    add di, 25
    call WRD_TO_HEX
    mov dx, offset MEDIA
    mov AH,09h
    int 21h
    ret
F2 ENDP

F3 PROC near
    mov cx, 0
    mov cl, ds:[80h]   
    mov si, offset TAIL
    add si, 22
    cmp cl, 0          ;если пусто
    je empty_tail 
    mov di, 0
    mov ax, 0
read_tail: 
    mov al, ds:[81h+di]
    inc di
    mov [si], al
    inc si
    loop read_tail     ;цикл считывания

    mov dx, offset TAIL
    jmp write_tail
empty_tail:
    mov dx, offset EMPTY
write_tail: 
    mov AH,09h
    int 21h
    ret
F3 ENDP

F4 PROC near
    mov dx, offset CONTENT
    mov AH,09h
    int 21h
    mov di, 0
    mov ds, ds:[2Ch]
read_str:
    cmp byte ptr [di], 0
    je end_str
    mov dl, [di]
    mov ah, 02h
    int 21h
    jmp find_end
end_str:
    cmp byte ptr [di+1],00h
    je find_end
    push ds
    mov cx, cs
    mov ds, cx
    mov dx, offset END_STRING
    mov AH,09h
    int 21h
    pop ds
find_end:
    inc di
    cmp word ptr [di], 0001h
    je read_path
    jmp read_str
read_path:
    push ds
    mov ax, cs
    mov ds, ax
    mov dx, offset PATH
    mov AH,09h
    int 21h
    pop ds
    add di, 2
loop2:
    cmp byte ptr [di], 0
    je break
    mov dl, [di]
    mov ah, 02h
    int 21h
    inc di
    jmp loop2
break:
    ret
F4 ENDP

; Код
BEGIN:
    call F1    ;определение адреса недоступной памяти
    call F2    ;определение сегментного адреса среды
    call F3    ;определение хвоста
    call F4    ;получает содержимое области среды и путь

    xor AL,AL
    mov AH,4Ch
    int 21H
TESTPC ENDS
END START; конец модуля, START - точка выхода
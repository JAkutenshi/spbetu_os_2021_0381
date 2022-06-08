MAIN    SEGMENT
        ASSUME CS:MAIN, DS:MAIN, SS:NOTHING
        ORG 100H

START:  JMP BEGIN
; DATA
UNAVAILABLE_ADDRESS db 'Unavailable memory address: $'
ENVIROMENT_ADDRESS db 'Enviroment address: $'
COMMAND_LINE_EDGE db 'End of command line: $'
NO_COMMAND_LINE_EGDE db 'End of command line is empty',10,13,'$'
ENVIDOMENT_DATA db 'Enviroment data: $'
MODULE_PATH db 'Loaded module path: $'
ENDL db 13,10,'$'

; PROCEDURES
TETR_TO_HEX     PROC    near
        and     AL, 0Fh
        cmp     AL, 09
        jbe     NEXT
        add     al,07
NEXT:   add     al, 30h
        ret
TETR_TO_HEX     ENDP
;--------------------------
BYTE_TO_HEX     PROC    near   
; input:        AL=F8h (число)
; output:       AL={f}, AH={8} (в фигурных скобках символы)
;
; переводит AL в два символа в 16-й сс в AX
; в AL находится старшая, в AH младшая цифры
        push    cx
        mov     ah,al
        call    TETR_TO_HEX
        xchg    al,ah
        mov     cl,4
        shr     al,cl
        call    TETR_TO_HEX
        pop     cx
        ret
BYTE_TO_HEX     ENDP

WRITE_AL_HEX PROC NEAR
        push ax
        push dx
        call BYTE_TO_HEX

        mov dl, al
        mov al, ah
        mov ah, 02h
        int 21h

        mov dl, al
        int 21h
        pop dx
        pop ax
        ret
WRITE_AL_HEX ENDP


PRINT_MSG MACRO msg
	push ax
    push dx
    mov DX, offset msg
    mov AH, 09h
    int 21h
    pop dx
    pop ax
ENDM

;--------------------------
; CODE
BEGIN:

    ; Сегментный адрес недоступной памяти
    PRINT_MSG UNAVAILABLE_ADDRESS
    mov bx, ds:[02h]
    mov al, bh
    call WRITE_AL_HEX
    mov al, bl
    call WRITE_AL_HEX
    PRINT_MSG ENDL
    
    ; Сегментный адрес среды
    PRINT_MSG ENVIROMENT_ADDRESS

    mov bx, ds:[2Ch]
    mov al, bh
    call WRITE_AL_HEX
    mov al, bl
    call WRITE_AL_HEX
    PRINT_MSG ENDL

    ; Хвост командной строки в символьном виде
    mov ch, 0h
    mov cl, ds:[80h]

    cmp cl, 0
    je no_edge
    
    PRINT_MSG COMMAND_LINE_EDGE

    mov bx, 0
edge_loop:
    mov dl, ds:[81h+bx]
    mov ah, 02h
    int 21h

    inc bx
    loop edge_loop

    PRINT_MSG ENDL
    jmp enviroment_data

no_edge:
    PRINT_MSG NO_COMMAND_LINE_EGDE

enviroment_data:
    ; Вывод данных области среды
    PRINT_MSG ENVIDOMENT_DATA
	PRINT_MSG ENDL
    mov es, ds:[2Ch]
    mov bx, 0
    print_env_variable:
        mov dl, es:[bx]

        cmp dl, 0
        je variable_end

        mov ah, 02h
        int 21h
        inc bx
        jmp print_env_variable
    variable_end:
        mov dl, es:[bx+1]
        PRINT_MSG ENDL
        cmp dl, 0
        je enviroment_end

        inc bx
        jmp print_env_variable
enviroment_end:
    ; Вывод пути загружаемого модуля
    PRINT_MSG MODULE_PATH

    add bx, 3
    path_loop:
        mov dl, es:[bx]
        cmp dl, 0
        jne print_path_byte
        cmp byte ptr es:[bx+1], 0
        je path_end
    print_path_byte:
        mov ah, 02h
        int 21h
        inc bx
        jmp path_loop
path_end:


; Выход в DOS
dos_exit:
        xor     al,al
        mov     ah,4Ch
        int     21h
MAIN    ENDS
        END START

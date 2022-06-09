un_offset equ 2h
env_offset equ 2ch
tail_size equ 80h
tail_offset equ 81h
programm segment
  assume cs:programm, ds:programm, es:nothing, ss:nothing
  org 100h
start: jmp begin

mem_seg db 'Lock memory adress: 0000h', 0dh,0ah,'$'
seg_prog db 'Environment segment adress: 0000h', 0dh,0ah,'$'
cmd_tail db 'Command line tail:   ', 0dh, 0ah, '$'
empty_cmd_tail db 'Command line tail is empty', 0dh,0ah,'$'
space_symb db 'Environment symbols:', 0dh, 0ah, '$'
modul_path db 'Modul path: $'
line db 0dh,0ah,'$'

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

print proc near
  add di, dx
  call WRD_TO_HEX
  mov ah,09h
  int 21H
  ret
print endp

endline proc near
  mov dl,0dh
  int 21H
  mov dl, 0ah
  int 21h
  ret
endline endp

print_str proc
  push ds
  mov ax,es
  mov ds,ax
  mov ah,02h
  cycle:
  lodsb
  mov dl,al
  cmp dl,0
  je p_end
  int 21h
  loop cycle
  p_end:
  pop ds
  ret
print_str endp

begin:
;1
    mov di,23
    mov dx, offset mem_seg
    mov ax,ds:[un_offset]
    call print
;2
    mov di,31
    mov dx, offset seg_prog
    mov ax,ds:[env_offset]
    call print

    mov ah,09h
    mov dx, offset cmd_tail
    int 21h

    mov si, tail_offset
    mov cl, ds:[tail_size]
    call print_str

    mov ah,09h
    mov dx,offset line
    int 21h

    mov ah,09h
    mov dx,offset space_symb
    int 21h

    mov cx, -1
    mov si, 0
    mov es, ds:[env_offset]
    cycle_env:
    call print_str
    mov ah,02h
    mov dl,' '
    int 21h
    mov al,es:[si]
    cmp al,0
    jne cycle_env

    mov ah,09h
    mov dx,offset line
    int 21h

    mov ah,09h
    mov dx,offset modul_path
    int 21h

    add si,3
    call print_str
; Выход в DOS
xor AL,AL

;модификация
mov ah,08h
int 21h

mov AH,4Ch
int 21H
programm ends
end start
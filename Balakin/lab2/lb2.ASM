programm segment
  assume cs:programm, ds:programm, es:nothing, ss:nothing
  org 100h
start: jmp begin

mem_seg db 'Lock memory adress:     h', 0dh,0ah,'$'
seg_prog db 'Environment segment adress:     h', 0dh,0ah,'$'
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

begin:
;1
    mov ax, ds:[2]
    mov di, offset mem_seg
    add di, 23
    call WRD_TO_HEX
    mov dx, offset mem_seg
    call print
;2
    mov ax, ds:[2ch]
    mov di, offset seg_prog
    add di, 31
    call WRD_TO_HEX
    mov dx, offset seg_prog
    call print
;3
    xor cx,cx
    mov cl, ds:[80h]
    mov si, offset cmd_tail
    add si,21
    cmp cl,0
    je p2
    xor di,di
    xor ax,ax
    p1:
      mov al, ds:[81h+di]
      inc di
      mov [si],al
      inc si
      loop p1
      mov dx, offset cmd_tail
      jmp pend
    p2:
      mov dx,offset empty_cmd_tail
    pend:
      call print

;4,5
    mov dx,offset space_symb
    call print
    xor di,di
    mov ds, ds:[2ch]
    r:
      cmp byte ptr [di], 00h
      jz e_s
      mov dl, [di]
      mov ah, 02h
      int 21h
      jmp fe
    e_s:
      cmp byte ptr [di+1],00h
      jz fe
      push ds
      mov cx,cs
      mov ds,cx
      mov dx, offset line
      call print
      pop ds
    fe:
      inc di
      cmp word ptr [di], 001h
      jz rp
      jmp r
    rp:
      push ds
      mov ax,cs
      mov ds,ax
      mov dx, offset modul_path
      call print
      pop ds
      add di,2
    lp:
      cmp byte ptr[di],00h
      jz f
      mov dl, [di]
      mov ah, 02h
      int 21h
      inc di
      jmp lp
    f:

; Выход в DOS
xor AL,AL
mov AH,4Ch
int 21H
programm ends
end star
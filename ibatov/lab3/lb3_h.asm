prog segment
assume cs:prog, ds:prog, es:nothing, ss:nothing
org 100h
start: jmp begin

available_mem db 'available memory:  $'
extended_mem db 'Extended memory:  $'
bytes db ' bytes$'
mcb_type db 'MCB Type: $'
mcb_text db ' SD/SC: $'
mcb_addres db ' MCB Address: 0000h $'
block_size db 'Size: $'
owner db 'Owner:       $'
mcb_reserved db 'Reserved:  $'
free db 'free'
dos db 'Dos'
endline db 0dh,0ah,'$'
mcb db 16 dup()

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


print_str PROC NEAR ;si-str cx-len
push es
mov ax,ds
mov es,ax
mov ah,02h
f:
lodsb
mov dl,al
cmp dl,0
je e
int 21h
loop f
e:
pop es

ret
print_str ENDP

mcb_info PROC
mov si, 0
copy:
mov al, es:[si]
mov [si+offset mcb], al
inc si
cmp si,16
jl copy
ret
mcb_info ENDP

big_number proc near
  xor cx,cx
  mov bx,10
  step:
  mov si,ax
  mov ax,dx
  xor dx,dx
  div bx
  mov di,ax
  mov ax,si
  div bx
  push dx
  inc cx
  mov dx,di
  push ax
  or ax,dx
  pop ax
  jnz step
  mov ah,02h
  completion:
  pop dx
  add dl, '0'
  int 21h
  loop completion
  ret
big_number endp

print_available proc near
  mov dx,offset available_mem
  mov ah,09h
  int 21h

  mov bx,0ffffh
  mov ah,48h
  int 21h
  mov ax,bx

  mov bx,16
  mul bx

  call big_number

  mov dx,offset bytes
  mov ah,09h
  int 21h
  mov dx,offset endline
  mov ah,09h
  int 21h

  ret
print_available endp

print_extended proc NEAR
mov dx, offset extended_mem
mov ah,09h
int 21h
  mov al,31h
  out 70h,al
  in al,71h
  mov ah,al
  mov al,30h
  out 70h,al
  in al,71h
  mov bx,1024
  mul bx
  call big_number
  mov dx, offset bytes
  mov ah,09h
  int 21H
  mov dx, offset endline
  mov ah,09h
  int 21h
  ret
print_extended endp

print_mcb_type proc NEAR
  push ax
  mov ah,0
  mov al, mcb[si]
  call BYTE_TO_HEX
  mov bx,ax
  mov ah,09h
  int 21h

  mov dl, bl
  mov ah,02h
  int 21h

  mov dl, bh
  mov ah,02h
  int 21h

  mov dl,'h'
  mov ah,02h
  int 21h

  pop ax
  ret
print_mcb_type endp

print_mcb proc near
  push ax
  mov dx, offset mcb_type
  mov si,0
  call print_mcb_type

  mov ax,es
  lea di, mcb_addres
  add di,17
  call WRD_TO_HEX
  lea dx, mcb_addres
  mov ah,09h
  int 21h

  mov ax, mcb[01h]
  lea di, owner
  add di,10
  call WRD_TO_HEX
  lea dx, owner
  mov ah,09h
  int 21h

  mov dx, offset block_size
  mov ah,09h
  int 21h
  mov ax,mcb[03h]
  mov bx,16
  mul bx

  call big_number

  mov dx, offset bytes
  mov ah,09h
  int 21h

  mov dx, offset endline
  mov ah,09h
  int 21h

  mov dx, offset mcb_reserved
  mov si,5
  call print_mcb_type

  mov dx, offset mcb_text
  mov ah, 09h
  int 21h

  mov si, offset mcb+8
  mov cx, 8
  call print_str

  pop ax
  ret
print_mcb endp

begin:
mov bx,4096
mov AH,4ah
int 21H
mov bx,4096
mov AH,48h
int 21H
  call print_available
  call print_extended

  mov ah,52h
  int 21h

  mov ax, es:[bx-2]
  mov es, ax
  mov ax, es:[0000h]
  jmp one
  read:

  mov dx, offset endline
  mov ah,09h
  int 21h
  one:
  call mcb_info

  mov ax,es
  call print_mcb
  push ax
  pop ax
  inc ax
  add ax, mcb[03h]
  mov es,ax

  mov al, mcb[00h]
  cmp al,5ah
  jne read
  mov ax,ds
  mov es,ax

; Выход в DOS
xor AL,AL
mov AH,4Ch
int 21H
prog ends
end start
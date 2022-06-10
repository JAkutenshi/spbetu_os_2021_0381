CODE SEGMENT
ASSUME CS:CODE, DS:NOTHING, SS:NOTHING
MAIN proc far
    push ax
    push dx
    push ds
    push di

    mov ax, cs
    mov ds, ax
    mov di, offset OVERLAY_ADDRESS
    add di, 20
    call WRD_TO_HEX
    mov dx, offset OVERLAY_ADDRESS
    call WRITE_STRING

    pop di
    pop ds
    pop dx
    pop ax
    retf
MAIN endp

OVERLAY_ADDRESS db "overlay1 address:    ", 0DH, 0AH, '$'

WRITE_STRING proc near
    push ax
    mov ah, 9h
    int 21h
    pop ax
    ret
WRITE_STRING endp


TETR_TO_HEX proc near
    and al,0fh
    cmp al,09
    jbe next
    add al,07
next:
    add al,30h
    ret
TETR_TO_HEX endp


BYTE_TO_HEX proc near
    push cx
    mov ah, al
    call tetr_to_hex
    xchg al,ah
    mov cl,4
    shr al,cl
    call tetr_to_hex
    pop cx
    ret
BYTE_TO_HEX endp


WRD_TO_HEX proc near
    push bx
    mov	bh,ah
    call byte_to_hex
    mov	[di],ah
    dec	di
    mov	[di],al
    dec	di
    mov	al,bh
    xor	ah,ah
    call byte_to_hex
    mov	[di],ah
    dec	di
    mov	[di],al
    pop	bx
    ret
WRD_TO_HEX endp

code ends
end main
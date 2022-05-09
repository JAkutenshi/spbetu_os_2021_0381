assume cs:code
code segment
    main proc far
        push ax
        push dx
        push ds
        push di

        mov ax,cs
        mov ds,ax
        mov di, offset overlay_addr
        add di,22
        call wrd_to_hex
        mov dx, offset overlay_addr
        call print_string

        pop di
        pop ds
        pop dx
        pop ax
        retf
    main endp

    overlay_addr db "Overlay 2 address: 0000h$", 0dh,0ah,'$'

    print_string proc
        push ax
        mov ah,9h
        int 21h
        pop ax
        ret
    print_string endp

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
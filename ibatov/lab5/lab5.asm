code segment
ASSUME CS:code, DS:data, SS:stack


user_int proc far
    jmp start
    psp dw ?
    num dw 1234h
    keep_ip dw ?
    keep_cs dw ?
    keep_ss dw ?
    keep_sp dw ?
    keep_ax dw ?
    button_key db 01h
    dw 32 dup()
    stack_end dw ?

    start:
    mov keep_ss, ss
    mov keep_sp, sp
    mov keep_ax, ax
    mov ax,cs
    mov ss,ax
    mov sp, offset stack_end

    push bx
    push cx
    push dx
    push di
    push bp
    push ds

    in al,60h
    cmp al,button_key
    je button_action
    call dword ptr cs:keep_ip
    jmp end_int
    button_action:

    in al,61h
    mov ah,al
    or al,80h
    out 61h,al
    xchg ah,al
    out 61h,al
    mov al,20h
    out 20h,al

    wrt_again:
    mov ah,05h
    mov cl,'G'
    mov ch,00h
    int 16h
    or al,al
    jz end_int
    mov ah,0ch
    mov al,00h
    int 21h
    jmp wrt_again
    end_int:

    pop ds
    pop bp
    pop di
    pop dx
    pop cx
    pop bx

    mov ax,keep_ax
    mov ss, keep_ss
    mov sp, keep_sp

    mov al,20h
    out 20h,al
    iret
    end_user_int:
user_int endp

    check_int proc far
        push bx
        push es
        mov ah,35h
        mov al,09h
        int 21h

        mov ax,es:[num]
        cmp ax, 1234h
        je load_true
        mov al,0
        jmp load_exit
        load_true:
        mov al,1
        load_exit:
        pop es
        pop bx
        ret
    check_int endp

    cmd_free proc
        mov si,0
        cycle_flag:
        mov bl,es:[81h+si]
        cmp bl,unload_cmd[si]
        jne false
        inc si
        cmp unload_cmd[si],0dh
        je true
        jmp cycle_flag

        true:
        mov ax,si
        cmp al,es:[80h]
        jne false
        mov al,1
        jmp go_end
        false:
        mov al,0
        go_end:
        ret
    cmd_free endp


    load_usr_int proc
        mov psp, es
        mov ah,35h
        mov al,09h
        int 21h
        mov keep_ip, bx
        mov keep_cs, es

        push ds
        mov dx,offset user_int
        mov ax,seg user_int
        mov ds,ax
        mov ah,25h
        mov al,09h
        int 21H
        pop ds

        mov dx,offset end_user_int
        mov cl,4
        shr dx,cl
        inc dx
        mov ax,cs
        sub ax,psp
        add dx,ax
        mov al,0
        mov ah,31h
        int 21h
        ret
    load_usr_int endp

    unload_usr_int proc near
        cli
        push ds
        mov dx,es:[keep_ip]
        mov ax,es:[keep_cs]
        mov ds,ax
        mov ah,25h
        mov al,09h
        int 21h
        pop ds
        sti
        mov ax,es:[psp]
        mov es,ax
        push es
        mov ax,es:[2ch]
        mov es,ax
        mov ah,49h
        int 21h
        pop es
        int 21h
        ret
    unload_usr_int endp

    main proc far
        mov ax,data
        mov ds,ax

        call cmd_free
        mov bx,ax
        call check_int

        cmp al,0
        je no_loaded

        cmp bl,0
        jne unload
        mov ah,09h
        mov dx,offset already_loaded
        int 21h
        jmp pend

        no_loaded:
        cmp bl, 0
        je load
        mov ah,09h
        mov dx, offset not_loaded
        int 21h
        jmp pend

        unload:
        mov ah,09h
        mov dx,offset unloading
        int 21h

        mov ah,35h
        mov al,09h
        int 21h
        call unload_usr_int
        jmp pend

        load:
        mov ah,09h
        mov dx,offset loading
        int 21h
        call load_usr_int

        pend:
        mov ah,4ch
        int 21h
    main endp

code ends

stack segment stack
    dw 256 dup(?)
stack ends

data segment
    unload_cmd db " /un",0dh
    loading db "Loading ...", 0dh,0ah, '$'
    not_loaded db "User interrupt isn`t loaded.", 0dh,0ah,'$'
    already_loaded db "User interrupt is already loaded.",0dh,0ah,'$'
    unloading db "Unloading ...",0dh,0ah,'$'
data ends

end main
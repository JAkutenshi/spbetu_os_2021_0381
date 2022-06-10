astack segment stack
    dw 128 dup()
astack ends

data segment
    epb db 14 dup()
    file db "File $"
    ctrl_c db 0dh,0ah,"Terminated with CTRL+C, code 000$"
    norma db 0dh,0ah,"Terminated with code: 000$"
    not_found db " not found $"
    filename db "LB2.com",0
    path db 50 dup(0)
    endline db 0dh,0ah,'$'
    save_ss dw ?
    save_sp dw ?
data ends

code segment
    assume cs:code, ds:data, ss:astack

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

    print_str proc near
        push ds
        mov ax,es
        mov ds,ax
        mov ah,02h
        cycle:
        lodsb
        mov dl,al
        cmp dl,0
        je end_p
        int 21h
        loop cycle
        end_p:
        pop ds
        ret
    print_str endp

    main proc far
        mov ax,data
        mov ds,ax
        push es

        mov si,0
        mov es,es:[2ch]
        cycle_env:
        mov al,es:[si]
        inc si
        cmp al,0
        jne cycle_env
        mov al,es:[si]
        cmp al,0
        jne cycle_env

        add si,3
        push si
        find_sl:
        cmp byte ptr es:[si],'\'
        jne next_step
        mov ax,si
        next_step:
        inc si
        cmp byte ptr es:[si],0
        jne find_sl
        inc ax
        pop si
        mov di,0
        copy_dir:
        mov bl,es:[si]
        mov path[di],bl
        inc si
        inc di
        cmp si,ax
        jne copy_dir
        mov si,0
        copy_filename:
        mov bl,filename[si]
        mov path[di],bl
        inc si
        inc di
        cmp bl,0
        jne copy_filename

        mov si, offset path

        pop es
        mov bx, offset end_code
        mov ax,es
        sub bx,ax
        mov cl,4
        shr bx,cl
        mov ah,4ah
        int 21h

        jc exit_p

        push ds
        push es

        mov word ptr epb[2], es
        mov word ptr epb[4],80h

        mov ax,ds
        mov es,ax
        mov dx,offset path
        mov bx,offset epb
        mov save_ss,ss
        mov save_sp, sp
        mov ax, 4b00h
        int 21h
        mov ss, save_ss
        mov sp,  save_sp

        pop es
        pop ds

        jnc without_err

        mov ax,ds
        mov es,ax
        mov ah,09h
        mov dx,offset file
        int 21h
        mov si, offset path
        mov cx,-1
        call print_str

        mov ah,09h
        mov dx, offset not_found
        int 21h
        jmp exit_p
        without_err:

        mov ah,4dh
        int 21h
        cmp ah,0
        je normal_msg
        mov si, offset ctrl_c
        add si, 32
        call BYTE_TO_DEC

        mov ah,09h
        mov dx,offset ctrl_c
        int 21h
        jmp exit_p
        normal_msg:

        mov si, offset norma
        add si,26
        call BYTE_TO_DEC

        mov ah,09h
        mov dx,offset norma
        int 21h
        exit_p:
        mov ah,4ch
        int 21h
    end_code:
    main endp
code ends
end main

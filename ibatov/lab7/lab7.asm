assume cs:code, ds:data, ss:stack

stack segment stack
    dw 64 dup(?)
stack ends

data segment
    overlay1_name db 'overlay1.ovl',0
    overlay2_name db 'overlay2.ovl',0
    current_path db 50 dup (0)

    illegal_function_error db "!: Illegal function$"
    illegal_file_error db "!: File doesn't exist$"
    illegal_path_error db "!: Path doesn't exist$"
    oplimit_error db "!: Too many open files$"
    no_access_error db "!: Access denied$"
    memory_error db "!: Insufficient memory$"
    enviroment_error db "!: Incorrect enviroment$"
    address_error db "!: Wrong block address$"

    overlay_address dd 0
    dta db 43 dup(0)
    mcb_crash db "!: MCB destroyed$"
    end_line db 0dh,0ah,'$'
    epb dw 2 dup(0)
    error db 0
data ends

code segment
    mem_free proc near
        push ax
        push bx
        push cx
        push dx
        mov bx,offset p_end_code
        mov ax,es
        sub bx,ax
        mov cl,4
        shr bx,cl
        mov ah,4ah
        int 21h
        jnc mem_free_end
        cmp ax,7
        je mem_free_7
        cmp ax,8
        je mem_free_8
        cmp ax,9
        je mem_free_9
        jmp mem_free_end

        mem_free_7:
          mov dx,offset mcb_crash
          jmp mem_free_print

        mem_free_8:
          mov dx,offset memory_error
          jmp mem_free_print

        mem_free_9:
          mov dx,offset address_error

        mem_free_print:
          mov ah,09h
          int 21h
          mov error,1

        mem_free_end:
          pop dx
          pop cx
          pop bx
          pop ax
          ret
    mem_free endp

    getPath proc near
        push si
        mov si,0
        mov es, es:[2ch]
        env_cycle:
          mov al,es:[si]
          inc si
          cmp al,0
          jne env_cycle
          mov al,es:[si]
          cmp al,0
          jne env_cycle

        add si,3
        push si

        search_sl:
          cmp byte ptr es:[si],'\'
          jne next_search
        mov ax,si

        next_search:
          inc si
          cmp byte ptr es:[si],0
          jne search_sl
        inc ax
        pop si
        mov di,0

        dir_path:
          mov bl,es:[si]
          mov current_path[di],bl
          inc si
          inc di
          cmp si,ax
          jne dir_path
        pop si

        fileName:
          mov bl,[si]
          mov current_path[di],bl
          inc si
          inc di
          cmp bl,0
          jne fileName
        ret
    getPath endp

    fileSize proc near
        push cx
        push dx
        mov dx, offset dta
        mov ah,1ah
        int 21h

        mov cx,0
        mov dx,offset current_path
        mov ah,4eh
        int 21h

        jnc fileSize_correct
        cmp ax,2
        je fileSize_err2
        cmp ax,3
        je fileSize_err3

        fileSize_err2:
          mov dx,offset illegal_file_error
          jmp fileSize_print

        fileSize_err3:
          mov dx, offset illegal_path_error

        fileSize_print:
          mov error,1
          mov ah,09h
          int 21h

        fileSize_correct:
          mov ax, word ptr dta[1ah]
          mov dx, word ptr dta[1ah+2]
          mov cl,4
          shr ax,cl
          mov cl,12
          shl dx,cl
          add ax,dx
          add ax,1
        pop dx
        pop cx
        ret
    fileSize endp

    malloc proc near
        push bx
        push dx
        mov bx,ax
        mov ah,48h
        int 21h
        jnc malloc_correct
        mov dx,offset memory_error
        mov ah,09h
        int 21h
        mov error,1
        jmp p_end_malloc

        malloc_correct:
          mov epb[0],ax
          mov epb[2],ax

        p_end_malloc:
          pop dx
          pop bx
          ret
    malloc endp

    load proc near
        push ax
        push es
        push bx
        push dx
        mov dx,offset current_path
        mov ax,ds
        mov es,ax
        mov bx,offset epb
        mov ax, 4b03h
        int 21h

        jnc load_correct
        cmp ax,1
        je load_err1
        cmp ax,2
        je load_err2
        cmp ax,3
        je load_err3
        cmp ax,4
        je load_err4
        cmp ax,5
        je load_err5
        cmp ax,8
        je load_err8
        cmp ax, 10
        je load_err10

        load_err1:
          mov dx,offset illegal_function_error
          jmp load_print
        load_err2:
          mov dx,offset illegal_file_error
          jmp load_print
        load_err3:
          mov dx,offset illegal_path_error
          jmp load_print
        load_err4:
          mov dx,offset oplimit_error
          jmp load_print
        load_err5:
          mov dx,offset no_access_error
          jmp load_print
        load_err8:
          mov dx,offset memory_error
          jmp load_print
        load_err10:
          mov dx,offset enviroment_error
        load_print:
          mov ah,09h
          mov error,1
          int 21
        load_correct:
          mov ax,epb[2]
          mov word ptr overlay_address+2, ax
          call overlay_address

          mov es,ax
          mov ah,49h
          int 21h
        load_end:
          pop dx
          pop bx
          pop es
          pop ax
          ret
    load endp

    print_str proc near
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

    main proc near
        mov ax,data
        mov ds,ax
        push es
        call mem_free
        cmp error,0
        jne p_exit

        mov si,offset overlay1_name
        call getPath
        call fileSize
        cmp error,0
        jne p_ovl1
        call malloc
        cmp error,0
        jne p_ovl1
        call load

        p_ovl1:
          mov dx,offset end_line
          mov ah,09h
          int 21h
          pop es
          mov error,0
          mov si,offset overlay2_name
          call getPath
          call fileSize
          cmp error,0
          jne p_exit
          call malloc
          cmp error,0
          jne p_exit
          call load

        p_exit:
          xor al,al
          mov ah,4ch
          int 21h
        p_end_code:
    main endp
code ends
end main
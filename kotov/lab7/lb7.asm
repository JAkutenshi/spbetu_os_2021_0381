AStack    SEGMENT  STACK
          DW 64 DUP(?)    
AStack    ENDS

DATA      SEGMENT

OVERLAY_1 db "o1.exe",0
OVERLAY_2 db "o2.exe",0
PARAMETER_BLOCK dw 2 dup(0)
NEWLINE db 0Dh,0Ah,'$'
ERR7 db "MCB is destroyed",0Dh,0Ah,'$'
ERR9 db "Invalid memory block address",0Dh,0Ah,'$'
PATHERR db "Path not found",0Dh,0Ah,'$'
FUNCERR db "Wrong function",0Dh,0Ah,'$'
FINDERR db "File not found",0Dh,0Ah,'$'
MUCHERR db "Too many open files",0Dh,0Ah,'$'
MEMERR db "Not enought memory",0Dh,0Ah,'$'
ACSERR db "Access error",0Dh,0Ah,'$'
ENVERR db "Wrong enviroment",0Dh,0Ah,'$'
PATH db 50 dup(0)
DTA_BUFFER db 43 dup(0)
OVERLAYADDRESS dd 0

DATA ENDS

CODE      SEGMENT
          ASSUME CS:CODE, DS:DATA, SS:AStack
		  
PUTS PROC NEAR
push ax
mov ah,09h
int 21h
pop ax
ret
PUTS ENDP

FREE PROC NEAR
push ax
push dx

mov bx, offset exit
mov ax, es
sub bx, ax
mov cl, 4
shr bx, cl
inc bx
mov ah, 4Ah
int 21h
jnc no_errs

mov bx, 1

cmp ax, 7
jne _err8
lea dx, ERR7
jmp write

_err8:
cmp ax, 8
jne _err9
lea dx, MEMERR
jmp write

_err9:
cmp ax, 9
jne free_end
lea dx, ERR9

write:
call PUTS
jmp free_end

no_errs:
mov bx, 0

free_end:
pop dx
pop ax
ret
FREE ENDP

GET_PATH PROC NEAR
push es
push ax
push si

sub si, si
mov es, es:[2Ch]

find_loop:
mov al, es:[si]
inc si
cmp al, 0
jne find_loop
mov al, es:[si]
cmp al, 0
jne find_loop
	
add si, 3
push si

find_slash:
cmp byte ptr es:[si], '\'
jne next
mov ax, si
	
next:
inc si
cmp byte ptr es:[si], 0
jne find_slash
inc ax
pop si
mov di, 0

save_path:
mov bl, es:[si]
mov PATH[di], bl
inc si
inc di
cmp si, ax
jne save_path

pop si

add_filename:
mov bl, [si]
mov PATH[di], bl
inc si
inc di
cmp bl, 0
jne add_filename

pop ax
pop es
ret
GET_PATH ENDP

GET_FILESIZE PROC NEAR
push cx
push dx
mov dx, offset DTA_BUFFER
mov ah, 1Ah
int 21h

mov cx, 0
mov dx, offset PATH
mov ah, 4Eh
int 21h

jnc no_err_size

cmp ax, 2
je _err2

lea dx, PATHERR
jmp write_err

_err2:
lea dx, FINDERR

write_err:
call PUTS
mov bx, 1
jmp end_size
ret

no_err_size:
mov ax, word ptr DTA_BUFFER[1ah]
mov dx, word ptr DTA_BUFFER[1ah+2]
mov cl, 4
shr ax, cl
mov cl, 12
shl dx, cl
add ax, dx
add ax, 1
mov bx, 0

end_size:
pop dx
pop cx
ret
GET_FILESIZE ENDP

MALLOC PROC NEAR
push bx
push dx
mov bx, ax
mov ah, 48h
int 21h
jnc no_err_mem
lea dx, MEMERR
call PUTS
mov bx, 1
jmp mem_end

no_err_mem:
mov PARAMETER_BLOCK[0], ax
mov PARAMETER_BLOCK[2], ax
mov bx, 0

mem_end:
pop dx
pop bx
ret
MALLOC ENDP

LOAD PROC NEAR
push ax
push es
push bx
push dx
lea dx, PATH
mov ax, ds
mov es, ax
lea bx, PARAMETER_BLOCK
mov ax, 4B03h
int 21h
jnc no_err_load

cmp ax, 1
je _funcerr

cmp ax, 2
je _finderr

cmp ax, 3
je _patherr

cmp ax, 4
je _mucherr

cmp ax, 5
je _acserr

cmp ax, 8
je _memerr

lea dx, ENVERR
jmp _write

_funcerr:
lea dx, FUNCERR
jmp _write

_finderr:
lea dx, FINDERR
jmp _write

_patherr:
lea dx, PATHERR
jmp _write

_mucherr:
lea dx, MUCHERR
jmp _write

_acserr:
lea dx, ACSERR
jmp _write

_memerr:
lea dx, MEMERR

_write:
call PUTS
jmp load_end

no_err_load:
mov ax, PARAMETER_BLOCK[2]
mov word ptr OVERLAYADDRESS+2, ax
call OVERLAYADDRESS
	
mov es, ax
mov ah, 49h
int 21h

load_end:
pop dx
pop bx
pop es
pop ax
ret
LOAD ENDP

MAIN PROC FAR                            
push ds
sub ax, ax
push ax
mov ax, DATA
mov ds, ax
push es

call FREE
cmp bx, 0
jne end_main
	
mov si, offset OVERLAY_1
call GET_PATH
call GET_FILESIZE
cmp bx, 0
jne o2

call MALLOC
cmp bx, 0
jne o2

call LOAD

o2:
pop es

lea si, OVERLAY_2
call GET_PATH
call GET_FILESIZE
cmp bx, 0
jne end_main

call MALLOC
cmp bx, 0
jne end_main

call LOAD

end_main:
mov ah, 4Ch
int 21h
ret

exit:
MAIN ENDP
CODE ENDS
END MAIN

AStack    SEGMENT  STACK
          DW 512 DUP(?)    
AStack    ENDS

DATA      SEGMENT

OVERLAY1_NAME db "o1.ovl",0
OVERLAY2_NAME db "o2.ovl",0

PARAMETR_BLOCK dw 2 dup(0)
NEWLINE db 0DH,0AH,'$'
ERROR7 DB "Can't spread memory: block destroyed",0DH,0AH,'$'
ERROR8 DB "Can't spread memory: not enough memory",0DH,0AH,'$'
ERROR9 DB "Can't spread memory: wrong address",0DH,0AH,'$'
PATH_TO_FILE db 50 dup(0)
DTA_BUFFER db 43 dup(0)
OVERLAYADDRESS dd 0

PATHNOTFOUND db "Path not found",0DH,0AH,'$'
NOSUCHFUNC db "Function doesn't exist",0DH,0AH,'$'
FILENOTFOUND db "File not found",0DH,0AH,'$'
TOOMANYOPEN db "Too many open files",0DH,0AH,'$'
NOTENOUGHMEMORY db "Not enought memory",0DH,0AH,'$'
NOACCESS db "No access",0DH,0AH,'$'
WRONGENV db "Wrong enviroment",0DH,0AH,'$'

DATA ENDS

CODE      SEGMENT
          ASSUME CS:CODE, DS:DATA, SS:AStack
		  
;печать сообщения
WRITEMESSAGE PROC Near
push AX
mov AH,09h
int 21h
pop AX
ret
WRITEMESSAGE ENDP

SPREAD_MEMORY PROC near
push AX
push DX

mov BX, offset program_end
mov AX, ES
sub BX, AX
mov CL, 4
shr BX, CL
inc BX
mov AH, 4Ah
int 21h
jnc succes
mov BX, 1

cmp AX, 7
jne error_8
lea DX, ERROR7
jmp show_warning

error_8:
cmp AX, 8
jne error_9
lea DX, ERROR8
jmp show_warning

error_9:
cmp AX, 9
jne spread_end
lea DX, ERROR9

show_warning:
call WRITEMESSAGE
jmp spread_end

succes:
	mov BX, 0

spread_end:
pop DX
pop AX
ret
SPREAD_MEMORY ENDP

GET_PARAMS PROC Near
push ES
push AX
push SI

sub SI, SI
mov ES, ES:[2Ch]

find_loop:
	mov AL, ES:[SI]
	inc SI
	cmp AL, 0
	jne find_loop
	mov AL, ES:[SI]
	cmp AL, 0
	jne find_loop
	
add SI, 3
push SI

find_slash:
	cmp byte ptr ES:[SI], '\'
	jne next_char
	mov AX, SI
	
	next_char:
		inc SI
		cmp byte ptr ES:[SI], 0
		jne find_slash
		inc AX
		pop SI
		mov DI, 0

save_path:
	mov BL, ES:[SI]
	mov PATH_TO_FILE[DI], BL
	inc SI
	inc DI
	cmp SI, AX
	jne save_path

	pop SI

add_filename:
	mov BL, [SI]
	mov PATH_TO_FILE[DI], BL
	inc SI
	inc DI
	cmp BL, 0
	jne add_filename

pop AX
pop ES
ret
GET_PARAMS ENDP

GET_FILESIZE PROC Near
push CX
push DX
mov DX, offset DTA_BUFFER
mov AH, 1Ah
int 21h

mov CX, 0
mov DX, offset PATH_TO_FILE
mov AH, 4Eh
int 21h

jnc no_err_get
cmp AX, 2
je get_error_2
lea DX, PATHNOTFOUND
jmp write_err_mess
get_error_2:
	lea DX, FILENOTFOUND
write_err_mess:
	call WRITEMESSAGE
	mov BX, 1
	jmp end_get
	ret
no_err_get:
	mov AX, word ptr DTA_BUFFER[1Ah]
	mov DX, word ptr DTA_BUFFER[1Ah+2]
	mov CL, 4
	shr AX, CL
	mov CL, 12
	shl DX, CL
	add AX, DX
	add AX, 1
	mov BX, 0
end_get:
	pop DX
	pop CX
	ret
GET_FILESIZE ENDP

MEMORY_FOR_OVERLAY Proc NEAR
push BX
push DX
mov BX, AX
mov AH, 48h
int 21h
jnc no_err_mem
lea DX, NOTENOUGHMEMORY
call WRITEMESSAGE
mov BX, 1
jmp mem_end
no_err_mem:
	mov PARAMETR_BLOCK[0], AX
	mov PARAMETR_BLOCK[2], AX
	mov BX, 0
mem_end:
pop DX
pop BX
ret
MEMORY_FOR_OVERLAY ENDP


LOAD_OVERLAY Proc NEAR
push AX
push ES
push BX
push DX
lea DX, PATH_TO_FILE
mov AX, DS
mov ES, AX
lea BX, PARAMETR_BLOCK
mov AX, 4B03h
int 21h
jnc no_err_load
cmp AX, 1
je load_nofunc
cmp AX, 2
je load_nofile
cmp AX, 3
je load_nopath
cmp AX, 4
je load_open
cmp AX, 5
je load_noacc
cmp AX, 8
je load_nomem
lea DX, WRONGENV
jmp load_write_err_msg
load_nofunc:
	lea DX, NOSUCHFUNC
	jmp load_write_err_msg
load_nofile:
	lea DX, FILENOTFOUND
	jmp load_write_err_msg
load_nopath:
	lea DX, PATHNOTFOUND
	jmp load_write_err_msg
load_open:
	lea DX, TOOMANYOPEN
	jmp load_write_err_msg
load_noacc:
	lea DX, NOACCESS
	jmp load_write_err_msg
load_nomem:
	lea DX, NOTENOUGHMEMORY
load_write_err_msg:
	call WRITEMESSAGE
	jmp load_end
no_err_load:
	mov AX, PARAMETR_BLOCK[2]
	mov word ptr OVERLAYADDRESS+2, AX
	call OVERLAYADDRESS
	
	mov ES, AX
	mov AH, 49h
	int 21h
load_end:
	pop DX
	pop BX
	pop ES
	pop AX
	ret
LOAD_OVERLAY ENDP

Main 	Proc FAR                            
	push DS
	sub AX, AX
	push AX
	mov AX, DATA
	mov DS, AX
	push ES

	call SPREAD_MEMORY
	cmp BX, 0
	jne end_main
	
	mov SI, offset OVERLAY1_NAME
	call GET_PARAMS
	call GET_FILESIZE
	cmp BX, 0
	jne load_second
	call MEMORY_FOR_OVERLAY
	cmp BX, 0
	jne load_second
	call LOAD_OVERLAY

load_second:
	pop ES
	lea SI, OVERLAY2_NAME
	call GET_PARAMS
	call GET_FILESIZE
	cmp BX, 0
	jne end_main
	call MEMORY_FOR_OVERLAY
	cmp BX, 0
	jne end_main
	call LOAD_OVERLAY

	end_main:
	mov AH, 4Ch
	int 21h
	RET
program_end:
Main      ENDP
CODE      ENDS
          END Main

LAB3 SEGMENT
 ASSUME CS:LAB3, DS:LAB3, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
; ДАННЫЕ

;СТРОКИ ДЛЯ ВЫВОДА ИНОФРМАЦИИ
MEMORYSIZE db 'Available memory size:        byte',0DH,0AH,'$'
EXTMEMORY db 'Extended memory size:        byte',0DH,0AH,'$'
BLOCKLINE db 'MCB || Type:   h | Adress:     h | Size:        bytes | Owner: ','$'
BLOCKLINE_OTHER db ' Other: ','$'
BLOCKLINE_END db '||',0DH,0AH,'$'
BADALLOC db 'Bad memory allocation',0DH,0AH,'$'

OWNER_FREE db        'Free                   |','$'
OWNER_OSXMS db       'OS XMS UMD             |','$'
OWNER_DRIVER db      'High driver memory     |','$'
OWNER_MSDOS db       'MS DOS                 |','$'
OWNER_BLOCKUMB db    'Occupied by 386MAX UMB |','$'
OWNER_BLOCKED386 db  'Blocked by 386MAX      |','$'
OWNER_OWNED386MAX db '386MAX UMB             |','$'
OWNER_UNKNOWN db     '    h                  |','$'

BLOCKDATA db 16 DUP(?)
NEWLINE db 0DH,0AH,'$'

;ПРОЦЕДУРЫ

;вывод сообщения
WRITEMESSAGE PROC Near
mov AH,09h
int 21h
ret
WRITEMESSAGE ENDP

TETR_TO_HEX PROC near
 and AL,0Fh
 cmp AL,09
 jbe NEXT
 add AL,07
NEXT: add AL,30h
 ret
TETR_TO_HEX ENDP

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

;-------------------------------------------------------------------------------


;ОПРЕДЕЛЕНИЕ РАЗМЕРА ДОСТУПНОЙ ПАМЯТИ
WRITEMEMORYSIZE PROC Near
push AX
push ES
push BX
push DX

mov AH, 4ah;
mov BX, 0ffffh;
int 21h

mov AX, BX

lea SI, MEMORYSIZE
add SI, 23
call WRD_TO_DEC

mov DX, OFFSET MEMORYSIZE
call WRITEMESSAGE

pop DX
pop BX
pop ES
pop AX
ret
WRITEMEMORYSIZE ENDP

;ОПРЕДЕЛЕНИЕ РАЗМЕРА РАСШИРЕННОЙ ПАМЯТИ
WRITEEXTMEMORYSIZE PROC Near
push AX
push DX
push DI

mov AL, 30h
out 70h, AL
in AL, 71h
mov BL, AL
mov AL, 31h
out 70h, AL
in AL, 71h
mov AH, AL
mov AL, BL

lea SI, EXTMEMORY
add SI, 22
call WRD_TO_DEC

lea DX, EXTMEMORY
call WRITEMESSAGE

pop DI
pop DX
pop AX
ret
WRITEEXTMEMORYSIZE ENDP

SAVEBLOCK PROC Near
PUSH AX
PUSH SI
PUSH BX

mov SI, 0h
lea BX, BLOCKDATA
save:
	mov AL, ES:[SI]
	mov [BX][SI], AL
	inc SI
	cmp SI, 16
	jl save

pop BX
pop SI
pop AX
ret
SAVEBLOCK ENDP

WRDMUL_TO_DEC PROC Near
push BX
push CX
push DX

mov CX, 0
mov BX, 10

get_number:
	div BX
	push DX
	inc CX
	cmp AX, 0
	jne get_number

write_number:
	mov AX, 0
	pop AX
	call BYTE_TO_DEC
	inc SI
	loop write_number

pop DX
pop CX
pop BX
ret
WRDMUL_TO_DEC ENDP

WRD_TO_DEC PROC Near
push BX
push CX
push AX
push DX

mov CX, 0
mov CL, 4
mov DX, 0
mov BX, 10
div BX

shl AX, CL
mov DI, AX
shl DX, CL
mov AX, DX
mov DX, 0
div BX
push DX
mov CX, 0
inc CX
or AX, DI

addcmp:
	cmp AX, 0Ah
	jb endl
	mov dx, 0
	div BX
	push DX
	inc CX
	
	jmp addcmp

endl:
	push AX
	inc CX

addnumber:
	pop AX
	call BYTE_TO_DEC
	add SI, 2
	loop addnumber

pop DX
pop AX
pop CX
pop BX
ret
WRD_TO_DEC ENDP

DETECTBLOCKTYPE PROC Near
push AX
push DX
	mov AL, BLOCKDATA[01]
	mov AH, BLOCKDATA[02]
	cmp AX, 0
	je free
	cmp AX, 6
	je xms
	cmp AX, 7
	je highdriver
	cmp AX, 8
	je dos
	cmp AX, 0FFFAh
	je max386
	cmp AX, 0FFFDh
	je blocked
	cmp AX, 0FFF3h
	je umb
	lea DI, OWNER_UNKNOWN
	add DI, 3
	call WRD_TO_HEX
	lea DX, OWNER_UNKNOWN
	jmp end_print
	
	free:
		lea DX, OWNER_FREE
		jmp end_print
	
	xms:
		lea DX, OWNER_OSXMS
		jmp end_print
	
	highdriver:
		lea DX, OWNER_DRIVER
		jmp end_print
	
	dos:
		lea DX, OWNER_MSDOS
		jmp end_print
		
	max386:
		lea DX, OWNER_BLOCKUMB
		jmp end_print
	
	blocked:
		lea DX, OWNER_BLOCKED386
		jmp end_print
	
	umb:
		lea DX, OWNER_OWNED386MAX
	
	end_print:
		call WRITEMESSAGE
pop DX
pop AX
ret
DETECTBLOCKTYPE ENDP


WRITEBLOCKLIST PROC Near
push ES
push BX
push AX
push DI
push CX
push DX

mov AH, 52h
int 21h

mov AX, ES:[BX-2]
mov ES, AX
mov AX, ES:[0h]


printblock:
	;адрес блока
	mov AX, ES
	lea DI, BLOCKLINE
	add DI, 30
	call WRD_TO_HEX

	;сохранение информации из блока
	call SAVEBLOCK

	;тип блока
	lea BX, BLOCKLINE
	add BX, 13
	mov AX, 0h
	mov AL, BLOCKDATA[0h]
	call BYTE_TO_HEX
	mov [BX], AX

	;размер в байтах
	
	mov AL, BLOCKDATA[03h]
	mov AH, BLOCKDATA[04]
	lea SI, BLOCKLINE
	add SI, 41
	call WRD_TO_DEC
	
	lea DX, BLOCKLINE
	call WRITEMESSAGE
	
	;владелец
	call DETECTBLOCKTYPE

	;последние 8 байт
	lea DX, BLOCKLINE_OTHER
	call WRITEMESSAGE
	lea DX, BLOCKDATA[8]
	call WRITEMESSAGE

	mov AX, ES
	inc AX
	add AX, BLOCKDATA[03]
	mov ES, AX
	
	mov AL, BLOCKDATA[0]
	cmp AL, 5Ah
	jne printblock
	
pop DX
pop CX
pop DI
pop AX
pop BX
pop ES
ret
WRITEBLOCKLIST ENDP



BEGIN:
 
 call WRITEMEMORYSIZE
 call WRITEEXTMEMORYSIZE
 
 lea AX, program_end
 mov DX, 0
 mov BX, 16
 div BX
 inc AX
 
 mov BX, AX
 mov AH, 4Ah
 int 21h
 jc badall
 
 mov BX, 4096
 mov AH, 48h
 int 21h
 jnc blocks
 
 badall:
 lea DX, BADALLOC
 call WRITEMESSAGE
 xor AL,AL
 mov AH,4Ch
 int 21H
 
 blocks:
 call WRITEBLOCKLIST
 xor AL,AL
 mov AH,4Ch
 int 21H
 
program_end:
LAB3 ENDS
END START ;конец модуля, START - точка входа
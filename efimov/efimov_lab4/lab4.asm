CODE      SEGMENT
          ASSUME CS:CODE, DS:DATA, SS:ASTACK

;-------------------------------
          
MY_INTERRUPT PROC far
   jmp start_my_interrupt
   
   PSP dw ?
   KEEP_IP dw 0
   KEEP_CS dw 0
   INTERRUPT_ID dw 8f17h
   
   STR_COUNTER db 'INTERRUPS: 0000$'
                  
	KEEP_SS dw ?
	KEEP_SP dw ?
	KEEP_AX dw ?
	INTERRUPT_STACK dw 32 dup (?)
	END_IT_STACK dw ?
   
start_my_interrupt:
   mov KEEP_SS,ss
   mov KEEP_SP,sp
   mov KEEP_AX,ax

   mov ax,cs
   mov ss,ax
   mov sp,offset END_IT_STACK

   push bx
   push cx
   push dx
   
   ;get cursor
	mov ah,3h
	mov bh,0h
	int 10h
	push dx
   
   ;set cursor
	mov ah,02h
	mov bh,0h
   mov dh,02h
   mov dl,05h
	int 10h
   
   ;number of times
   push si
	push cx
	push ds
   push bp
   
	mov ax,SEG STR_COUNTER
	mov ds,ax
	mov si,offset STR_COUNTER
	add si,11

   mov cx,4  
interrupt_loop:
   mov bp,cx
   mov ah,[si+bp]
	inc ah
	mov [si+bp],ah
	cmp ah,3Ah
	jne number
	mov ah,30h
	mov [si+bp],ah

   loop interrupt_loop 
    
number:
   pop bp
   
   pop ds
   pop cx
   pop si
   
   ;write string
	push es
	push bp
   
	mov ax,SEG STR_COUNTER
	mov es,ax
	mov ax,offset STR_COUNTER
	mov bp,ax
	mov ah,13h
	mov al,00h
	mov cx,16 ; number of chars
	mov bh,0
	int 10h
   
	pop bp
	pop es
   
	;return cursor
	pop dx
	mov ah,02h
	mov bh,0h
	int 10h

	pop dx
	pop cx
	pop bx
   
	mov ax, KEEP_SS
	mov ss, ax
	mov ax, KEEP_AX
	mov sp, KEEP_SP

   iret
interrapt_end:
MY_INTERRUPT ENDP          

;-------------------------------          

WRITE_STRING PROC near
   push AX
   mov AH,09h
   int 21h
   pop AX
   ret
WRITE_STRING ENDP
;-------------------------------

LOAD_FLAG PROC near
   push ax
   
   mov PSP,es
   mov al,es:[81h+1]
   cmp al,'/'
   jne load_flag_end
   mov al,es:[81h+2]
   cmp al, 'u'
   jne load_flag_end
   mov al,es:[81h+3]
   cmp al, 'n'
   jne load_flag_end
   mov flag,1h
  
load_flag_end:
   pop ax
   ret
LOAD_FLAG ENDP

;-------------------------------

IS_LOAD PROC near
   push ax
   push si
   
   mov ah,35h
   mov al,1Ch
   int 21h
   mov si,offset INTERRUPT_ID
   sub si,offset MY_INTERRUPT
   mov dx,es:[bx+si]
   cmp dx, 8f17h
   jne is_load_end
   mov flag_load,1h
is_load_end:   
   pop si
   pop ax
   ret
IS_LOAD ENDP

;-------------------------------

LOAD_INTERRUPT PROC near
   push ax
   push dx
   
   call IS_LOAD
   cmp flag_load,1h
   je already_load
   jmp start_load
   
already_load:
   lea dx,STR_ALR_LOAD
   call WRITE_STRING
   jmp end_load
  
start_load:
   mov AH,35h
	mov AL,1Ch
	int 21h 
	mov KEEP_CS, ES
	mov KEEP_IP, BX
   
   push ds
   lea dx, MY_INTERRUPT
   mov ax, seg MY_INTERRUPT
   mov ds,ax
   mov ah,25h
   mov al, 1Ch
   int 21h
   pop ds
   lea dx, STR_SUC_LOAD
   call WRITE_STRING
   
   lea dx, interrapt_end
   mov CL, 4h
   shr DX,CL
   inc DX
   mov ax,cs
   sub ax,PSP
   add dx,ax
   xor ax,ax
   mov AH,31h
   int 21h
     
end_load:  
   pop dx
   pop ax
   ret
LOAD_INTERRUPT ENDP

;-------------------------------

UNLOAD_INTERRUPT PROC near
   push ax
   push si
   
   call IS_LOAD
   cmp flag_load,1h
   jne cant_unload
   jmp start_unload
   
cant_unload:
   lea dx,STR_IST_LOAD
   call WRITE_STRING
   jmp unload_end
   
   
start_unload:
   CLI ;восстановим оригинальный вектор
   PUSH DS
   mov ah,35h
	mov al,1Ch
	int 21h

   mov si,offset KEEP_IP
	sub si,offset MY_INTERRUPT
	mov dx,es:[bx+si]
	mov ax,es:[bx+si+2]
   MOV DS,AX
   MOV AH,25H
   MOV AL, 1CH
   INT 21H
   POP DS
   
   ;освободим память
   mov ax,es:[bx+si-2]
   mov es,ax
   push es
   
   mov ax,es:[2ch] ; очистка данных из префикса
   mov es,ax
   mov ah,49h
   int 21h
   
   pop es
   mov ah,49h
   int 21h
   STI
   
   lea dx,STR_IS_UNLOAD
   call WRITE_STRING
unload_end:   
   pop si
   pop ax
   ret
UNLOAD_INTERRUPT ENDP

;-------------------------------
; Головная процедура
Main      PROC  FAR
   push  DS       
   xor   AX,AX    
   push  AX       
   mov   AX,DATA             
   mov   DS,AX

   call LOAD_FLAG
   cmp flag, 1h
   je unload_interrupt
   call LOAD_INTERRUPT
   jmp CustomEnd
   
unload_iterrupt:
   call UNLOAD_INTERRUPT
   
CustomEnd:  
   mov ah,4ch
   int 21h   
Main      ENDP
CODE      ENDS

ASTACK    SEGMENT  STACK
   DW 64 DUP(?)   
ASTACK    ENDS

DATA      SEGMENT
   flag db 0
   flag_load db 0

   STR_IST_LOAD  DB 'Interrupt is not load', 0AH, 0DH,'$'
   STR_ALR_LOAD  DB 'Interrupt is already loaded', 0AH, 0DH,'$'
   STR_SUC_LOAD  DB 'Interrupt has been loaded', 0AH, 0DH,'$'
   STR_IS_UNLOAD  DB 'Interrupt is unloaded', 0AH, 0DH,'$'
DATA      ENDS
          END Main
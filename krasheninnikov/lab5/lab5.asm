ASTACK SEGMENT STACK
   DW 128 DUP(?)
ASTACK ENDS

DATA SEGMENT
   LODED db 0
   KEY db 0

   NOT_LODED  DB 'NOT_LOADED', 0AH, 0DH,'$'
   IN_LODED  DB 'LOADED IN MEMORY', 0AH, 0DH,'$'
   OK_LODED  DB 'LOAD IS SUCCESSFUL', 0AH, 0DH,'$'
   OK_UNLODED  DB 'UNLOAD IS SUCCESSFUL', 0AH, 0DH,'$'
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA, SS:ASTACK

;-------------------------------

MY_INT PROC far
   jmp start
   psp dw ?
   INTERRUPT_ID dw 8f17h
   keep_ip dw ?
   keep_cs dw ?
   keep_ss dw ?
   keep_sp dw ?
   keep_ax dw ?
   CODE_KEY db 43h
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
   cmp al,CODE_KEY
   je ACTION
   call dword ptr cs:keep_ip
   jmp INT_END
   ACTION:

   in al,61h
   mov ah,al
   or al,80h
   out 61h,al
   xchg ah,al
   out 61h,al
   mov al,20h
   out 20h,al

   AGAIN:
   mov ah,05h
   mov cl,'N'
   mov ch,00h
   int 16h
   or al,al
   jz INT_END
   mov ah,0ch
   mov al,00h
   int 21h
   jmp AGAIN
   INT_END:

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
   INT_ENDER:

MY_INT ENDP

;-------------------------------

WRITING PROC near
   push AX
   mov AH,09h
   int 21h
   pop AX
   ret
WRITING ENDP
;-------------------------------

LOAD_FLAG PROC near
   push ax

   mov PSP,es
   mov al,es:[81h+1]
   cmp al,'/'
   jne LOADER_FLAG_END
   mov al,es:[81h+2]
   cmp al, 'u'
   jne LOADER_FLAG_END
   mov al,es:[81h+3]
   cmp al, 'n'
   jne LOADER_FLAG_END
   mov LODED,1h

LOADER_FLAG_END:
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
   sub si,offset MY_INT
   mov dx,es:[bx+si]
   cmp dx, 8f17h
   jne IS_ENDER
   mov KEY,1h
IS_ENDER:
   pop si
   pop ax
   ret
IS_LOAD ENDP

;-------------------------------

LOADER_INT PROC near
   push ax
   push dx

   call IS_LOAD
   cmp KEY,1h
   je IN_LOADE
   jmp START_LOADER

IN_LOADE:
   lea dx,IN_LODED
   call WRITING
   jmp END_LOADER

START_LOADER:
   mov AH,35h
	mov AL,1Ch
	int 21h
	mov KEEP_CS, ES
	mov KEEP_IP, BX

   push ds
   lea dx, MY_INT
   mov ax, seg MY_INT
   mov ds,ax
   mov ah,25h
   mov al, 1Ch
   int 21h
   pop ds
   lea dx, OK_LODED
   call WRITING

   lea dx, INT_ENDER
   mov CL, 4h
   shr DX,CL
   inc DX
   mov ax,cs
   sub ax,PSP
   add dx,ax
   xor ax,ax
   mov AH,31h
   int 21h

END_LOADER:
   pop dx
   pop ax
   ret
LOADER_INT ENDP

;-------------------------------

UNLOADER_INT PROC near
   push ax
   push si

   call IS_LOAD
   cmp KEY,1h
   jne ERR_UNLOAD
   jmp START_UNLOADER

ERR_UNLOAD:
   lea dx,NOT_LODED
   call WRITING
   jmp UNLOADER_END


START_UNLOADER:
   CLI
   PUSH DS
   mov ah,35h
	mov al,1Ch
	int 21h

   mov si,offset KEEP_IP
	sub si,offset MY_INT
	mov dx,es:[bx+si]
	mov ax,es:[bx+si+2]
   MOV DS,AX
   MOV AH,25H
   MOV AL, 1CH
   INT 21H
   POP DS

   mov ax,es:[bx+si-2]
   mov es,ax
   push es

   mov ax,es:[2ch]
   mov es,ax
   mov ah,49h
   int 21h

   pop es
   mov ah,49h
   int 21h
   STI

   lea dx,OK_UNLODED
   call WRITING
UNLOADER_END:
   pop si
   pop ax
   ret
UNLOADER_INT ENDP

;-------------------------------
Main      PROC  FAR
   push  DS
   xor   AX,AX
   push  AX
   mov   AX,DATA
   mov   DS,AX

   call LOAD_FLAG
   cmp LODED, 1h
   je INTIT_UNL
   call LOADER_INT
   jmp ENDER

INTIT_UNL:
   call UNLOADER_INT

ENDER:
   mov ah,4ch
   int 21h
Main      ENDP
CODE      ENDS


          END Main

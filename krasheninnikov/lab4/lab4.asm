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
   jmp STARTER
   
   PSP dw ?
   KEEP_IP dw 0
   KEEP_CS dw 0
   INTERRUPT_ID dw 8f17h
   
   COUNTER db 'Number of interrupts:  0000$'
                  
	KEEP_SS dw ?
	KEEP_SP dw ?
	KEEP_AX dw ?
	INT_STACK dw 64 dup (?)
	END_STACK dw ?
   
STARTER:
   mov KEEP_SS,ss
   mov KEEP_SP,sp
   mov KEEP_AX,ax

   mov ax,cs
   mov ss,ax
   mov sp,offset END_STACK

   push bx
   push cx
   push dx
   

	mov ah,3h
	mov bh,0h
	int 10h
	push dx
   

	mov ah,02h
	mov bh,0h
   mov dh,02h
   mov dl,05h
	int 10h
   
   push si
	push cx
	push ds
   push bp
   
	mov ax,SEG COUNTER
	mov ds,ax
	mov si,offset COUNTER
	add si,22

   mov cx,4  
MAIN_CYC:
   mov bp,cx
   mov ah,[si+bp]
	inc ah
	mov [si+bp],ah
	cmp ah,3Ah
	jne NUM
	mov ah,30h
	mov [si+bp],ah

   loop MAIN_CYC 
    
NUM:
   pop bp
   
   pop ds
   pop cx
   pop si
   

	push es
	push bp
   
	mov ax,SEG COUNTER
	mov es,ax
	mov ax,offset COUNTER
	mov bp,ax
	mov ah,13h
	mov al,00h
	mov cx,27
	mov bh,0
	int 10h
   
	pop bp
	pop es

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

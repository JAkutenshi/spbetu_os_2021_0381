TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
 START: JMP BEGIN
 ; ДАННЫЕ
 type_PC db 'IBM PC Type: PC', 0dh, 0ah, '$'
 type_PC_XT db 'IBM PC Type: PC/XT', 0dh, 0AH, '$'
 type_AT db 'IBM PC Type: AT', 0dh, 0ah, '$'
 type_PS2_30 db 'IBM PC Type: PS2 model 30', 0dh, 0ah, '$'
 type_PS2_50_60 db 'IBM PC Type: PS2 model 50/60', 0dh, 0ah, '$'
 type_PS2_80 db 'IBM PC Type: PS2 model 80', 0dh, 0ah, '$'
 type_PCjr db 'IBM PC Type: PCjr', 0dh, 0ah, '$'
 type_PC_Convertible db 'IBM PC Type: PC Convertible', 0dh, 0ah, '$'

 version db 'MS-DOS version:  .', 0dh, 0ah,'$'
 serial_number db 'Serial number(OEM): .', 0dh,0ah,'$'
 user_number db 'User serial number:      H .$'

 ;ПРОЦЕДУРЫ
 ;-----------------------------------------------------
 TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe NEXT
   add AL,07
   NEXT: add AL,30h
   ret
 TETR_TO_HEX ENDP
 ;-------------------------------
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
 ;-------------------------------
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
 ;--------------------------------------------------
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
 ;-------------------------------

 PC_TYPE PROC near
   mov ax,0f000h
   mov es,ax
   mov al, es:[0fffeh]

   cmp al, 0ffh
   je PC

   cmp al, 0feh
   je PC_XT

   cmp al, 0fbh
   je PC_XT

   cmp al, 0fch
   je AT

   cmp al, 0fah
   je PS2_30

   cmp al, 0fch
   je PS2_50_60

   cmp al, 0f8h
   je PS2_80

   cmp al, 0fdh
   je PCjr

   cmp al, 0f9h
   je PC_Convertible

   end_type:
   call BYTE_TO_HEX
   call print
   ret
 PC_TYPE ENDP

 PC:
   mov dx, offset type_PC
   jmp end_type

 PC_XT:
   mov dx, offset type_PC_XT
   jmp end_type

 AT:
   mov dx, offset type_AT
   jmp end_type

 PS2_30:
   mov dx, offset type_PS2_30
   jmp end_type

 PS2_50_60:
   mov dx, offset type_PS2_50_60
   jmp end_type

 PS2_80:
   mov dx, offset type_PS2_80
   jmp end_type

 PCjr:
   mov dx, offset type_PCjr
   jmp end_type

 PC_Convertible:
   mov dx, offset type_PC_Convertible
   jmp end_type

 ; КОД

 print proc near
   mov ah,09h
   int 21H
   ret
 print endp

 VERSIA_INFO PROC near
   mov ah, 30h
   int 21h
 ;oc-version
   mov si, offset version
   add si,16
   call BYTE_TO_DEC
   mov al,ah
   add si,3
   call BYTE_TO_DEC
   mov dx,offset version
   call print
 ;oem
   mov si, offset serial_number
   add si,20
   mov al,bh
   call BYTE_TO_DEC
   mov dx, offset serial_number
   call print

   ;user number
   mov di, offset user_number
   add di, 23
   mov ax,cx
   call WRD_TO_HEX
   mov al,bl
   call BYTE_TO_HEX
   mov dx, offset user_number
   call print
   ret
 VERSIA_INFO ENDP

 BEGIN:
 call PC_TYPE
 call VERSIA_INFO
 ; Выход в DOS
 xor AL,AL
 mov AH,4Ch
 int 21H
 TESTPC ENDS
 END START ;конец модуля, START - точка входа

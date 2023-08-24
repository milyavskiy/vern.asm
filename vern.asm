.model small
.stack 100h
.code
main proc

mov ax,@data
mov ds,ax

;Clear all registers
xor ax,ax
xor bx,bx
xor cx,cx
xor dx,dx
xor si,si
xor di,di
;;;;;;;;;;;;;;;;;;;;;

;::::::::::::::::::::::::::::::::Command Tail::::::::::::::::::::::::::::

;Check if there is a command tail
mov si,80h
mov cl,es:[si]
cmp cl,0
je jmpHelp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mov di, offset Text

;Check for a space (20h)
Tail:
inc si
mov al,es:[si]
cmp al,20h
jne Write_Buff
;;;;;;;;;;;;;;;;;;;;;;;;;

;Find where to write the tail
cmp di,offset Text
ja A
Loop Tail
jmp Help

A:
cmp di,offset Key
ja B
mov di,offset Key
Loop Tail
jmp Help
;;;;;;;;;;;;;;;;;;;;;;

;Write the tail
Write_Buff:
mov [di],al
inc di
loop Tail
cmp di,offset Key
jbe jmpHelp
xor ax,ax
jmp Default
;;;;;;;;;;;;;;;;;;;;;;;

;Get the position, and check if input is valid
B:
dec cl
xor ax,ax

Get_Pos:
inc si
mov bl,es:[si]
mov var,bx
mov bx,10
cmp var,20h
jne Pos2
Loop Get_Pos
jmp Default

Pos2:
cmp var,'0'
jl Default
cmp var,'9'
jg Default
and var,0Fh
mov di,dx
mul bx
jnc No_DX

push ax
push dx
mov ax,di
mul bx
pop dx
add dx,ax
pop ax

No_DX:
add ax,var
adc dx,0
loop Get_Pos

jmp Go_Around
jmpHelp:
jmp Help
Go_Around:

Default:
push ax
push dx
;;;;;;;;;;;;;;;;

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

;First segment to use for data
mov BuffSeg,ss
add BuffSeg,16
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Open files
mov al,42h
mov dx,offset Text
call Open
mov TextHandle,ax

mov al,40h
mov dx,offset Key
call Open
mov KeyHandle,ax
;;;;;;;;;;;;;;;;

;Get file size
mov al,2
mov bx,TextHandle
mov cx,0
mov dx,0
call Pos
;;;;;;;;;;;;;;;;

;Number of times to loop
mov cx,BuffSize
div cx
cmp dx,0
je No_Add
add ax,1

No_Add:
mov var,ax
;;;;;;;;;;;;;;;;;;;;;;;;

;Position the file pointers
mov al,0
mov cx,0
mov dx,0
call Pos

mov al,0
mov bx,KeyHandle
pop cx
pop dx
call Pos
;;;;;;;;;;;;;;;;;;;;;;;;

mov ah,9
mov dx,offset Hold_Msg
int 21h

cmp var,0
je Close_All

;Read files
mov cx,var
Do:
push cx
mov bx,TextHandle
mov cx,BuffSize
mov dx,0
call Read
mov Len,ax
mov bx,KeyHandle
mov cx,ax
mov dx,BuffSize
Call Read
;;;;;;;;;;;;;;;;;;;;;;;;

;Check if Key is smaller then Text
cmp ax,Len
jb ErrS
Return:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Set up DS
mov si,BuffSize
mov di,0
mov cx,Len
push ds
mov ds,BuffSeg
;;;;;;;;;;;;;;;;;;;;;;;;;;

Crypt:
mov al,[si]
xor [di],al
inc di
inc si
loop Crypt

;Find the position to write to
pop ds
pop cx
mov di,cx
mov ax,var
sub ax,cx
mov cx,BuffSize
mul cx
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mov cx,dx
mov dx,ax
mov al,0
mov bx,TextHandle
call Pos

Call Write

mov cx,di
loop Do

Close_All:
mov bx,TextHandle
call Close

mov bx,KeyHandle
call Close

Exit:
mov ax,4C00h
int 21h

;Error handler
Error:
cmp al,2h
je Err2
cmp al,3h
je Err3
cmp al,4h
je Err4
cmp al,5h
je Err5
cmp al,50h
je Err5
jmp ErrX

ErrS:
mov Len,ax
pop cx
sub var,cx
add var,1
mov cx,1
push cx
mov ah,9
mov dx,offset ErrS_Msg
int 21h
cmp Len,0
je Close_All
jmp Return

Err2:
mov ah,9
mov dx, offset Err2_Msg
int 21h
jmp Exit

Err3:
mov ah,9
mov dx, offset Err3_Msg
int 21h
jmp Exit

Err4:
mov ah,9
mov dx, offset Err4_Msg
int 21h
jmp Exit

Err5:
mov ah,9
mov dx, offset Err5_Msg
int 21h
jmp Exit

ErrX:
mov ah,9
mov dx, offset ErrX_Msg
int 21h
jmp Exit

Help:
mov ah,9
mov dx,offset Help_Msg
int 21h
jmp Exit

jmp Go_Around2
jmpError:
jmp Error
Go_Around2:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

main endp

;:::::::::::::::::::::::::::::::::::::::::::Start the functions:::::::::::::::::::::::::::::::::::
Open proc
mov ah,3Dh
int 21h
jc Error
ret
Open endp

Pos proc
mov ah,42h
int 21h
jc jmpError
ret
Pos endp

Read proc
mov ah,3Fh
push ds
mov ds,BuffSeg
int 21h
pop ds
jc jmpError
ret
Read endp

Write proc
mov ah,40h
mov bx,TextHandle
mov cx,Len
mov dx,0
push ds
mov ds,BuffSeg
int 21h
pop ds
jc jmpError
ret
Write endp

Close proc
mov ah,3Eh
int 21h
jc jmpError
ret
Close endp

;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

.data
BuffSize=32767
Text db 129 dup(0)
Key db 129 dup(0)
TextHandle dw ?
KeyHandle dw ?
BuffSeg dw ?
Len dw ?
var dw 0
Hold_Msg db 'Working...',0Dh,0Ah,'$'
Help_Msg db 'V E R N 1.0',0Dh,0Ah
db 'Usage: VERN File.to.encrypt.or.decrypt Key.file Position(optional)',0Dh,0Ah,'$'
Err2_Msg db 'Error: File not found',0Dh,0Ah,'$'
Err3_Msg db 'Error: Path not found',0Dh,0Ah,'$'
Err4_Msg db 'Error: Too many open files',0Dh,0Ah,'$'
Err5_Msg db 'Error: File could not be accessed',0Dh,0Ah,'$'
ErrS_Msg db 'Warning: Less data in key then text. File partially encrypted',0Dh,0Ah,'$'
ErrX_Msg db 'Unknown Error',0Dh,0Ah,'$'
end main

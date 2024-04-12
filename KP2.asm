.model small
.stack 200h
.data
input_buffer db 6,?,6 dup('?')
number dw 0,? 

.code
main proc
mov ax, @data
mov ds, ax
push ds
call input
call clear_mr
mov bx,15
add number,bx
call output
.exit
main endp

output proc
 mov bx, number
 or bx, bx ;set sf if neg
 jns skip_minus
 mov al, '-'
 int 29h
 neg bx
 skip_minus:
 mov ax, bx
 mov bx, 10
parse_res:
 xor dx, dx
 div bx ;div bx stores quot in dx and res in ax
 add dl, '0' ;one char fits in byte therefore dh useless
 push dx
 inc cx ;remember how many put in stack
 test ax, ax ;in final no residue left, test will set zf
 jnz parse_res
disp:
 pop ax
 int 29h
 loop disp
 ret
 output endp

input proc
 xor ax,ax
 mov ah,10
 mov dx,offset input_buffer
 int 21h 
 xor cx,cx
 mov cl,input_buffer[1]
 ;filling stack in preparation
 lea di,input_buffer[2]
parse:
 mov bl,ds:[di]
 push bx
 inc di
 loop parse
 ;reset counter
 mov cl,input_buffer[1]
 ;getting a number
 xor bx,bx
transform:
 xor ax,ax ;clear ax
 xor bx,bx ;clear bx
 ;pow
 mov dh,dl
 mov bl,10
 mov al,10
 test dh,dh
 jz pow_break 
exp:
 push dx
 mul bx
 pop dx
 dec dh
 test dh,dh
 jnz exp
 push dx
 xor dx,dx
 div bx
 pop dx
pow_break:
 ;/pow
 xor dh,dh
 pop bx ;get input from stack in reverse
 sub bl,'0' ;get number from char
 test dl,dl ;checking if this was 10^0
 jz skip_mul
 push dx ;after next mul dl = 0000
 mul bx ;use bx to mul not by al but by ax
 pop dx
 mov bx,ax
skip_mul:
 add number,bx
 inc dl ;incrementing the next power for 10
 loop transform
 ret
input endp
clear_mr proc ;clear ax,bx,cx,dx
  xor ax,ax
  xor bx,bx
  xor cx,cx
  xor dx,dx
  ret
clear_mr endp
end main
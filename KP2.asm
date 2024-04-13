.model small
.stack 200h
.data
input_buffer db 6,?,6 dup('?')
number dw 0
input_sign_flag db 0

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
 mov ah,10 ;prepare 10-th function
 mov dx,offset input_buffer ;point to buffer to fill later
 int 21h ;call 21 interruption that accepts input
 xor cx,cx ;clear counter just for sake
 ;filling stack in preparation
 lea di,input_buffer[2]
 ;check for minus
 mov bl,ds:[di]
 cmp bl,'-'
 jne parse
 inc input_sign_flag
 inc di
 dec input_buffer[1]
 mov cl,input_buffer[1]
parse:
 mov bl,ds:[di]
 push bx
 inc di
 loop parse
 ;reset counter
 mov cl,input_buffer[1]
 ;getting a number
 mov dl,-1 ;starting counter for pow of 10
transform:
 xor ax,ax ;clear ax
 xor bx,bx ;clear bx
 ;pow
 mov dh,1 ;marker to start mul from 1
 cmp dl,dh ;compare dl counter with marker (dl - dh)
 mov al,10 ;anyway put 10 to make 10^1, check for 0 lower in code
 js pow_break
 ;prepare for pow
 mov bl,10 ;place 10 in bx for pow
 mov dh,dl ;turn dh into count-down 1 = 1 mul 10x10
exp:
 push dx ;save dl exp value
 mul bx ;mul bx by ax
 pop dx ;return saved values
 dec dh 
 test dh,dh ;test if dh zero
 jnz exp
pow_break:
 ;/pow
 pop bx ;get input from stack in reverse
 sub bl,'0' ;get number from char
 test dl,dl ;checking if this was 10^0 (because start from -1)
 js skip_mul
 push dx ;again save dl
 mul bx ;use bx to mul not by al but by ax
 pop dx ;return saved dl
 mov bx,ax 
skip_mul:
 add number,bx
 inc dl ;inc to reflect times 10 x 10 (starts from -1 works from 1)
 loop transform
 ;treat as neg
 mov al,input_sign_flag
 test al,al
 jz skip_neg
 neg number
skip_neg:
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
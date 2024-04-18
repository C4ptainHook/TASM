.model small

.stack 200h

.data 
input_buffer db 7,?,7 dup('?')
result db 'Result: ','$'
number dw 0
input_sign_flag db 0
input_ovf_flag db 0
input_zero_flag db 0
input_empty_flag db 0
input_symbol_flag db 0
welcome_msg db 13,10,'Enter a new number [-32752 <= value <= 32752]',13,10,'$'
continue_msg db 13,10,'Try again. Press 1 = Yes, Else = No',13,10,'$'
overflow_msg db 'You entered value out of bounds[-32752 <= value <= 32752]',13,10,'$'
empty_msg db 'You input nothing',13,10,'$'
zero_msg db 'Number can not start with zero',13,10,'$'
symbol_msg db 'Input contains symbols. Not able to proceed',13,10,'$'

.code 
main proc
restart:
mov ax, @data
mov ds, ax
push ds
call clear_restart_mr
mov ah,9 
mov dx,offset welcome_msg 
int 21h 
call input
;
mov al,input_zero_flag
cmp al,0
jne catch
mov al,input_ovf_flag
cmp al,0
jne catch
mov al,input_symbol_flag
cmp al,0
jne catch
mov al,input_empty_flag
cmp al,0
jne catch
;
call clear_mr ;clean
;
mov bx,15
add number,bx
;
call clear_mr ;clean
;
mov ah, 9
mov dx,offset result
int 21h
;
call output
catch:
mov ah,9 
mov dx,offset continue_msg 
int 21h 
;
mov ah,01h 
int 21h 
cmp al,'1'
je restart
.exit
main endp

output proc stdcall uses ax,bx,cx,dx
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
 cmp input_buffer[1],0
 jne input_exist
 mov ah,9 ;prepare 10-th function
 mov dx,offset empty_msg ;point to buffer to fill later
 int 21h ;call 21 interruption that accepts input
 inc input_empty_flag
 ret
 ;filling stack in preparation
input_exist:
 lea di,input_buffer[2]
 mov cl,input_buffer[1]
 ;check for minus
 mov bl,ds:[di]
 cmp bl,'-'
 jne parse
 inc input_sign_flag
 inc di
 dec input_buffer[1]
 mov cl,input_buffer[1]
 ;check for too large value
 parse:
 mov bl,ds:[di]
 cmp bl, '0' 
 jb not_a_number 
 cmp bl, '9' 
 ja not_a_number 
 inc di
 loop parse
 mov al,input_symbol_flag
 test al,al
 jz parse_push_prep
 not_a_number:
 xor ax,ax
 mov ah,9 
 mov dx,offset symbol_msg 
 int 21h 
 inc input_symbol_flag
 mov al,input_symbol_flag
 ret
parse_push_prep:
 mov cl,input_buffer[1]
 lea di,input_buffer[2]
 mov bl,input_sign_flag
 test bl,bl
 jz check_first_zero
 inc di
check_first_zero:
 cmp input_buffer[1], 1
 je check_ovf
 mov bl,ds:[di]
 cmp bl,'0'
 jne check_ovf
 xor ax,ax
 mov ah,9 
 mov dx,offset zero_msg 
 int 21h 
 inc input_zero_flag
 ret
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
check_ovf:
 cmp input_buffer[1], 5
 jb parse_push
 mov bl,ds:[di]
 cmp bl,'4'
 jb parse_push
 xor ax,ax
 mov ah,9 
 mov dx,offset overflow_msg 
 int 21h 
 inc input_ovf_flag
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ret
parse_push:
 mov bl,ds:[di]
 push bx
 inc di
 loop parse_push
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
 mov ax,number
 add ax,bx
 ;without this section weird stuff is happening with of in cmp (possibly sign trouble)
 cmp ax,32752
 ;end of sign coersion
 jbe skip_ovf_throw
 inc input_ovf_flag
skip_ovf_throw:
 add number,ax
 inc dl ;inc to reflect times 10 x 10 (starts from -1 works from 1)
 loop transform
 mov al, input_ovf_flag
 test al,al
 jz neg_processing
 xor ax,ax
 mov ah,9 
 mov dx,offset overflow_msg 
 int 21h 
 ret
 ;treat as neg
neg_processing:
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
  xor di,di
  ret
clear_mr endp

clear_restart_mr proc 
 call clear_mr ;clean
 mov number,ax
 mov input_ovf_flag,al 
 mov input_zero_flag,al 
 mov input_symbol_flag,al
 mov input_empty_flag,al
 ret
clear_restart_mr endp
end main
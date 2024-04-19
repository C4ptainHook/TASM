.model small

.stack 200h

.data 
NEG_LIM equ 32768
POS_LIM equ 32752
input_buffer db 7,?,7 dup('?')
result db 'Result: ','$'
number dw 0
input_sign_flag db 0
input_ovf_flag db 0
input_zero_flag db 0
input_empty_flag db 0
input_symbol_flag db 0
welcome_msg db 13,10,'Enter a new number [-32768 <= value <= 32752]',13,10,'$'
continue_msg db 13,10,'Try again. Press 1 = Yes, Else = No',13,10,'$'
overflow_msg db 'You entered value out of bounds [-32768 <= value <= 32752]',13,10,'$'
empty_msg db 'You input nothing',13,10,'$'
zero_msg db 'Number can not start with zero',13,10,'$'
symbol_msg db 'Input contains symbols. Not able to proceed',13,10,'$'

.code 
.286
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
call catch_exc
test ah,ah
jnz catch
;
mov bx,15
add number,bx
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
 jne check_first_zero
 inc input_sign_flag
 inc di
 dec input_buffer[1]
 mov cl,input_buffer[1]
 ;check for 01 situation
 check_first_zero:
 cmp input_buffer[1], 1
 je parse
 mov bl,ds:[di]
 cmp bl,'0'
 jne parse
 xor ax,ax
 mov ah,9 
 mov dx,offset zero_msg 
 int 21h 
 inc input_zero_flag
 dec cl
 ret
 ;check for too large value
 parse:
 mov bl,ds:[di]
 cmp bl,'0' 
 jb not_a_number 
 cmp bl,'9' 
 ja not_a_number 
 sub bl,'0' ;get number from char
 mov ax,number
 imul ax,10
 jc overfl
 add ax,bx
 jmp no_overflow
overfl:
 call input_ovf_exc
 ret
no_overflow:
 mov number,ax
 inc di
 loop parse
 ;check sign
 mov dl,input_sign_flag
 test dl,dl
 jz check_positive_ovf
 cmp ax,NEG_LIM
 ja overfl
 neg ax
 mov number,ax
 jmp exit
check_positive_ovf:
 cmp ax,POS_LIM
 ja overfl
exit:
 ret
 ;handle symbol exception
 not_a_number:
 call input_symbol_exc
 ret
 input endp
 
input_symbol_exc proc
 xor ax,ax
 mov ah,9 
 mov dx,offset symbol_msg 
 int 21h 
 inc input_symbol_flag
 ret
 input_symbol_exc endp
 
input_ovf_exc proc
 mov ah,9 
 mov dx,offset overflow_msg 
 int 21h 
 inc input_ovf_flag
 ret
 input_ovf_exc endp

clear_mr proc ;clear ax,bx,cx,dx
  xor ax,ax
  xor bx,bx
  xor cx,cx
  xor dx,dx
  xor di,di
  ret
clear_mr endp

catch_exc proc 
mov al,input_zero_flag
mov ah,input_ovf_flag
or ah,al
mov al,input_symbol_flag
or ah,al
mov al,input_empty_flag
or ah,al
ret
catch_exc endp

clear_restart_mr proc 
 call clear_mr ;clean
 mov number,ax
 mov input_sign_flag,al 
 mov input_ovf_flag,al 
 mov input_zero_flag,al 
 mov input_symbol_flag,al
 mov input_empty_flag,al
 ret
clear_restart_mr endp
end main
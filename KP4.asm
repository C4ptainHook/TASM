.model small

.stack 100h

.data 
NEG_LIM equ 32768
POS_LIM equ 32767
MAX_SIZE equ 64
input_buffer db 7,?,7 dup('?')
number dw 0
;arr
main_array dw MAX_SIZE dup(0)
clone_array dw MAX_SIZE dup(0)
arr_size dw 0
STEP equ 2
;input
input_sign_flag db 0
input_ovf_flag db 0
input_zero_flag db 0
input_empty_flag db 0
input_symbol_flag db 0
;cases
case_fail_flag db 0
;ERROR
;input
overflow_exc db 'WARNING You entered value out of bounds [-32768 <= value <= 32767]',13,10,'$'
empty_exc db 'You input nothing',13,10,'$'
zero_exc db 'ERROR Number can not start with zero',13,10,'$'
symbol_exc db 'ERROR Input contains symbols. Not able to proceed',13,10,'$'
;menu
wrong_choice_war db 'WARNING. No such option',13,10,'$'
;cases
case_fail_exc db 255 dup('$')
wrong_array_size_exc db 13,10,'Wrong array size. Can be [1-64]',13,10,'$'
wase equ $-wrong_array_size_exc-1
sum_ovf_exc db 13,10,'ERROR During sum proccess encountered overflow. Consider another array',13,10,'$'
;UI
;menu
new_arr_msg db 13,10,'1. Enter NEW array',13,'$'
sum_msg db 13,10,'2. Find SUM of the elements',13,'$'
min_msg db 13,10,'3. Find MIN of the elements',13,'$'
sort_msg db 13,10,'4. SORT the array',13,10,'$'
exit_msg db 13,10,'5. Exit program',13,10,'$'
;cases
array_size_msg db 13,10,'Input array size [1-64]',13,10,'$'
new_el_msg db 13,10,'Input new element [-32768 <= element <= 32767]',13,10,'$'
result_msg db 13,10,'Result: ','$'
;repeat
repeat_msg db 255 dup('$')
continue_msg db 13,10,'TRY AGAIN? Press 1 = YES, Else = NO',13,10,'$'
rep_size_msg db 13,10,'Do you want to input array size again. 1 = YES, Else = Back to menu',13,10,'$'
rsmg equ $-rep_size_msg-1
rep_new_el_msg db 13,10,'Do you want to input the element again. 1 = YES, Else = Back to menu',13,10,'$'
rnmg equ $-rep_new_el_msg-1
.code 
.286
main proc
;preparation
restart:
mov ax, @data
mov ds, ax
mov es, ax ;for chain manipulation commands
push ds
start:
call clear_restart_mr
call print_menu
call validate_case_choice
call catch_exc
test ah,ah
jnz start
;switch (based on X and Y)
mov al, byte ptr number 
cmp al,1
je case1
cmp al,2
je case2
cmp al,3
je case3
cmp al,4
je case4
cmp al,5
je exit
case1 :  ;New array
call case1_p
jmp break
case2 :  ;Find SUM
call case2_p
jmp break
case3 :  ;Find MIN
call case3_p
jmp break
case4 :  ;SORT
call case4_p
break:
jmp start
exit:
.exit
main endp

copy_exc_string proc stdcall uses ax si cx
lea di,case_fail_exc 
cld
rep movsb 
ret
copy_exc_string endp

copy_msg_string proc stdcall uses ax si cx
lea di,repeat_msg 
cld
rep movsb 
ret
copy_msg_string endp

clear_universal_string proc stdcall uses ax cx di si
mov al, '$'
std
rep stosb 
ret
clear_universal_string endp

case1_p proc
input_arr_size_again:
mov ah, 09h
lea dx,array_size_msg
int 21h
call clear_mr
call input
call catch_exc
test ah,ah
jnz catch_case
cmp number,1
jl catch_case_double
cmp number,MAX_SIZE
jg catch_case_double
jmp proceed
catch_case_double:
inc case_fail_flag
lea si,wrong_array_size_exc
mov cl,wase
call copy_exc_string
call catch_case_exc
call clear_universal_string
catch_case:
lea si,rep_size_msg
mov cl,rsmg
call copy_msg_string
call handle_repeat_msg
call clear_universal_string
cmp al,'1' ;handle repeat (1 line before) invokes 01h proc
je input_arr_size_again
proceed:
mov ax, number
mov arr_size,ax
mov cx,arr_size
fill_arraye:
input_elem_again:
mov ah, 09h
lea dx,new_el_msg
int 21h
call clear_mr
call input
call catch_exc
test ah,ah
jz next
push cx
lea si,rep_new_el_msg
mov cl,rnmg
call copy_msg_string
call handle_repeat_msg
call clear_universal_string
cmp al,'1' 
pop cx
je input_elem_again
ret ;exit from proc
next:
mov ax,number
mov main_array[bx],ax
add bx,STEP
loop fill_arraye
ret
case1_p endp

case2_p proc
xor ax,ax
mov cx, arr_size
lea bx,main_array
sum:
mov dx,[bx]
add bx,STEP
add ax,dx
jo case_catch
loop sum
push ax
mov ah,09h
lea dx, result_msg
int 21h
pop ax
call print
mov al,13
int 29h
mov al,10
int 29h
ret
case_catch:
mov ah,09h
lea dx,sum_ovf_exc
int 21h
ret
case2_p endp

case3_p proc 

ret
case3_p endp

case4_p proc

ret
case4_p endp

;input block start
input proc stdcall uses ax bx cx dx si di
 xor ax,ax
 mov ah,10 ;Prepare 10-th function
 mov dx,offset input_buffer ;point to buffer to fill later
 int 21h ;Call 21 interruption that accepts input
 cmp input_buffer[1],0 ;check if there is no chars in the input
 jne input_exist
 mov ah,9 ;Prepare 10-th function
 mov dx,offset empty_exc ;point to buffer to fill later
 int 21h ;Call 21 interruption that accepts input
 inc input_empty_flag
 ret
input_exist:
 lea di,input_buffer[2]
 mov cl,input_buffer[1]
 ;Check for minus
 mov bl,ds:[di]
 cmp bl,'-'
 jne check_first_zero
 inc input_sign_flag
 inc di
 dec input_buffer[1]
 mov cl,input_buffer[1]
 ;Check for 01 situation
 check_first_zero:
 cmp input_buffer[1], 1
 je parse
 mov bl,ds:[di]
 cmp bl,'0'
 jne parse
 xor ax,ax
 mov ah,9 
 mov dx,offset zero_exc
 int 21h 
 inc input_zero_flag
 dec cl
 ret
 parse:
 mov bl,ds:[di]
 cmp bl,'0' 
 jb not_a_number 
 cmp bl,'9' 
 ja not_a_number 
 sub bl, '0' ;Get number from char
 mov ax,number
 push bx
 mov bx,10
 mul bx
 pop bx
 jc overfl
 add ax,bx
 jc overfl
 jmp no_overflow
overfl:
 call input_ovf_exc
 ret
no_overflow:
 mov number,ax
 inc di
 loop parse
 ;Check sign
 mov dl,input_sign_flag
 test dl,dl
 jz check_positive_ovf
 cmp ax,NEG_LIM
 ja overfl
 neg ax
 mov number,ax
 ret
check_positive_ovf:
 cmp ax,POS_LIM
 ja overfl
 ret
 ;Handle symbol exception
 not_a_number:
 call input_symbol_exc
 ret
 input endp
 
input_symbol_exc proc
 xor ax,ax
 mov ah,9 
 mov dx,offset symbol_exc
 int 21h 
 inc input_symbol_flag
 ret
input_symbol_exc endp
 
input_ovf_exc proc
 mov ah,9 
 mov dx,offset overflow_exc 
 int 21h 
 inc input_ovf_flag
 ret
input_ovf_exc endp
 ;input block end
 
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

catch_case_exc proc stdcall uses ax dx
mov al,case_fail_flag
test al,al
jnz handle
ret
handle:
mov ah,09h
lea dx,case_fail_exc
int 21h
ret
catch_case_exc endp

handle_repeat_msg proc stdcall uses dx
mov ah,09h
lea dx,repeat_msg
int 21h
mov ah,01h 
int 21h 
ret
handle_repeat_msg endp

clear_mr proc stdcall uses ax ;Clear ax,bx,cx,dx
  xor ax,ax
  mov input_sign_flag,al 
  mov input_ovf_flag,al 
  mov input_zero_flag,al 
  mov input_symbol_flag,al
  mov input_empty_flag,al
  mov number,ax
  ret
clear_mr endp

print_menu proc stdcall uses ax dx
mov ah,9
lea dx, new_arr_msg
int 21h
lea dx, sum_msg
int 21h
lea dx, min_msg
int 21h
lea dx, sort_msg
int 21h
ret
print_menu endp

print proc
cmp ax,0
jge skip_minus
push ax
mov al, '-'
int 29h
pop ax
neg ax
skip_minus:
push cx
mov bx, 10                          
xor cx, cx                          
parse_el:
xor dx, dx                          
div bx                              
push dx                             
inc cx                              
test ax, ax                         
jnz parse_el                        
print_num_inner:
pop ax                              
or al, 00110000b  ; Conversion to ASCII = ADD '0'
int 29h                             
loop print_num_inner 
pop cx 
ret
print endp

print_1d_arr proc stdcall uses ax bx cx dx  
lea si,main_array
cld
mov cx,arr_size
mov al,10
int 29h
print_array:
cmp cx,arr_size
je skip_sep 
mov al,','
int 29h
skip_sep:
lodsw
call print                    
loop print_array
ret
print_1d_arr endp

validate_case_choice proc 
call input
cmp number,1
jl raise
cmp number,5
jg raise
ret
raise:
mov ah,9
lea dx, wrong_choice_war
int 21h
inc input_ovf_flag
ret
validate_case_choice endp

clear_restart_mr proc 
 call clear_mr ;Clean
  xor ax,ax
  xor bx,bx
  xor cx,cx
  xor dx,dx
  xor di,di
  xor si,si
 ret
clear_restart_mr endp
 
end main
 
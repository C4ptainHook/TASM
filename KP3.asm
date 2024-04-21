.model small

.stack 200h

.data 
result_string db 30 dup ('$')
NEG_LIM equ 32768
POS_LIM equ 32767
input_buffer db 7,?,7 dup('?')
result db 10,'Result: ','$'
number dw 0
x dw 0
y dw 0
input_sign_flag db 0
input_ovf_flag db 0
input_zero_flag db 0
input_empty_flag db 0
input_symbol_flag db 0
case_fail_flag db 0
enter_x_msg db 13,10,'Enter a X number [-32768 <= value <= 32767]',13,10,'$'
enter_y_msg db 13,10,'Enter a Y number [-32768 <= value <= 32767]',13,10,'$'
continue_msg db 13,10,'Try again. Press 1 = Yes, Else = No',13,10,'$'
overflow_msg db 'WARNING You entered value out of bounds [-32768 <= value <= 32767]',13,10,'$'
case_fail_msg db 'WARNING Value out of bounds [-32768 <= value <= 32767] appeared in calculations',10,'Consider another input values...',13,10,'$'
empty_msg db 'You input nothing',13,10,'$'
zero_msg db 'ERROR Number can not start with zero',13,10,'$'
symbol_msg db 'ERROR Input contains symbols. Not able to proceed',13,10,'$'

.code 
.286
main proc
restart:
;preparation
mov ax, @data
mov ds, ax
mov es, ax ;for chain manipulation commands
push ds
call clear_binp_mr
;input X
mov ah,9 
mov dx,offset enter_x_msg 
int 21h 
call input
mov bx, number
mov x,bx
call catch_exc
test ah,ah
jnz catch
;clear number
xor ax,ax
mov number,ax
;input Y
mov ah,9
mov dx,offset enter_y_msg 
int 21h 
call clear_binp_mr 
call input
mov bx, number
mov y,bx
xor dx,dx ;clean dx from msg
;input exception handling
call catch_exc
test ah,ah
jnz catch
;switch (based on X and Y)
cmp y,0
je case1
jl case2
jg case3
case1 :  ;y = 0
call case1_p
jmp break
case2 :  ;y < 0
call case2_p
jmp break
case3 :  ;y > 0 x = 5
cmp x,5
jne case4
call case3_p
jmp break
case4 :  ;other
call case4_p
;
break:
mov dl,case_fail_flag
test dl,dl
jz convert
mov ah, 9
mov dx,offset case_fail_msg
int 21h
jmp catch
;
convert:
lea di, result_string
call convert_whole_part
test dl,dl
jz print_result
mov byte ptr es:[di], '.'
inc di
call convert_float_part
;
print_result:
mov ah, 9
mov dx,offset result
int 21h
mov dx,offset result_string
int 21h
;
catch:
mov ah,9 
mov dx,offset continue_msg 
int 21h 
;
mov ah,01h 
int 21h 
cmp al,'1'
jne exit
jmp restart
exit:
.exit
main endp

;switch-case block
case1_p proc stdcall uses bx
xor ax,ax
xor bx,bx
mov ax,x
call ax_sqr
mov bx,25
mul bx
jc c1_catch
ret
c1_catch:
inc case_fail_flag
ret
case1_p endp

case2_p proc
xor ax,ax
xor bx,bx
mov ax,y
call ax_sqr
imul ax,5
jc c2_catch
mov bx,ax ;put divisor in bx
xor ax,ax ;clear ax for dividend
mov ax,x
imul ax,38
jc c2_catch
jo c2_catch
test ax,ax
jns division
cwd
division:
idiv bx
ret
c2_catch:
inc case_fail_flag
ret
case2_p endp

case3_p proc 
xor ax,ax
xor bx,bx
mov bx,y
mov ax,x
call ax_cqb
imul ax,6
div bx
ret
case3_p endp

case4_p proc
xor ax,ax
mov al,1
ret
case4_p endp

;exp block
ax_cqb proc stdcall uses bx
xor bx,bx
mov bx,ax
call ax_sqr
imul bx
ret
ax_cqb endp

ax_sqr proc
imul ax
jnc exit_sqr
inc case_fail_flag
exit_sqr:
ret
ax_sqr endp
;input block start
input proc stdcall uses ax bx cx dx
 xor ax,ax
 mov ah,10 ;Prepare 10-th function
 mov dx,offset input_buffer ;point to buffer to fill later
 int 21h ;Call 21 interruption that accepts input
 cmp input_buffer[1],0 ;check if there is no chars in the input
 jne input_exist
 mov ah,9 ;Prepare 10-th function
 mov dx,offset empty_msg ;point to buffer to fill later
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
 mov dx,offset zero_msg 
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
 ;input block end
 
clear_mr proc ;Clear ax,bx,cx,dx
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

clear_binp_mr proc ;binp = before input
 call clear_mr ;Clean
 mov number,ax
 mov input_sign_flag,al 
 mov input_ovf_flag,al 
 mov input_zero_flag,al 
 mov input_symbol_flag,al
 mov input_empty_flag,al
 mov case_fail_flag,al
 ret
clear_binp_mr endp

; Quotient to decimal
; Quotient = value in AX after div/idiv
convert_whole_part proc stdcall uses ax bx cx dx    
    or ax,ax
    jns skip_minus
    push ax
    mov al, '-'
    stosb
    pop ax
    neg ax
  skip_minus:
    mov bx, 10                          ; Prepare divisor value
    xor cx, cx                          ; Clean counter of numbers
  parse_quot:
    xor dx, dx                          
    div bx                              
    push dx                             
    inc cx                              
    test ax, ax                         ; Check inner quotient
    jnz parse_quot                      ; No: once more
  append_str_quot:
    pop ax                              ; Get back pushed digits
    or al, 00110000b                    ; Conversion to ASCII = ADD '0'
    stosb                               ; Append char to the postion by es:di ptr
    loop append_str_quot                      
    mov byte ptr es:[di], '$'           ; End of string char for 21h int
    ret
    convert_whole_part endp                    
    
; Remainder to decimal
; Remainder = numbers after period .000, stored in DX after div/idiv
convert_float_part proc stdcall uses ax bx cx dx    
    mov cx, 20                          ; limit of fractional digits
    @@LBL1:
    mov ax, dx                          ; Move remainder to AX
    test ax,ax
    jns skip_deneg
    neg ax
skip_deneg:
    xor dx, dx
    imul ax, 10
    div bx
    or al, 00110000b                    ; Conversion to ASCII = ADD '0'
    stosb                               ; Append char to the postion by es:di ptr
    test dx, dx
    loopnz @@LBL1                       ; loop if ZF == 0 ( by test) and CX <> 0
    mov byte ptr es:[di], '$'           ; End of string char for 21h int
    ret
    convert_float_part endp
end main
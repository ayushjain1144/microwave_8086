.model tiny
.data

sec dw 0         ;Stores the total time left for the countdown
power db 0          ;Stores the number of power presses
start db 0         ;Stores the number of start button presses
stop db 0        ;Stores the number of stop button presses

disp equ 1015h         ;Next 4 bytes will be stored for 4-digit BCD count
display_table equ 1019h     ;Display table for displaying digits on the 7-segement display
inp equ 1029h            ;Stores the input from the port - to check which button is pressed
time_loop equ 1030h
align 2
print dw 0  
start_flag db 0
stop_flag db 0
time_flag db 0 
flag_10m db 0
flag_1m db 0
flag_10s db 0
power_flag db 0
button_flag db 0
power_value dw 0
temp db 0
temp2 db 0
quick_flag db 0
out_flag db 0 
ms_status db 0
ms_flag db 0

;8255(A) 
A_a equ 5000h
A_b equ 5002h
A_c equ 5004h
A_creg equ 5006h

;8255(B)
B_a equ 6000h
B_b equ 6002h
B_c equ 6004h
B_creg equ 6006h

db 1024 dup(0) ;Initially reserving first 1K of memory for IVT

.code
.startup


;Display Table Initialization
mov si,display_table
mov byte ptr [si],3fh
inc si
mov byte ptr [si],06h
inc si
mov byte ptr [si],5bh
inc si
mov byte ptr [si],4fh
inc si
mov byte ptr [si],66h
inc si
mov byte ptr [si],6dh
inc si
mov byte ptr [si],7dh
inc si
mov byte ptr [si],07h
inc si
mov byte ptr [si],7fh
inc si
mov byte ptr [si],67h
inc si

;Initializing 8255(A)
mov al,10000000b    ;Because all ports are input ports, we make them output for bsr
mov dx,A_creg
out dx,al
mov al,00001010b    ;Buzzer Indicator OFF
out dx,al
mov al,00001100b    ;Power input can be taken
out dx,al
mov al,00001001b    ;Countdown can't be started
out dx,al

;PC0 - PC3 set 1 -- which means all the 4 seven segement displays are disabled
mov al,00000001b
out dx,al
mov al,00000011b
out dx,al
mov al,00000101b
out dx,al
mov al,00000111b
out dx,al

;Initializing 8255(B)
mov al,10000010b  ;Port B is taken as input
mov dx,B_creg
out dx,al

;Initializing the values at the following addresses:

mov sec , 0 ;Total no. of seconds loaded initially
mov power,-1 ;No. of times Power is pressed
mov start,0 ;No. of times start is pressed
mov stop,00 ;No. of times stop is pressed

;Initializing timers--------------------------------------------------------------------
mov al,00010001b      ;TIMER2 COUNTER 0 Control Word
mov dx,3006h
out dx,al
;----------------------------------------------------------------------------

button_press:
	mov quick_flag, 0
	mov sec , 0
	call check_button
	cmp button_flag, 0
	jz button_press

	cmp start_flag, 0
	jz x1

	jmp quick_start  
	jqs: jmp button_press 


x1:

	mov power_value, 90
	mov ms_status , 09
	cmp power_flag, 0
	jz x2
	mov temp2 , 1
	cp:
		call display_power

		cmp power_flag, 0
		jz x2                   
		inc temp2
	jmp cp                     
;-------------------------------------
display_power proc near 
	
	call calculate_power
	mov ax , power_value
	mov print , ax

	cd:
		call display
		call check_button

		cmp button_flag , 00
	jz cd
ret
display_power endp
;-----------------------------------------
calculate_power proc near
	
	mov cl , temp2
	mov ch, 0
	mov ax, cx
	mov bl, 3
	
	div bl
		cmp ah, 0
		jnz p1			            
		mov power_value, 30
		mov ms_status , 03
		jmp r 

	p1:
		cmp ah, 1
		jnz p2
		
		mov power_value, 90
		mov ms_status , 09
		jmp r

	p2:
		cmp ah, 2                    
		mov power_value, 60
		mov ms_status , 06
		jmp r


	r: ret 
	calculate_power endp
;------------------------------------------
quick_start:
mov sec,0
mov power_value, 90d
mov ms_status , 09d
mov quick_flag, 1
call enable_lock
qs:
	mov ax , sec
	add ax , 30
	mov sec , ax
	mov print,ax
	jmp timer_display	
;------------------------------------------
x2:
cmp stop_flag, 0
jnz button_press
cmp start_flag, 0
jnz cp   


      ;cmpheck the time set

before_start_normal:

time_set:
	cmp flag_10m, 0
	jz call_1m
	mov ax , sec
	add ax , 600d
	mov sec , ax
	mov print , ax
	cd1:
		call display
		call check_button
		cmp button_flag , 00
	jz cd1              ; here we need to display the value of button pressed not total time

	jmp time_set


call_1m:
	cmp flag_1m, 0
	jz call_10s
	mov ax , sec
	add ax , 60d
	mov sec , ax
	mov print , ax
	jmp cd1  ; here we need to display the value of button pressed not total time
	

call_10s:
	;call check_1s ; is it needed?
	cmp flag_10s, 0
	jz final
	mov ax , sec
	add ax , 10d
	mov sec , ax
	mov print , ax 
	jmp cd1  ; here we need to display the value of button pressed not total time
	


final: 
	cmp start_flag, 0
	jnz cooking
	cmp stop_flag, 0
	jnz button_press
	
;-------------------------------------------------
cooking:

;-----------------
call enable_lock
timer_display:
	
	mov ax , sec
	mov print , ax
	call check_ms_status
	call display	
	call delay_1s
	dec sec
	jnz ccb 
	mov print, 0
	call display
	call enable_buzzer
	call remove_lock
	call power_off
	kunda1: call check_button
	cmp button_flag, 0
	jz kunda1
	cmp stop_flag, 1
	jnz kunda1
	call delay
	call reset
	jmp dead
	ccb: call check_button
	cmp button_flag, 0
	jz timer_display


cmp quick_flag, 1
jnz ayush1
cmp start_flag, 0
jnz qs 

ayush1:  
cmp stop_flag, 0
jnz final_stop

;call check_countdown ; it should become 0 when count is cleared to be made:::Burhan 
;cmp count_flag, 0
jmp timer_display
;-----------------------------
reset proc near
	mov print, 0
	call display
	mov sec, 0 
	call stop_buzzer
	call remove_lock
	call power_off
	ret
reset endp	
;---------------------------
final_stop:
	call power_off
	call remove_lock
	mov ax, sec
	mov print, ax
	cb: call display
	call check_button
	cmp button_flag, 0
	jz cb

cmp stop_flag, 0
jz burhan
call reset
jmp dead

burhan: 
cmp start_flag, 0
jz time_handle

call enable_lock
cmp quick_flag, 0
jnz timer_display
jmp before_start_normal

time_handle:

cmp quick_flag, 0
jnz final_stop
jmp time_set

;----------------------------------
remove_lock proc near
	mov ax,00001110b ;pc7 resets i.e lock led turns off
	mov dx, A_creg
	out dx,al
ret 
remove_lock endp
;---------------------------------
enable_lock proc near
	mov ax,00001111b ;pc7 resets i.e lock led turns on
	mov dx, A_creg
	out dx,al
ret 
enable_lock endp
;---------------------------------
stop_buzzer proc near
	mov ax,00001010b ;pc5 sets i.e buzzer led turns off
	mov dx,A_creg
	out dx,al
ret
stop_buzzer endp
;-------------------------------
enable_buzzer proc near
	mov ax,00001011b ;pc5 sets i.e buzzer led glows
	mov dx,A_creg
	out dx,al
ret 
enable_buzzer endp
;-------------------------------------------------
power_on proc near
    mov al, 00001101b
    mov dx, A_creg
    out dx, al
ret
power_on endp

 power_off proc near
 	mov al, 00001100b
 	mov dx, A_creg
 	out dx,al
 ret
 power_off endp
;--------------------------------------------------

check_ms_status proc near
mov ax , sec
mov bl , 10d
div bl 

cmp ah , ms_status
jb l1
call power_off
jmp r
l1:

call power_on

r: ret 
check_ms_status endp

;---------------------------------------------
display proc near
mov si,disp
mov di,offset print

mov ax, [di]         ;Current number of seconds is stored in AX now
;mov ax , 1234d
mov bx,10

xor dx,dx
div bx
mov [si],dl         ;Remainder is in DL as remainder is not greater than 9, so no need to considerDH - Hence we extract the last digit

xor dx,dx           ;Digit at Tens place
div bx
mov [si+1],dl

xor dx,dx        ;Digit at hundredth place
div bx
mov [si+2],dl

xor dx,dx         ;Digit at Thousandth place
div bx
mov [si+3],dl

mov di,display_table
;Display Last Digit
mov al,[si]
mov bl,al
xor bh,bh
mov ax,[di+bx]         ;So the displacement is equal to the digit we have
mov dx,B_a
out dx,al

mov ax, 00000001b        ;Previous display disabled
mov dx,A_creg
out dx,al
mov ax, 00000110b         ;Last digit shown
out dx,al
call delay

mov al,[si+1]
mov bl,al
mov ax,[di+bx]
mov dx,B_a
out dx,al

mov ax, 00000111b        ;Previous display disabled
mov dx,A_creg
out dx,al
mov ax, 00000100b        ;Second Last digit shown
out dx,al
call delay

mov al,[si+2]
mov bl,al
mov ax,[di+bx]
mov dx,B_a
out dx,al

mov ax, 00000101b         ;Previous display disabled
mov dx,A_creg
out dx,al
mov ax, 00000010b        ;Digit at Hundredth place shown
out dx,al
call delay

mov al,[si+3]
mov bl,al
mov ax,[di+bx]
mov dx,B_a
out dx,al
mov ax, 00000011b    ;Previous display disabled
mov dx,A_creg
out dx,al
mov ax, 00000000b    ;Digit at thousandth place shown
out dx,al
call delay

mov ax, 00000001b     ;Finally clearing the previous display also
out dx,al

ret
display endp
;---------------------------------------------------------------------
delay proc near
mov cx, 15000d
l5:    dec cx
loop l5
ret
delay endp

delay_1s proc near
mov al, 01             ;Loading count into TIMER2 COUNTER 0
mov dx,3000h
out dx,al
sahil:
call check_out 
cmp out_flag , 00h
jz sahil
ret
delay_1s endp
;---------------------------------------------------------

;procedure to check flags

check_button proc near 
mov button_flag , 00h
mov bh , 00
mov [temp], 00
call check_start
mov bh, start_flag
add [temp] , bh
call check_stop
mov bh, stop_flag
add [temp] , bh
call check_power
mov bh, power_flag
add [temp] , bh
call check_10m
mov bh, flag_10m
add [temp] , bh
call check_1m
mov bh, flag_1m
add [temp] , bh
call check_10s
mov bh, flag_10s
add [temp] , bh
mov al, [temp]
mov button_flag , al
ret
check_button endp

check_start proc near 
mov start_flag , 00h
mov dx,B_b
in al,dx
and al , 10h
jnz c2
mov start_flag , 01d

jmp r
c2:	mov start_flag , 00d

r:
 ret
check_start endp

check_stop proc near
mov stop_flag , 00h
mov dx,B_b
in al,dx
and al , 20h
jnz c2
mov stop_flag , 01d
jmp r
c2:	mov stop_flag , 00d
r:
 ret
check_stop endp


check_power proc near
mov power_flag , 00h
mov dx,B_b
in al,dx
and al , 08h
jnz c2
	
	mov power_flag , 01d
	jmp r
	c2:	
	mov power_flag , 00d
	jmp r
	r:
 ret
check_power endp


check_10m proc near 
mov flag_10m , 00h
mov dx,B_b
in al,dx
and al , 01h
jnz c2
mov flag_10m , 01d
jmp r
c2:	mov flag_10m , 00d
r:
 ret
check_10m endp

check_1m proc near
mov flag_1m , 00h
mov dx,B_b
in al,dx
and al , 02h
jnz c2

mov flag_1m , 01d
jmp r
c2:	mov flag_1m , 00d
r:
 ret
check_1m endp

check_10s proc near
mov flag_10s , 00h
mov dx,B_b
in al,dx
and al , 04h
jnz c2
mov flag_10s , 01d
jmp r
c2:	mov flag_10s , 00d
r:
 ret
check_10s endp

check_out proc near
mov out_flag , 00h
mov dx , B_c
in al , dx
and al , 02h
jz c2
mov out_flag , 01d
jmp r
c2: mov out_flag , 00d
r:
ret
check_out endp
;-------------------------------------------

dead:
jmp button_press

.exit
end

;--------------------------------------------

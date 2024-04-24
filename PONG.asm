.model small
.286
.stack 100h
.data
		screen_width db 79
		screen_height db 24
		screen_bounds db 0

		ball_original_x db 39
		ball_original_y db 12
		ball_x db 39
		ball_y db 12
		time_aux db 0
		ball_speed_x db 1
		ball_speed_y db 1
		
		table_left_x db 0
		table_left_y db 9
		table_right_x db 77	
		table_right_y db 9
		table_width db 2
		table_height db 6 	
		table_speed db 1
		
		PLAYER1_SCORE dw 0
		PLAYER2_SCORE dw 0
		DIGIT_DISPLAY_NOE DB 0
		SCORE_STRING DB 'SCORE', 0ah, 0dh, '$' ;strings for displaying on the screen
		PLAYER_1_WINS DB 'PLAYER 1 WON', 0ah, 0dh, '$'
		PRESS_INFO DB 'PRESS ANY KEY TO START AGAIN', 0ah, 0dh, '$'
		PRESS_INFO_2 DB 'PRESS AND HOLD Q TO QUIT', 0ah, 0dh, '$'
		PLAYER_2_WINS DB 'PLAYER 2 WON', 0ah, 0dh, '$'
		placeholder dw ?
.code
main proc

mov ax, @data
mov ds, ax
call play_sound
	check_time:
	
	mov ah, 2Ch 
	int 21h
	
	cmp dl, time_aux
	je check_time
	
	mov time_aux, dl
	
	call clear_screen
	call move_ball
	call draw_ball
	call move_tables
	call draw_table
	
	call finish_game
	call display_score
	call game_over
	
	jmp check_time
	

mov ah, 4Ch
int 21h

main endp
setCursor MACRO x, y
	pusha

	mov ah, 02h				 ; interrupt setting cursor position
    mov bh, 0  				 ; page number
    mov dh, y    ; row
    mov dl, x	 ; column
    int 10h

	popa
ENDM

game_over proc near
	
	cmp PLAYER1_SCORE,5
	je display_p1_end
	jne check_p2
	
	display_p1_end:
	call clear_screen

	setCursor 33, 10
	mov dx, offset PLAYER_1_WINS
	mov ah, 9
	int 21h
	
	setCursor 25, 11
	mov dx, offset PRESS_INFO
	mov ah, 9
	int 21h
	
	setCursor 27, 12
	mov dx, offset PRESS_INFO_2
	mov ah, 9
	int 21h
	
	mov ah, 0
	int 16h
	cmp al, 32
	int 16h
	
	mov PLAYER1_SCORE, 0
	mov PLAYER2_SCORE, 0
		
	
	check_p2:
	cmp PLAYER2_SCORE, 5
	je display_p2_end
	jne skip_p
	
	display_p2_end:
	
	call clear_screen

	setCursor 33, 10
	mov dx, offset PLAYER_2_WINS
	mov ah, 9
	int 21h
	
	setCursor 25, 11
	mov dx, offset PRESS_INFO
	mov ah, 9
	int 21h	
	
	setCursor 27, 12
	mov dx, offset PRESS_INFO_2
	mov ah, 9
	int 21h
	
	mov ah, 0
	int 16h
	cmp al, 32
	int 16h
	
	mov PLAYER1_SCORE, 0
	mov PLAYER2_SCORE, 0
		

skip_p:
ret
game_over endp

finish_game proc near
	;quitting the game process
	
	mov ah, 1; constantly checking if button was pressed
	int 16h
	jz go_on
	
	cmp al,  'q'
	jne go_on
	;if q was pressed, we clear the screen and quit the game
	call clear_screen
	mov ah, 4Ch
	int 21h
go_on:
ret
finish_game endp


draw_table proc near

	mov dl, table_left_x		; dl for setting column
	mov dh, table_left_y      ; dh for setting row

	
	draw_table_left_horizontal:
	mov ah, 2h     ; cursor position function
	mov bh, 0     
	int 10h        ; set cursor position

	mov ah, 9h     ; function for sign displaying
	mov al, '!'    ; the sign to display
	mov bl, 7      ; displaying attribute - 7(default)
	int 10h        ; interrupt so the sign will be displayed
	
	inc dl
	mov al, dl
	sub al, table_left_x
	cmp al, table_width
	jng draw_table_left_horizontal
	
	mov dl, table_left_x
	inc dh
	
	mov al, dh
	sub al, table_left_y
	cmp al, table_height
	jng draw_table_left_horizontal



	mov dl, table_right_x		; col 
	mov dh, table_right_y      ; row  

	
	draw_table_right_horizontal:
	mov ah, 2h     
	mov bh, 0       
	int 10h         

	mov ah, 9h      
	mov al, '!'     
	mov bl, 7      
	int 10h        
	
	inc dl
	mov al, dl
	sub al, table_right_x
	cmp al, table_width
	jng draw_table_right_horizontal
	
	mov dl, table_right_x
	inc dh
	
	mov al, dh
	sub al, table_right_y
	cmp al, table_height
	jng draw_table_right_horizontal
	
	ret

draw_table endp


	

move_tables proc near

	;check if the key was pressed
	mov ah, 1
	int 16h
	jz check_rightTable_movement
	
	mov ah, 0
	int 16h
	

	;moving the table if the certain key was pressed
	cmp al, 77h ; "w"
	je move_leftTable_up
	cmp al, 57h ;"W"
	je move_leftTable_up
	
	cmp al, 73h ; "s"
	je move_leftTable_down
	cmp al, 53h ;"S"
	je move_leftTable_down
	jmp check_rightTable_movement
	
	move_leftTable_up:
		mov al, table_speed
		sub table_left_y, al
	
		;moving the table back to the screen if it would hit the top/bottom
		mov al, screen_bounds
		cmp table_left_y, al
		jl fix_leftTable_TOPposition
		jmp check_rightTable_movement
		
		fix_leftTable_TOPposition:
			mov table_left_y, al
			jmp check_rightTable_movement
	
	move_leftTable_down:
		mov al, table_speed
		add table_left_y, al
		mov al, screen_height
		sub al, screen_bounds
		sub al, table_height
		cmp table_left_y, al
		jg fix_leftTable_BOTTOMposition
		jmp check_rightTable_movement
		
		fix_leftTable_BOTTOMposition:
			mov table_left_y, al
			jmp check_rightTable_movement
		
	
	;same thing as above but for the right table
	check_rightTable_movement:
	
	cmp al, 69h ; "i"
	je move_rightTable_up
	cmp al, 49h ;"I"
	je move_rightTable_up
	
	cmp al, 6bh ; "k"
	je move_rightTable_down
	cmp al, 4bh ;"K"
	je move_rightTable_down
	jmp exit_table_movemant
	
	move_rightTable_up:
		mov al, table_speed
		sub table_right_y, al
	
		mov al, screen_bounds
		cmp table_right_y, al
		jl fix_rightTable_TOPposition
		jmp exit_table_movemant
		
		fix_rightTable_TOPposition:
			mov table_right_y, al
			jmp exit_table_movemant
	
	move_rightTable_down:
		mov al, table_speed
		add table_right_y, al
		mov al, screen_height
		sub al, screen_bounds
		sub al, table_height
		cmp table_right_y, al
		jg fix_rightTable_BOTTOMposition
		jmp exit_table_movemant
		
		fix_rightTable_BOTTOMposition:
			mov table_right_y, al
			jmp exit_table_movemant
			
	exit_table_movemant:

ret
move_tables endp



draw_ball proc near

	mov dh, ball_y
	mov dl, ball_x
	mov ah, 2h
	mov bh, 0
	int 10h
	mov ah, 9h
	mov al, "*"
	mov bl, 7
	mov cx, 1
	int 10h
	
	ret
draw_ball endp

move_ball proc near

	;checking the wall collision

	mov al, ball_speed_x
	add ball_x, al
	
	cmp ball_x, 79
	jg reset_position1
	cmp ball_x, 0
	jl reset_position2
	 jmp move_ball_vertically
	
	reset_position1:
		call reset_ball_position1
		ret
		
	reset_position2:
		call reset_ball_position2
		ret
	
	move_ball_vertically:
	
	mov al, ball_speed_y
	add ball_y, al
	
	cmp ball_y, 24
	jg NEG_SPEED_Y
	cmp ball_y, 0
	jl NEG_SPEED_Y
	
	;checking if ball is colliding with a  left table
	
	mov al, ball_x
	add al, 1
	cmp al, table_right_x
	jng check_collision_with_left_table
	
	mov al, table_right_x
	add al, table_width
	cmp ball_x, al
	jnl check_collision_with_left_table
	
	mov al, ball_y
	add al, 1
	cmp al, table_right_y
	jng check_collision_with_left_table
	
	mov al, table_right_y
	add al, table_height
	cmp ball_y, al
	jnl check_collision_with_left_table
	
	
	jmp NEG_SPEED_x
	check_collision_with_left_table:
	
	;checking if ball is colliding with a  right table
		mov al, ball_x
	add al, 1
	cmp al, table_left_x
	jng exit_collision_check
	
	mov al, table_left_x
	add al, table_width
	cmp ball_x, al
	jnl exit_collision_check
	
	mov al, ball_y
	add al, 1
	cmp al, table_left_y
	jng exit_collision_check
	
	mov al, table_left_y
	add al, table_height
	cmp ball_y, al
	jnl exit_collision_check
	
	neg ball_speed_x
	ret
	
	jmp NEG_SPEED_x
	
	NEG_SPEED_Y:
		neg ball_speed_y
		ret
		
	NEG_SPEED_x:
	neg ball_speed_x
	ret
		
	exit_collision_check:
	ret
	
		
move_ball endp

;setting the ball in the middle
reset_ball_position1 proc near
	inc PLAYER1_SCORE

	mov al, ball_original_x
	mov ball_x, al
	
	mov al, ball_original_y
	mov ball_y, al
	
	ret
	reset_ball_position1 endp
	
	reset_ball_position2 proc near
	inc PLAYER2_SCORE

	mov al, ball_original_x
	mov ball_x, al
	
	mov al, ball_original_y
	mov ball_y, al
	
	ret
	reset_ball_position2 endp

;screen clearing process
clear_screen proc near

	mov ah, 0h    
	mov al, 3h     
	int 10h        
	
	ret
clear_screen endp





display_integer proc
    ; player score ascii conversion
    mov CX, 10    ; the divider for decimal conversion
    mov BX, 0     ; num counter
	mov placeholder, dx
	
    ; przypadek dla zera
    test AX, AX
    jnz NOT_ZERO

    mov DL, '0'
    mov AH, 02h
    int 21h

    ret

	NOT_ZERO:
		CONVERT_LOOP:
			xor DX, DX          ; clear previous remainder
			div CX              ; divide AX by 10, quotient in AX, remainder in DX
			push DX             ; push remainder onto stack
			inc BX              ; increase digit count
			mov DIGIT_DISPLAY_NOE, 1 ;  variable for "increasing the number of digits to display"
			test AX, AX         ; check if quotient is zero
			jnz CONVERT_LOOP    ; if not, continue

		DISPLAY_LOOP:
			pop DX              ; pop value from stack
			add DL, '0'         ; convert to ASCII

			 ; display the number
			mov AH, 02h
			int 21h

			 ; move cursor to the next position
			mov AH, 02h
			mov BH, 0
			mov DH, 0
			mov DL, byte ptr [placeholder] 				  ; 66 is the first number of the result
			add DL, DIGIT_DISPLAY_NOE ; move by the number of digits
			int 10h

			inc DIGIT_DISPLAY_NOE
			dec BX              ; decrease number of digits to display
			jnz DISPLAY_LOOP    ; if more digits, continue


    ret
	
display_integer endp

display_score proc
     ; set cursor position where the text should be displayed
	setCursor 36, 0

	 ; print the string 'SCORE'
	mov dx, offset SCORE_STRING
	mov ah, 9
	int 21h

	 ; set cursor position where the score (number) should be displayed
	setCursor 44,0

	 ; function to display the player's 1 score
	mov DX, 44
	mov AX, PLAYER1_SCORE
	call display_integer

	setCursor 32,0

	 ; function to display the player's 2 score
	mov DX, 32
	mov AX, PLAYER2_SCORE
	call display_integer
	
    ret
display_score endp


play_sound proc
	; something music related
	in al,61h
	or al,3
	out 61h,al
	; something music related up

	mov bx, 0200h	; Standard A tone, 440 Hz
	mov dx, 0012h	; high part of number 1234dd
	mov ax, 34DDh	; low part of number 1234dd
	div bx		; ax = value to send

	pushf		; preserve flags
	push ax		; preserve value to send
	cli		; disable interrupts
	mov al,0b6h
	out 43h,al	; send command

	pop ax
	out 42h,al	; send first half of counter
	mov al,ah
	out 42h,al	; send second half of counter
	popf		; restore interrupt flag state

	mov cx,0h
	mov dx,0F000h
	mov ah,86h
	int 15h


	in al,61h
	and al,not 3		; clear bits 0 and 1
	out 61h, al
	ret
ret
play_sound endp



end main
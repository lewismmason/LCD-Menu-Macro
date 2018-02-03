;testing code
$MODLP51
org 0x0000
    ljmp mainprogram
$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros
$LIST

;example setup for the macro
B0 equ P2.5
B1 equ P4.5	
; These ’EQU’ must match the wiring between the microcontroller and LCD
LCD_RS equ P1.1
LCD_RW equ P1.2
LCD_E  equ P1.3
LCD_D4 equ P3.2
LCD_D5 equ P3.3
LCD_D6 equ P3.4
LCD_D7 equ P3.5	

CSEG
CLEARLINE:  	db 		'                ', 0		;used to clear the LCD

;the first level of the test menu: an example of how to initialize the seperate strings.
S1: 	    	db 		'hello<        hi', 0
S2: 		db 		'hello        >hi', 0
S3: 		db 		'hello         hi', 0
S4: 		db 		'check<      test', 0
S5: 		db 		'check      >test', 0
S6: 		db 		'check       test', 0
;the second level of the test menu
SS1: 	    db 		'yo1<        dawg', 0
SS2: 		db 		'yo1        >dawg', 0
SS3: 		db 		'yo1         dawg', 0
SS4: 		db 		'test<        mel', 0
SS5: 		db 		'test        >mel', 0
SS6: 		db 		'test         mel', 0


;------------------------------------------------------------------------------------------------------------------------------------------------------------;
;This Macro was made by Lewis Mason, January 2018		
;LCD_Menu_Branch creates another branch segment of a in depth
;menu.
;NOTE: THIS FUNCTION REQUIRES THE USE OF FUNCTIONS FROM LCD4_bit
;
;Requirements:
;		2 pushbuttons
;		Either 3 function-name parameters, or less than 3 and the
;		the remainder named "NULL_FUNCTION"
;
;Menu_Branch(cursortoggle,cursorselect,Func1,FUNC2ENABLE,Func2,FUNC3ENABLE,Func3,FUNC4ENABLE,Func4, UP<,UP>,UP_,DN<,DN>,DN_,Blankstr)				
;		NAME   		NAME	NAME    1/0	 NAME     1/0	    NAME   1/0	      NAME   ----all string names------------
;		%0		 %1	%2	  %3	 %4       %5	     %6     %7 	       %8   %9  %1  %11	%12  %13 %14 %15
;
;cursortoggle		- The input that toggles the current cursor position
;cursorselect		- The input that selects the current position of the cursor
;Func1			- The first function that can be called when cursor is in the correct position
;FUNC2ENABLE		- 1 enables the second function, 0 disables
;Func2			- The second function that can be called when cursor is in the correct position
;FUNC3ENABLE		- 1 enables the third function, 0 disables
;Func3			- The third function that can be called when cursor is in the correct position
;FUNC4ENABLE		- 1 enables the fourth function, 0 disables
;Func4			- The fourth function that can be called when cursor is in the correct position
;UP<			- The string that shows first function selected
;UP>			- The string that shows second function selected
;UP_			- The string that clears cursor from function 1/2 
;DN<			- The string that shows third function selected
;DN>			- The string that shows fourth function selected
;DN_			- The string that clears cursor from function 3/4
;Blankstr		- A blank 16 space long string used to clear the screen.
;------------------------------------------------------------------------------------------------------------------------------------------------------------;
Menu_Branch mac
	push ar0
	push ar1
	push ar2
	push ar3
	push ar4
	push ar5
	push ar6
	push ar7
	push acc
	mov R0, #0x00			;R0 is the exit flag, reset the exit flag
	mov R1, #0x00			;R1 is the Cursor position register
	mov R2, #0x00			;R2 is the number of functions flag
	
	
	;We put the information about the functions in R2,bits 0,1,2 correspond to funcs 2,3,4
	Menu_Setup_Function_Register(%3,%5,%7)	;sets up the function flag register
	;R2 is the function flag register
	
	Menu_Display_LCD_Cursor(%9,%10,%11,%12,%13,%14,%15)	;display on LCD

;The loop that will happen over and over in each level of the menu
Menu_Loop%M:
	;First, Check to see if the user wants to change the cursors location
	jb %0, Menu_Skip_Cursor_Changetp%M ; if the '%0' button is not pressed skip
	Wait_Milli_Seconds(#50)		; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb %0, Menu_Skip_Cursor_Changetp%M ; if the '%0' button is not pressed skip
	jnb %0, $					; Wait for button release.
	;The below code is used to get around the max jb jump distance
	sjmp Menu_Change_Cursor%M
Menu_Skip_Cursor_Changetp%M:
	ljmp Menu_Skip_Cursor_Change%M

Menu_Change_Cursor%M:	
	INC R1				;increment the cursors position
	lcall Menu_Change_Cursor_Func	;verify cursors position.
	Menu_Display_LCD_Cursor(%9,%10,%11,%12,%13,%14,%15)	;display on LCD
	
Menu_Skip_Cursor_Change%M:
	;Check if the user wanted to exit the level of the menu
	mov a, R0
	cjne a, #0x01, Menu_Stay%M 	;if the flag is not 1, continue program, otherwise reset flag and return
	mov R0, #0x00
	ljmp Menu_Exit_Level%M
	
Menu_Stay%M:	
	;now the code that operates when the "select" button is pressed
	jb %1, Menu_Skip_Select_Changetp%M ; if the '%1' button is not pressed skip
	Wait_Milli_Seconds(#50)		; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb %1, Menu_Skip_Select_Changetp%M ; if the '%1' button is not pressed skip
	jnb %1, $					; Wait for button release
	;The below code is used to get around the max jb jump distance 
	sjmp Menu_Select_Change%M
Menu_Skip_Select_Changetp%M:
	ljmp Menu_Skip_Select_Change%M	;the button was not pressed.
	
Menu_Select_Change%M:
	Menu_Select_Functions(%2,%4,%6,%8)

	
	;after selecting the function and exiting it, reset the cursor position and the screen
	mov R1, #0x00
	Menu_Display_LCD_Cursor(%9,%10,%11,%12,%13,%14,%15)

Menu_Skip_Select_Change%M:
	ljmp Menu_Loop%M

Menu_Exit_Level%M:
	pop acc
	pop  ar7
	pop  ar6
	pop  ar5
	pop  ar4
	pop  ar3
	pop  ar2
	pop  ar1
	pop  ar0
endmac	

;-----------------------------------------USEFUL MACS-----------------------------------------

;------------------------------;
;Menu_Select_Functions
;------------------------------;
Menu_Select_Functions mac
	
;We simply compare what number is in the cursor and enter that function
	mov a, R1
	cjne a, #0x00, Menu_Not_Func_One_Select%M
	;if here, then the cursor is on the above position
	lcall %0
	ljmp Menu_Done_Func%M
			
Menu_Not_Func_One_Select%M:
		mov a, R1
	cjne a, #0x01, Menu_Not_Func_Two_Select%M
	;if here, then the cursor is on the above position
	lcall %1
	ljmp Menu_Done_Func%M
			
Menu_Not_Func_Two_Select%M:
	mov a, R1
	cjne a, #0x02, Menu_Not_Func_Three_Select%M
	;if here, then the cursor is on the above position
	lcall %2
	ljmp Menu_Done_Func%M
			
Menu_Not_Func_Three_Select%M:
	mov a, R1
	cjne a, #0x03, Menu_Not_Func_Four_Select%M
	;if here, then the cursor is on the above position
	lcall %3
	ljmp Menu_Done_Func%M
			
Menu_Not_Func_Four_Select%M:

Menu_Done_Func%M:
	endmac

;------------------------------;
;Menu_Setup_Function_Register
;------------------------------;
Menu_Setup_Function_Register mac
	mov a, #0x00			;clear a
	;jnb %0, Menu_No_Func_2
	mov a, #0x0%0
	cjne a, #0x01, Menu_No_Func_2%M
	inc R2
	;orl a, #00000001B		;put a 1 in bit 0 to indicate FUNC 2 activated
Menu_No_Func_2%M:
	;jnb %1, Menu_No_Func_3
	mov a, #0x0%1
	cjne a, #0x01, Menu_No_Func_3%M
	inc R2
	;orl a, #00000010B		;put a 1 in bit 1 to indicate FUNC 3 activated
Menu_No_Func_3%M:
	;jnb %2, Menu_No_Func_4
	mov a, #0x0%2
	cjne a, #0x01, Menu_No_Func_4%M
	inc R2
	;orl a, #00000100B		;put a 1 in bit 2 to indicate FUNC 4 activated
Menu_No_Func_4%M:
				;put the result into R2, this indicates the #of funcs
	endmac
	
;------------------------------;
;Menu_Display_LCD_Cursor
;------------------------------;
Menu_Display_LCD_Cursor mac
	;display the screen after it has switched. This stays inside the 
	;change cursor part so it only updates when pressed, not constantly.
	mov a, R1
	cjne a, #0x00, Menu_Display_not_ONE%M
	Menu_Display_Cursor(%0,%5,%6)			
	ljmp Menu_Done_Display_Cursor_Change%M	
		
Menu_Display_not_ONE%M:
		mov a, R1
		cjne a, #0x01, Menu_Display_not_TWO%M
		Menu_Display_Cursor(%1,%5,%6)
		ljmp Menu_Done_Display_Cursor_Change%M
				
Menu_Display_not_TWO%M:
		mov a, R1
		cjne a, #0x02, Menu_Display_not_THREE%M
		Menu_Display_Cursor(%2,%3,%6)
		ljmp Menu_Done_Display_Cursor_Change%M
				
Menu_Display_not_THREE%M:
		mov a, R1
		cjne a, #0x03, Menu_Display_not_FOUR%M
		Menu_Display_Cursor(%2,%4,%6)	
		ljmp Menu_Done_Display_Cursor_Change%M
				
Menu_Display_not_FOUR%M:
Menu_Done_Display_Cursor_Change%M:
	endmac
	
;------------------------------;
;Menu_Display_Cursor
;------------------------------;
Menu_Display_Cursor mac
	set_Cursor(1,1)
	Send_Constant_String(#%2)
	set_Cursor(1,1)
	Send_Constant_String(#%0)		;display top half, cursor >
	;check if its required to display bottom half
	mov a, R2
	anl a, #0x02
	cjne a, #0x02, Skip_Displaying_Bottom%M
	set_Cursor(2,1)
	Send_Constant_String(#%2)
	set_Cursor(2,1)
	Send_Constant_String(#%1)		;display bottom half no cursor
Skip_Displaying_Bottom%M:
	endmac
;-----------------------------------------USEFUL FUNCTIONS-------------------------------------

;------------------------------;
;Menu_Null
;------------------------------;
;The necessary function that gets used when using less than 4 branches (A filler)
Menu_Null:
	ret
;------------------------------;
;Menu_Back
;------------------------------;
;The necessary function that gets used when wanted to return from a level of the menu
Menu_Back:
	mov R0, #0x01	;sets the flag for the program to know to exit
	ret

;------------------------------;
;Menu_Change_Cursor_Func
;------------------------------;
;The necessary function used to change the cursors position
Menu_Change_Cursor_Func:
	;first case to check is there are no other funcs enabled
	mov a, R2		
	cjne a, #00000000B, Menu_NOTONE_Func_E		;see if 1 function
	mov R1, #0x00							;reset cursor position
	ljmp Menu_Display_LCD
			
Menu_NOTONE_Func_E:
	;next check if there are 1 funcs enabled
	mov a, R2
	cjne a, #0x01, Menu_NOTTWO_FUNC_E		;see if 2 functions
	;now change the cursors position
	mov a, R1
	cjne a, #0x02, Menu_Display_LCD	;if not = to uper bound, continue
	mov R1, #0x00							;was = to upper bound, reset
	ljmp Menu_Display_LCD
			
Menu_NOTTWO_FUNC_E:
	;next check if there are 1 funcs enabled
	mov a, R2
	cjne a, #0x02, Menu_NOTTHREE_FUNC_E		;see if 3 functions
	;now change the cursors position
	mov a, R1
	cjne a, #0x03, Menu_Display_LCD	;if not = to uper bound, continue
	mov R1, #0x00							;was = to upper bound, reset
	ljmp Menu_Display_LCD
			
Menu_NOTTHREE_FUNC_E:
	;next check if there are 1 funcs enabled
	mov a, R2
	cjne a, #0x03, Menu_NOTFOUR_FUNC_E		;see if 4 functions
	;now change the cursors position
	mov a, R1
	cjne a, #0x04, Menu_Display_LCD	;if not = to uper bound, continue
	mov R1, #0x00							;was = to upper bound, reset
	ljmp Menu_Display_LCD
			
Menu_NOTFOUR_FUNC_E:
	ljmp Menu_Display_LCD
		
Menu_Display_LCD:
	ret

	
mainprogram:
  lcall LCD_4BIT
	;testing the application.
	Menu_Branch(B0,B1,Menu_Null,1,Menu_Null,1,Menu_Null,1,Menu_Null,S1,S2,S3,S4,S5,S6,CLEARLINE)
end 






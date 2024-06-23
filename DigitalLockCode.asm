; LED light
   
#include P16F84A.INC
   
__config _XT_OSC & _WDT_OFF & _PWRTE_ON
   
; PIC always start executing at address 0
   
Display_Digit EQU H'23' ; Stores the segments of the LED that will be lit up
 
 ; Stores the 5 digits entered using the keypad
Input1 EQU H'24'
Input2 EQU H'25'
Input3 EQU H'26'
Input4 EQU H'27'
Input5 EQU H'28'
 
 ; Stores the which digit was last entered
Input_Counter EQU H'29'
 
 ; Stores the previous input sequence for the purpose of verifying the new usercode before setting it
Stored_Input1 EQU H'2A'
Stored_Input2 EQU H'2B'
Stored_Input3 EQU H'2C'
Stored_Input4 EQU H'2D'
Stored_Input5 EQU H'2E'
 
 ; Is h'01' when a button is being pressed on the keypad
Pressed_Flag EQU H'2F'
 
 ; Stores the unchanging mastercode used to set the usercode
Mastercode1 EQU H'31'
Mastercode2 EQU H'32'
Mastercode3 EQU H'33'
Mastercode4 EQU H'34'
Mastercode5 EQU H'35'
 
 ; Is h'01' when the usercode or mastercode has been entered respectively
Unlocked_Flag EQU H'36'
Master_Flag EQU H'37'

 ; Increments after each password attempt
Attempt_Counter EQU H'38'
 
 ; Used for delays
DELAY_COUNT1 EQU H'39'
DELAY_COUNT2 EQU H'3A'
DELAY_COUNT3 EQU H'3B'
DELAY_COUNT4 EQU H'3C'
 
 ; Used to track the number of delays
Delay_Loop_Counter EQU H'3D'
 
 ; Is h'01' when the inputs and stored inputs match or don't match respectively
Success_Flag EQU H'3E'
Failure_Flag EQU H'3F'
Confirm_Input EQU H'40'
 

ORG h'0' ; defines were the code is to be loaded in memory
   
bsf STATUS,5 ;select bank 1
movlw b'00000000' ;set up all PORTB as outputs
movwf TRISB

movlw b'00001110'
movwf TRISA ;
bcf STATUS,5 ; select bank 0
 
movlw b'00100000'
movwf Stored_Input1
movlw b'00000001'
movwf Stored_Input2
movlw b'00000010'
movwf Stored_Input3
movlw b'00000011'
movwf Stored_Input4
movlw b'00000100'
movwf Stored_Input5
 
call check_usercode_in_eeprom
 
movlw b'01000000'
movwf Mastercode1
movlw b'00000100'
movwf Mastercode2
movlw b'00000011'
movwf Mastercode3
movlw b'00000010'
movwf Mastercode4
movlw b'00000001'
movwf Mastercode5

; ////////////////////////////////////////////////////////////////////////////////
; STATES
; ////////////////////////////////////////////////////////////////////////////////
 ; Locked state
start
    movlw b'00000000'
    movwf Input_Counter
    movlw b'11100011'
    movwf Display_Digit
    movlw b'00000000'
    movwf Unlocked_Flag
    movlw b'00000000'
    movwf Master_Flag
    movlw b'00000001'
    movwf Attempt_Counter
start_loop
    call check_input
    btfsc Input_Counter, 4
    call check_unlock
    btfsc Unlocked_Flag, 0
    goto unlocked
    btfsc Master_Flag, 0
    goto set_new_usercode
    btfsc Attempt_Counter, 2
    goto locked_out
    
    call display_led
    goto start_loop

unlocked
    movlw b'00000000'
    movwf Delay_Loop_Counter
unlocked_loop
    movlw b'01000011'
    movwf Display_Digit
    call display_led
    call delay_250ms
    
    movlw b'11111111'
    movwf Display_Digit
    call display_led
    call delay_250ms
    
    movlw b'01000011'
    movwf Display_Digit
    call display_led
    call delay_250ms
    
    movlw b'11111111'
    movwf Display_Digit
    call display_led
    call delay_250ms
    
    btfsc Delay_Loop_Counter, 2
    goto start
    
    incf Delay_Loop_Counter
    
    goto unlocked_loop
    
set_new_usercode
    movlw b'00000000'
    movwf Input_Counter
    movlw b'10000111'
    movwf Display_Digit
    movlw b'00000000'
    movwf Success_Flag
    movlw b'00000000'
    movwf Failure_Flag
    movlw b'00000000'
    movwf Confirm_Input
set_new_usercode_loop
    call check_input
    
    btfsc Input_Counter, 4
    call validate_usercode
    
    btfsc Success_Flag, 0
    goto set_state
    btfsc Failure_Flag, 0
    goto not_state
    
    call display_led
    goto set_new_usercode_loop
    
set_state
    movlw b'10001001'
    movwf Display_Digit
    call display_led
    call song1
    
    movlw b'10100001'
    movwf Display_Digit
    call display_led
    call song1
    
    movlw b'10100011'
    movwf Display_Digit
    call display_led
    call song1
    goto start
    
not_state
    movlw b'10010111'
    movwf Display_Digit
    call display_led
    call song2
    
    movlw b'10000111'
    movwf Display_Digit
    call display_led
    call song2
    
    movlw b'10100011'
    movwf Display_Digit
    call display_led
    call song2
    goto start
    
locked_out
    movlw b'11100011'
    movwf Display_Digit
    call display_led
    call delay_20s
    goto start
    
; ////////////////////////////////////////////////////////////////////////////////
; FUNCTION BLOCK
; ////////////////////////////////////////////////////////////////////////////////
display_led
    movfw Display_Digit
    movwf PORTB
    
    btfsc Pressed_Flag, 0
    call use_speaker
    
    call short_delay
    return
    
use_speaker
    movlw b'00000001'
    movwf PORTA
    
    btfsc Input_Counter, 0
    call delay_pitch_A
    btfsc Input_Counter, 1
    call delay_pitch_B
    btfsc Input_Counter, 2
    call delay_pitch_C
    btfsc Input_Counter, 3
    call delay_pitch_D
    
    call short_delay
    
    movlw b'00000000'
    movwf PORTA
    return
    
song2
    movlw b'00000100'
    movwf Delay_Loop_Counter
    call tone
song1
    movlw b'00000001'
    movwf Delay_Loop_Counter
    call tone
    movlw b'00000010'
    movwf Delay_Loop_Counter
    call tone
    return
    
; Delays =========================================================================
short_delay
    movlw H'04'
    movwf DELAY_COUNT1
    movlw H'02'
    movwf DELAY_COUNT2
    goto delay_loop
    
delay_pitch_A
    movlw H'04'
    movwf DELAY_COUNT1
    movlw H'08'
    movwf DELAY_COUNT2
    goto delay_loop
    
delay_pitch_B
    movlw H'04'
    movwf DELAY_COUNT1
    movlw H'06'
    movwf DELAY_COUNT2
    goto delay_loop
    
delay_pitch_C
    movlw H'04'
    movwf DELAY_COUNT1
    movlw H'04'
    movwf DELAY_COUNT2
    goto delay_loop
    
delay_pitch_D
    movlw H'04'
    movwf DELAY_COUNT1
    movlw H'02'
    movwf DELAY_COUNT2
    goto delay_loop
    
delay_loop
    decfsz DELAY_COUNT1,F
    goto delay_loop
    decfsz DELAY_COUNT2,F
    goto delay_loop
    return
    
delay_250ms
    movlw H'FF'
    movwf DELAY_COUNT1
    movlw H'30'
    movwf DELAY_COUNT2
    movlw H'02'
    movwf DELAY_COUNT3
delay_250ms_loop
    decfsz DELAY_COUNT1,F
    goto delay_250ms_loop
    decfsz DELAY_COUNT2,F
    goto delay_250ms_loop
    decfsz DELAY_COUNT3,F
    goto delay_250ms_loop
    return
    
delay_1s
    call delay_250ms
    call delay_250ms
    call delay_250ms
    call delay_250ms
    return
    
delay_5s
    call delay_1s
    call delay_1s
    call delay_1s
    call delay_1s
    call delay_1s
    return
    
delay_20s
    call delay_5s
    call delay_5s
    call delay_5s
    call delay_5s
    return
    
tone
    movlw H'02'
    movwf DELAY_COUNT3
    movlw H'02'
    movwf DELAY_COUNT4
tone_loop
    movlw b'00000001' ; Turns the speaker pin on
    movwf PORTA
    btfsc Delay_Loop_Counter, 0
    call delay_pitch_D
    btfsc Delay_Loop_Counter, 1
    call delay_pitch_C
    btfsc Delay_Loop_Counter, 2
    call delay_pitch_B
    movlw b'00000000' ; Turns the speaker off
    movwf PORTA
    decfsz DELAY_COUNT3,F
    goto tone_loop
    decfsz DELAY_COUNT4,F
    goto tone_loop
    return
; End of Delays ==================================================================
    
check_usercode_in_eeprom
    movlw H'01'
    movwf EEADR
    bsf STATUS, RP0
    btfsc EECON1, RD
    call wait_eeprom
    bsf EECON1, RD
    bcf STATUS, RP0
    movf EEDATA, W
    
    xorwf Stored_Input1, W
    btfss STATUS, Z
    call store_usercode_in_eeprom
    return
    
    
store_usercode_in_eeprom
    movlw H'01'
    movwf EEADR
    movfw Stored_Input1
    movwf EEDATA
    call write_eeprom
    
    movlw H'02'
    movwf EEADR
    movfw Stored_Input2
    movwf EEDATA
    call write_eeprom
    
    movlw H'03'
    movwf EEADR
    movfw Stored_Input3
    movwf EEDATA
    call write_eeprom
    
    movlw H'04'
    movwf EEADR
    movfw Stored_Input4
    movwf EEDATA
    call write_eeprom
    
    movlw H'05'
    movwf EEADR
    movfw Stored_Input5
    movwf EEDATA
    call write_eeprom
    return
    
write_eeprom
    bsf STATUS, RP0
    bsf EECON1, WREN
    bcf INTCON, GIE 
    movlw H'55'
    movwf EECON2
    movlw H'AA'
    movwf EECON2
    bsf EECON1, WR
    btfsc EECON1, WR 
    goto $-1
    bcf EECON1, WREN
    bsf INTCON, GIE 
    bcf STATUS, RP0
    return
    
; ////////////////////////////////////////////////////////////////////////////////
; INPUT BLOCK
; ////////////////////////////////////////////////////////////////////////////////
check_input    
    movlw b'00000010'
    movwf PORTB
    btfsc PORTA, 1
    goto set_one
    btfsc PORTA, 2
    goto set_two
    btfsc PORTA, 3
    goto set_three
    
    movlw b'00000100'
    movwf PORTB
    btfsc PORTA, 1
    goto set_four
    btfsc PORTA, 2
    goto set_five
    btfsc PORTA, 3
    goto set_six
    
    movlw b'00001000'
    movwf PORTB
    btfsc PORTA, 1
    goto set_seven
    btfsc PORTA, 2
    goto set_eight
    btfsc PORTA, 3
    goto set_nine
    
    movlw b'00010000'
    movwf PORTB
    btfsc PORTA, 1
    goto set_star
    btfsc PORTA, 2
    goto set_zero
    btfsc PORTA, 3
    goto set_hash
    
    btfss Pressed_Flag, 0
    call set_locked
    
    movlw b'00000000'
    movwf Pressed_Flag
    return
    
set_one
    btfsc Pressed_Flag, 0
    return
    movlw b'00000001'
    movwf Pressed_Flag
    
    btfsc Input_Counter, 0
    goto set_input2_to_one
    btfsc Input_Counter, 1
    goto set_input3_to_one
    btfsc Input_Counter, 2
    goto set_input4_to_one
    btfsc Input_Counter, 3
    goto set_input5_to_one
    return
    
set_input2_to_one
    movlw b'00000001'
    movwf Input2
    movlw b'00000010'
    movwf Input_Counter
    movlw b'10111011'
    movwf Display_Digit
    return
    
set_input3_to_one
    movlw b'00000001'
    movwf Input3
    movlw b'00000100'
    movwf Input_Counter
    movlw b'10111001'
    movwf Display_Digit
    return
    
set_input4_to_one
    movlw b'00000001'
    movwf Input4
    movlw b'00001000'
    movwf Input_Counter
    movlw b'00111001'
    movwf Display_Digit
    return
    
set_input5_to_one
    movlw b'00000001'
    movwf Input5
    movlw b'00010000'
    movwf Input_Counter
    movlw b'00101001'
    movwf Display_Digit
    return
    

set_two
    btfsc Pressed_Flag, 0
    return
    movlw b'00000001'
    movwf Pressed_Flag
    
    btfsc Input_Counter, 0
    goto set_input2_to_two
    btfsc Input_Counter, 1
    goto set_input3_to_two
    btfsc Input_Counter, 2
    goto set_input4_to_two
    btfsc Input_Counter, 3
    goto set_input5_to_two
    return
    
set_input2_to_two
    movlw b'00000010'
    movwf Input2
    movlw b'00000010'
    movwf Input_Counter
    movlw b'10111011'
    movwf Display_Digit
    return
    
set_input3_to_two
    movlw b'00000010'
    movwf Input3
    movlw b'00000100'
    movwf Input_Counter
    movlw b'10111001'
    movwf Display_Digit
    return
    
set_input4_to_two
    movlw b'00000010'
    movwf Input4
    movlw b'00001000'
    movwf Input_Counter
    movlw b'00111001'
    movwf Display_Digit
    return
    
set_input5_to_two
    movlw b'00000010'
    movwf Input5
    movlw b'00010000'
    movwf Input_Counter
    movlw b'00101001'
    movwf Display_Digit
    return
    
     
set_three
    btfsc Pressed_Flag, 0
    return
    movlw b'00000001'
    movwf Pressed_Flag
    
    btfsc Input_Counter, 0
    goto set_input2_to_three
    btfsc Input_Counter, 1
    goto set_input3_to_three
    btfsc Input_Counter, 2
    goto set_input4_to_three
    btfsc Input_Counter, 3
    goto set_input5_to_three
    return
    
set_input2_to_three
    movlw b'00000011'
    movwf Input2
    movlw b'00000010'
    movwf Input_Counter
    movlw b'10111011'
    movwf Display_Digit
    return
    
set_input3_to_three
    movlw b'00000011'
    movwf Input3
    movlw b'00000100'
    movwf Input_Counter
    movlw b'10111001'
    movwf Display_Digit
    return
    
set_input4_to_three
    movlw b'00000011'
    movwf Input4
    movlw b'00001000'
    movwf Input_Counter
    movlw b'00111001'
    movwf Display_Digit
    return
    
set_input5_to_three
    movlw b'00000011'
    movwf Input5
    movlw b'00010000'
    movwf Input_Counter
    movlw b'00101001'
    movwf Display_Digit
    return
    
    
set_four
    btfsc Pressed_Flag, 0
    return
    movlw b'00000001'
    movwf Pressed_Flag
    
    btfsc Input_Counter, 0
    goto set_input2_to_four
    btfsc Input_Counter, 1
    goto set_input3_to_four
    btfsc Input_Counter, 2
    goto set_input4_to_four
    btfsc Input_Counter, 3
    goto set_input5_to_four
    return
    
set_input2_to_four
    movlw b'00000100'
    movwf Input2
    movlw b'00000010'
    movwf Input_Counter
    movlw b'10111011'
    movwf Display_Digit
    return
    
set_input3_to_four
    movlw b'00000100'
    movwf Input3
    movlw b'00000100'
    movwf Input_Counter
    movlw b'10111001'
    movwf Display_Digit
    return
    
set_input4_to_four
    movlw b'00000100'
    movwf Input4
    movlw b'00001000'
    movwf Input_Counter
    movlw b'00111001'
    movwf Display_Digit
    return
    
set_input5_to_four
    movlw b'00000100'
    movwf Input5
    movlw b'00010000'
    movwf Input_Counter
    movlw b'00101001'
    movwf Display_Digit
    return
    
    
set_five
    btfsc Pressed_Flag, 0
    return
    movlw b'00000001'
    movwf Pressed_Flag
    
    btfsc Input_Counter, 0
    goto set_input2_to_five
    btfsc Input_Counter, 1
    goto set_input3_to_five
    btfsc Input_Counter, 2
    goto set_input4_to_five
    btfsc Input_Counter, 3
    goto set_input5_to_five
    return
    
set_input2_to_five
    movlw b'00000101'
    movwf Input2
    movlw b'00000010'
    movwf Input_Counter
    movlw b'10111011'
    movwf Display_Digit
    return
    
set_input3_to_five
    movlw b'00000101'
    movwf Input3
    movlw b'00000100'
    movwf Input_Counter
    movlw b'10111001'
    movwf Display_Digit
    return
    
set_input4_to_five
    movlw b'00000101'
    movwf Input4
    movlw b'00001000'
    movwf Input_Counter
    movlw b'00111001'
    movwf Display_Digit
    return
    
set_input5_to_five
    movlw b'00000101'
    movwf Input5
    movlw b'00010000'
    movwf Input_Counter
    movlw b'00101001'
    movwf Display_Digit
    return
    
    
set_six
    btfsc Pressed_Flag, 0
    return
    movlw b'00000001'
    movwf Pressed_Flag
    btfsc Input_Counter, 0
    goto set_input2_to_six
    btfsc Input_Counter, 1
    goto set_input3_to_six
    btfsc Input_Counter, 2
    goto set_input4_to_six
    btfsc Input_Counter, 3
    goto set_input5_to_six
    return
    
set_input2_to_six
    movlw b'00000110'
    movwf Input2
    movlw b'00000010'
    movwf Input_Counter
    movlw b'10111011'
    movwf Display_Digit
    return
    
set_input3_to_six
    movlw b'00000110'
    movwf Input3
    movlw b'00000100'
    movwf Input_Counter
    movlw b'10111001'
    movwf Display_Digit
    return
    
set_input4_to_six
    movlw b'00000110'
    movwf Input4
    movlw b'00001000'
    movwf Input_Counter
    movlw b'00111001'
    movwf Display_Digit
    return
    
set_input5_to_six
    movlw b'00000110'
    movwf Input5
    movlw b'00010000'
    movwf Input_Counter
    movlw b'00101001'
    movwf Display_Digit
    return
    
    
set_seven
    btfsc Pressed_Flag, 0
    return
    movlw b'00000001'
    movwf Pressed_Flag
    
    btfsc Input_Counter, 0
    goto set_input2_to_seven
    btfsc Input_Counter, 1
    goto set_input3_to_seven
    btfsc Input_Counter, 2
    goto set_input4_to_seven
    btfsc Input_Counter, 3
    goto set_input5_to_seven
    return
    
set_input2_to_seven
    movlw b'00000111'
    movwf Input2
    movlw b'00000010'
    movwf Input_Counter
    movlw b'10111011'
    movwf Display_Digit
    return
    
set_input3_to_seven
    movlw b'00000111'
    movwf Input3
    movlw b'00000100'
    movwf Input_Counter
    movlw b'10111001'
    movwf Display_Digit
    return
    
set_input4_to_seven
    movlw b'00000111'
    movwf Input4
    movlw b'00001000'
    movwf Input_Counter
    movlw b'00111001'
    movwf Display_Digit
    return
    
set_input5_to_seven
    movlw b'00000111'
    movwf Input5
    movlw b'00010000'
    movwf Input_Counter
    movlw b'00101001'
    movwf Display_Digit
    return
    
    
set_eight
    btfsc Pressed_Flag, 0
    return
    movlw b'00000001'
    movwf Pressed_Flag
    
    btfsc Input_Counter, 0
    goto set_input2_to_eight
    btfsc Input_Counter, 1
    goto set_input3_to_eight
    btfsc Input_Counter, 2
    goto set_input4_to_eight
    btfsc Input_Counter, 3
    goto set_input5_to_eight
    return
    
set_input2_to_eight
    movlw b'00001000'
    movwf Input2
    movlw b'00000010'
    movwf Input_Counter
    movlw b'10111011'
    movwf Display_Digit
    return
    
set_input3_to_eight
    movlw b'00001000'
    movwf Input3
    movlw b'00000100'
    movwf Input_Counter
    movlw b'10111001'
    movwf Display_Digit
    return
    
set_input4_to_eight
    movlw b'00001000'
    movwf Input4
    movlw b'00001000'
    movwf Input_Counter
    movlw b'00111001'
    movwf Display_Digit
    return
    
set_input5_to_eight
    movlw b'00001000'
    movwf Input5
    movlw b'00010000'
    movwf Input_Counter
    movlw b'00101001'
    movwf Display_Digit
    return
    
     
set_nine
    btfsc Pressed_Flag, 0
    return
    movlw b'00000001'
    movwf Pressed_Flag
    
    btfsc Input_Counter, 0
    goto set_input2_to_nine
    btfsc Input_Counter, 1
    goto set_input3_to_nine
    btfsc Input_Counter, 2
    goto set_input4_to_nine
    btfsc Input_Counter, 3
    goto set_input5_to_nine
    return
    
set_input2_to_nine
    movlw b'00001001'
    movwf Input2
    movlw b'00000010'
    movwf Input_Counter
    movlw b'10111011'
    movwf Display_Digit
    return
    
set_input3_to_nine
    movlw b'00001001'
    movwf Input3
    movlw b'00000100'
    movwf Input_Counter
    movlw b'10111001'
    movwf Display_Digit
    return
    
set_input4_to_nine
    movlw b'00001001'
    movwf Input4
    movlw b'00001000'
    movwf Input_Counter
    movlw b'00111001'
    movwf Display_Digit
    return
    
set_input5_to_nine
    movlw b'00001001'
    movwf Input5
    movlw b'00010000'
    movwf Input_Counter
    movlw b'00101001'
    movwf Display_Digit
    return
    
    
set_star
    btfsc Pressed_Flag, 0
    return
    movlw b'00000001'
    movwf Pressed_Flag
    
    btfsc Input_Counter, 0
    goto set_input2_to_star
    btfsc Input_Counter, 1
    goto set_input3_to_star
    btfsc Input_Counter, 2
    goto set_input4_to_star
    btfsc Input_Counter, 3
    goto set_input5_to_star
    
    goto set_input1_to_star
    return
    
set_input2_to_star
    movlw b'01000000'
    movwf Input2
    movlw b'00000010'
    movwf Input_Counter
    movlw b'10111011'
    movwf Display_Digit
    return
    
set_input3_to_star
    movlw b'01000000'
    movwf Input3
    movlw b'00000100'
    movwf Input_Counter
    movlw b'10111001'
    movwf Display_Digit
    return
    
set_input4_to_star
    movlw b'01000000'
    movwf Input4
    movlw b'00001000'
    movwf Input_Counter
    movlw b'00111001'
    movwf Display_Digit
    return
    
set_input5_to_star
    movlw b'01000000'
    movwf Input5
    movlw b'00010000'
    movwf Input_Counter
    movlw b'00101001'
    movwf Display_Digit
    return
    
set_input1_to_star
    movlw b'01000000'
    movwf Input1
    movlw b'00000001'
    movwf Input_Counter
    movlw b'10111111'
    movwf Display_Digit
    return
    
    
set_zero
    btfsc Pressed_Flag, 0
    return
    movlw b'00000001'
    movwf Pressed_Flag
    
    btfsc Input_Counter, 0
    goto set_input2_to_zero
    btfsc Input_Counter, 1
    goto set_input3_to_zero
    btfsc Input_Counter, 2
    goto set_input4_to_zero
    btfsc Input_Counter, 3
    goto set_input5_to_zero
    return
    
set_input2_to_zero
    movlw b'00000000'
    movwf Input2
    movlw b'00000010'
    movwf Input_Counter
    movlw b'10111011'
    movwf Display_Digit
    return
    
set_input3_to_zero
    movlw b'00000000'
    movwf Input3
    movlw b'00000100'
    movwf Input_Counter
    movlw b'10111001'
    movwf Display_Digit
    return
    
set_input4_to_zero
    movlw b'00000000'
    movwf Input4
    movlw b'00001000'
    movwf Input_Counter
    movlw b'00111001'
    movwf Display_Digit
    return
    
set_input5_to_zero
    movlw b'00000000'
    movwf Input5
    movlw b'00010000'
    movwf Input_Counter
    movlw b'00101001'
    movwf Display_Digit
    return
    
    
set_hash
    btfsc Pressed_Flag, 0
    return
    movlw b'00000001'
    movwf Pressed_Flag
    
    btfsc Input_Counter, 0
    goto set_input2_to_hash
    btfsc Input_Counter, 1
    goto set_input3_to_hash
    btfsc Input_Counter, 2
    goto set_input4_to_hash
    btfsc Input_Counter, 3
    goto set_input5_to_hash
    
    goto set_input1_to_hash
    return
    
set_input2_to_hash
    movlw b'00100000'
    movwf Input2
    movlw b'00000010'
    movwf Input_Counter
    movlw b'10111011'
    movwf Display_Digit
    return
    
set_input3_to_hash
    movlw b'00100000'
    movwf Input3
    movlw b'00000100'
    movwf Input_Counter
    movlw b'10111001'
    movwf Display_Digit
    return
    
set_input4_to_hash
    movlw b'00100000'
    movwf Input4
    movlw b'00001000'
    movwf Input_Counter
    movlw b'00111001'
    movwf Display_Digit
    return
    
set_input5_to_hash
    movlw b'00100000'
    movwf Input5
    movlw b'00010000'
    movwf Input_Counter
    movlw b'00101001'
    movwf Display_Digit
    return
    
set_input1_to_hash
    movlw b'00100000'
    movwf Input1
    movlw b'00000001'
    movwf Input_Counter
    movlw b'10111111'
    movwf Display_Digit
    return
    
set_locked
    movlw b'11100011'
    movwf Display_Digit
    return
    
; ////////////////////////////////////////////////////////////////////////////////
; Check Entered Code
; ////////////////////////////////////////////////////////////////////////////////
check_unlock
    incf Attempt_Counter
    
    movlw H'01'
    movwf EEADR
    bsf STATUS, RP0
    btfsc EECON1, RD
    call wait_eeprom
    bsf EECON1, RD
    bcf STATUS, RP0
    movf EEDATA, W
    xorwf Input1, W
    btfss STATUS, Z
    goto check_mastercode
    
    movlw H'02'
    movwf EEADR
    bsf STATUS, RP0
    btfsc EECON1, RD
    call wait_eeprom
    bsf EECON1, RD
    bcf STATUS, RP0
    movf EEDATA, W
    xorwf Input2, W
    btfss STATUS, Z
    goto reset_inputs
    
    movlw H'03'
    movwf EEADR
    bsf STATUS, RP0
    btfsc EECON1, RD
    call wait_eeprom
    bsf EECON1, RD
    bcf STATUS, RP0
    movf EEDATA, W
    xorwf Input3, W
    btfss STATUS, Z
    goto reset_inputs
    
    movlw H'04'
    movwf EEADR
    bsf STATUS, RP0
    btfsc EECON1, RD
    call wait_eeprom
    bsf EECON1, RD
    bcf STATUS, RP0
    movf EEDATA, W
    xorwf Input4, W
    btfss STATUS, Z
    goto reset_inputs
    
    movlw H'05'
    movwf EEADR
    bsf STATUS, RP0
    btfsc EECON1, RD
    call wait_eeprom
    bsf EECON1, RD
    bcf STATUS, RP0
    movf EEDATA, W
    xorwf Input5, W
    btfss STATUS, Z
    goto reset_inputs
    
    movlw b'0000001'
    movwf Attempt_Counter
    movlw b'00000001'
    movwf Unlocked_Flag
    goto reset_inputs
    
wait_eeprom
    btfsc EECON1, RD
    goto $-1
    return
    
check_mastercode
    movfw Input1
    xorwf Mastercode1, W
    btfss STATUS, Z
    goto reset_inputs
    
    movfw Input2
    xorwf Mastercode2, W
    btfss STATUS, Z
    goto reset_inputs
    
    movfw Input3
    xorwf Mastercode3, W
    btfss STATUS, Z
    goto reset_inputs
    
    movfw Input4
    xorwf Mastercode4, W
    btfss STATUS, Z
    goto reset_inputs
    
    movfw Input5
    xorwf Mastercode5, W
    btfss STATUS, Z
    goto reset_inputs
    
    movlw b'00000001'
    movwf Attempt_Counter
    movlw b'00000001'
    movwf Master_Flag
    goto reset_inputs
    
    
reset_inputs
    movlw b'00000000'
    movwf Input_Counter
    
    movlw b'00000000'
    movwf Input1
    movlw b'00000000'
    movwf Input2
    movlw b'00000000'
    movwf Input3
    movlw b'00000000'
    movwf Input4
    movlw b'00000000'
    movwf Input5
    return
    
validate_usercode
    movlw b'00000000'
    movwf Input_Counter
    
    btfsc Confirm_Input, 0
    goto compare_inputs
    
    ; If Input1 is not # return
    btfss Input1, 5
    return
    ; Save input into second
    movfw Input1
    movwf Stored_Input1
    movfw Input2
    movwf Stored_Input2
    movfw Input3
    movwf Stored_Input3
    movfw Input4
    movwf Stored_Input4
    movfw Input5
    movwf Stored_Input5
    
    movlw b'00000001'
    movwf Confirm_Input
    return
    
compare_inputs
    movfw Input1
    xorwf Stored_Input1, W
    btfss STATUS, Z
    goto failed_to_set
    
    movfw Input2
    xorwf Stored_Input2, W
    btfss STATUS, Z
    goto failed_to_set
    
    movfw Input3
    xorwf Stored_Input3, W
    btfss STATUS, Z
    goto failed_to_set
    
    movfw Input4
    xorwf Stored_Input4, W
    btfss STATUS, Z
    goto failed_to_set
    
    movfw Input5
    xorwf Stored_Input5, W
    btfss STATUS, Z
    goto failed_to_set
    
    movlw b'00000001'
    movwf Success_Flag
    call store_usercode_in_eeprom
    return
    
failed_to_set
    movlw b'00000001'
    movwf Failure_Flag
    return
end
    

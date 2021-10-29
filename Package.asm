
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h
   
   
   
.data
;Variables for File Handling
MaxLength db 255
ActualLength db ?
szFileName db 255 dup(?) 
handle dw ?

;Variables for Reading Data
buffer db 100 dup(?), '$'

;Variables for Drawing Pixels
X_OFFSET dw ?
Y_OFFSET dw ?
X dw ?
Y dw ? 
IMG_WIDTH dw ?      
IMG_HEIGHT dw ?       

;Variables for Printing Messages
OpenFileErrorMessage db 'No such file.', '$'
ReadErrorMessage db 'Cannot read from file.', '$'
InputMessage db 'Enter the name of the file: ', '$'
    
    

.code
;Printing the prompt message
;The message at the location pointed by DX is printed
mov AH, 09h
lea DX, InputMessage
int 21h

;Receiving the name of the file
;The file name is stored at MaxLength
mov AH, 0Ah
lea DX, MaxLength
int 21h

;ActualLength automatically has the length of the file name
mov AL, ActualLength
xor AH, AH
;Moving the length of the file name to SI
mov SI, AX
;Adding 0 to the end of the file name
;ASCIZ is just like ASCII, but each string
;is followed by a zero byte
;(The Z in ASCIZ stands for zero)
mov szFileName[si], 0

;Open the file
mov AH, 3Dh
;AL == 0 implies read mode
xor Al, AL
lea DX, szFileName
int 21h
jc openError

;Storing the handle of the file in a variable
mov handle, AX    

;Reading from the file
mov AH, 3Fh  

;DX will store the address of the buffer,
;in which the read data will be stored
lea DX, buffer

;Loading the handle of the file in BX
mov BX, handle

;We need to find the first occurence of
;0Dh(cret) in order to find the width of
;the image.
;CX specifies the number of bytes to read
;We arbitrarily give CX a value of 100,
;assuming the first 0Dh will occur in
;that range 
mov CX, 101  
int 21h

;SI will now point to the starting
;of the buffer
mov SI, DX

;Finding the number of characters(IMG_WIDTH)
;before the first 0Dh
mov AX, 0
findLen:
    ;Checking if the character at SI, is equal to cret
    cmp [SI], 0Dh 
    ;If equal, assign AX to IMG_WIDTH and IMG_HEIGHT
    je found
    ;If not equal, increase the value of AX
    inc AX
    inc SI
    ;Looping statement
    jmp findLen
    
    found:  
        ;When found, AX will have the width of the image
        mov IMG_WIDTH, AX
        mov IMG_HEIGHT, AX
        jmp next
        
next:
    ;Closing the file       
    mov AH, 3Eh
    mov BX, handle
    int 21h

;Opening the file(As read and write this time)    
mov AH, 3Dh
;Al == 2 implies opening the file for reading and writing
mov AL, 2
lea DX, szFileName
int 21h
;In case an error occurs in opening the file,
;CF will be set
jc openError
;Storing the handle of the file in AX
mov handle, AX    

;Setting the video mode
mov AH, 00h
;AL == 13h implies graphical mode
mov AL, 13h
int 10h

;Calculating the X_OFFSET for printing the
;the image in the middle of the screen
mov AX, 140h
sar AX, 1
mov CX, AX
mov AX, IMG_WIDTH
sar AX, 1
sub CX, AX
mov X_OFFSET, CX
;Setting X to X_OFFSET
mov AX, X_OFFSET
mov X, AX 

;Calculating the Y_OFFSET for printing the
;the image in the middle of the screen
mov AX, 0C8h
sar AX, 1 
mov CX, AX
mov AX, IMG_HEIGHT
sar AX, 1 
sub CX, AX
mov Y_OFFSET, CX
;Setting Y to Y_OFFSET
mov AX, Y_OFFSET
mov Y, AX

;DRAWING THE IMAGE
repeat:
    ;Reading from the file
    mov AH, 3Fh 
    ;buffer is the location where the read data is stored
    lea DX, buffer
    ;CX specifies the amount of data to read
    ;We read the image row by row    
    mov CX, IMG_WIDTH
    ;+2 for reading the carriage return and new line characters
    add CX, 2      
    int 21h
    
    ;If there is an error in reading the file,
    ;the CF will be set
    jc readError
    
    ;AX has the length of the data read from the file
    ;We subtract 2 from it in order to omit the
    ;cret and new line characters
    sub AX, 2
    mov SI, AX
    ;The below statement adds '$' to the position
    ;after the last pixel in that row
    mov buffer[SI], '$'
    
    ;BP points to the first element of the buffer
    mov BP, DX 
    compare:
        ;Comparing the character in the buffer with 1
        ;(1 is 31h in ASCII)           
        cmp [BP], 31h
        ;If the character is 1:
        je black
        ;Else we check if the character is '$'
        cmp [BP], 24h
        ;If equal, it implies we have completed
        ;printing the row
        je cret
        ;If none of the above conditions are true
        ;we make the colour of the pixel white
        mov AL, 1111b
        jmp draw
    
    black:
        ;If the character is 1,
        ;we make the pixel black
        mov AL, 0000b
        
    draw:
        ;CX points to the X-coordinate of the pixel to be drawn   
        mov CX, X
        ;DX points to the Y-coordinate of the pixel to be drawn
        mov DX, Y
        ;Changing the colour of a single pixel
        mov AH, 0Ch
        int 10h
        
        ;Moving to the next pixel in that row
        inc CX
        ;Updating the X-coordinate variable
        mov X, CX
        ;Updating BP to point to the next
        ;character in the buffer
        inc BP
        ;Unconditional jump statement to repeat this process(Looping) 
        ;Loop stops when '$' is read
        jmp compare         
    
    ;The entire row has been printed            
    cret:
        ;Resetting X-coordinate by the X_OFFSET
        mov CX, X_OFFSET
        mov X, CX   
        
        ;Updating the Y-coordinate value 
        mov DX, Y
        inc DX
        mov Y, DX
        ;Checking if all the rows have been printed
        ;(Checking if DX == IMG_HEIGHT)
        mov CX, Y_OFFSET
        ;Adding IMG_HEIGHT, CX will point
        ;to the Y-coordinate of the first pixel
        ;in the last row
        add CX, IMG_HEIGHT
        sub CX, 1
        cmp DX, CX
        ;As long as we have not printed the
        ;last row, we keep looping
        jle repeat
    
;Now we have successfully printed the image,
;and we can stop the program 
jmp stop

;Label that handles the error
;in opening the file    
openError:
    ;Printing the error message
    mov AH, 09h
    lea DX, OpenFileErrorMessage
    int 21h
    jmp stop

;Label that handles the error
;in reading the file    
readError: 
    ;Printing the error message
    mov AH, 09h
    lea DX, ReadErrorMessage
    int 21h
    jmp stop
    
stop:    
    ret
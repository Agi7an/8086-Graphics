
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h

.data
X dw -1
Y dw 0  
color db 1111b
msg db "Thank You$"
newline db 0Ah, 0Dh, 24h
welcome db "THESE ARE THE BASIC INSTRUCTIONS$ : "
info1 db "w-white$"
info2 db "b-blue$"
info3 db "r-red$"
info4 db "g-green$"
info5 db "y-yellow$"
info6 db "e-eraser$"
info7 db "R-lightRed$"   
info8 db "B-lightBlue$"
info9 db "G-lightGreen$"

.code
mov AX, @data
mov DS, AX 
             

             
;Initialize graphics
mov AH, 00
mov AL, 13h
int 10h     

;Displaying the instructions on the screen
mov ah,09h
lea dx,welcome
int 21h

mov ah,09h
lea dx,newline
int 21h  

mov ah,09h
lea dx,info1
int 21h      

mov ah,09h
lea dx,newline
int 21h  

mov ah,09h
lea dx,info2
int 21h     

mov ah,09h
lea dx,newline
int 21h  

mov ah,09h
lea dx,info3
int 21h   

mov ah,09h
lea dx,newline
int 21h  

mov ah,09h
lea dx,info4
int 21h

mov ah,09h
lea dx,newline
int 21h  

mov ah,09h
lea dx,info5
int 21h 

mov ah,09h
lea dx,newline
int 21h  

mov ah,09h
lea dx,info6
int 21h     

mov ah,09h
lea dx,newline
int 21h  

mov ah,09h
lea dx,info7
int 21h     

mov ah,09h
lea dx,newline
int 21h  

mov ah,09h
lea dx,info8
int 21h     

mov ah,09h
lea dx,newline
int 21h  

mov ah,09h
lea dx,info9
int 21h

CHECK_MOUSE_BUTTON: 
;Getting the mouse position
;and the status of its buttons
mov AX, 3
int 33h

;In graphical 320X200 mode 
;the value of CX is doubled
shr CX, 1
;Checking if the left mouse button is pressed
cmp BX, 1
jne XOR_CURSOR
;Assigning green colour
mov AL, color
jmp DRAW_PIXEL

XOR_CURSOR:
    cmp X, -1
    je NOT_REQUIRED
    push CX
    push DX
    mov CX, X
    mov DX, Y
    ;Getting the colour of the pixel at (X, Y)
    mov AH, 0Dh
    int 10h
    ;Inverting the colour(Complement Colour)
    xor AL, 1111b
    ;Drawing the pixel
    mov AH, 0Ch
    int 10h
    pop DX
    pop CX 

NOT_REQUIRED:
    ;Getting the colour of the pixel at (CX, DX)
    mov AH, 0Dh
    int 10h
    ;Inverting the colour(Complement Colour)
    xor AL, 1111b
    mov X, CX
    mov Y, DX
    
DRAW_PIXEL:
    ;Drawing the pixel
    mov AH, 0Ch
    int 10h 
    
CHECK_ESC_KEY:
    ;Get character from keyboard buffer(if any)
    ;or set ZF = 1
    mov DL, 255
    mov AH, 6
    int 21h
    cmp AL, 114         
    je color_red 
    cmp AL,103
    je color_green
    cmp AL,119
    je color_white
    cmp AL,101
    je color_black
    cmp AL,98
    je color_blue 
    cmp AL,66
    je color_LightBlue   
    cmp AL,82
    je color_LightRed   
    cmp AL,71
    je color_LightGreen  
    cmp AL,121
    je color_yellow    
    jmp esc
      
    color_red:
        mov color,0100b 
        jmp esc
    color_green: 
        mov color,0010b
        jmp esc 
    color_white:
        mov color,1111b
        jmp esc
    color_black:
        mov color,0000b
        jmp esc
    color_blue:
        mov color,0001b
        jmp esc   
    color_LightBlue:
        mov color,1001b
        jmp esc    
    color_LightRed:
        mov color,1100b
        jmp esc 
    color_LightGreen:
        mov color,1010b
        jmp esc
    color_yellow:
        mov color,1110b
        jmp esc
    esc:
        ;Check if the key pressed is 'ESC'
        cmp AL, 27
        ;Space
        ;cmp AL, 32
        ;If ESC has not been pressed, loop
        jne CHECK_MOUSE_BUTTON

STOP:
    ;Get cursor position and size
    mov AX, 3
    int 10h
    
    ;Set text-mode
    mov AH, 1
    ;Value of CH indicates the cursor start line
    mov CH, 0
    ;CL decides the cursor properties(Shape, Blinking)
    mov CL, 8
    int 10h
    
    ;Printing the message
    mov DX, offset msg
    mov AH, 9
    int 21h
    
    ;Get keystroke from keyboard
    mov AH, 0
    int 16h
    ;The program terminates at this point
    ;when any key is pressed
ret
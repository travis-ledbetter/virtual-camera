
.386

.MODEL FLAT

ExitProcess PROTO NEAR32 stdcall, dwExitCode:DWORD

INCLUDE debug.h
INCLUDE sqrt.h

.STACK  4096           

.DATA                   

; declare these first so that they are all on WORD boundaries

eye_x       WORD    ?
eye_y       WORD    ?
eye_z       WORD    ?

eyexprompt      BYTE    "Enter the x-coordinate of the camera eyepoint:  ", 0
eyeyprompt      BYTE    "Enter the y-coordinate of the camera eyepoint:  ", 0
eyezprompt      BYTE    "Enter the z-coordinate of the camera eyepoint:  ", 0


display         		BYTE    50 DUP (?), 0 ; the text to display in (x, y, z) format
output_u        	BYTE    "u: ", 0
output_v        	BYTE    "v: ", 0
output_n        	BYTE    "n: ", 0

eol             		BYTE    CR, LF, 0     ; end of line

v_x           WORD    ?  ; variables to hold v coordinates
v_y           WORD    ?
v_z           WORD    ?


nPoint_x     WORD    ?  ; variables to hold n coordinates
nPoint_y     WORD    ?
nPoint_z     WORD    ?

nDotn        WORD    ?  ; result of (n.n)
v_upDotn     WORD    ?  ; result of (v_up.n)

tempV_x1     WORD    ?  ; variables to hold values for v = -(v_up.n)n + (n.n)v_up calculation
tempV_y1     WORD    ?
tempV_z1     WORD    ?
tempV_x2     WORD    ?
tempV_y2     WORD    ?
tempV_z2     WORD    ?

look_x       WORD    ?  ; variables to hold the "at point" input
look_y       WORD    ?
look_z       WORD    ?

lookXPrompt      BYTE    "Enter the x-coordinate of the camera look at point:  ", 0
lookYPrompt      BYTE    "Enter the y-coordinate of the camera look at point:  ", 0
lookZPrompt      BYTE    "Enter the z-coordinate of the camera look at point:  ", 0

up_x             WORD    ?  ; variables to hold the "v_up" input
up_y             WORD    ?
up_z             WORD    ?

u_x              WORD    ?  ; variables to hold the coordinates for the u result
u_y              WORD    ?
u_z              WORD    ?

len_u            WORD    ?  ; variables to hold the lengths of u,v,n
len_v            WORD    ?
len_n            WORD    ?

upXPrompt        BYTE    "Enter the x-coordinate of the camera up direction:  ", 0
upYPrompt        BYTE    "Enter the y-coordinate of the camera up direction:  ", 0
upZPrompt        BYTE    "Enter the z-coordinate of the camera up direction:  ", 0



.CODE          

getCoord    MACRO   prompt, var
        inputW  prompt, var
        mov     var, ax         ; store the result in memory
        outputW ax
        ENDM


get_and_display MACRO prompt1, prompt2, prompt3, prompt4, x1, x2, x3
        getCoord prompt1, x1  ; call getCoord macro for "eye point"
        getCoord prompt2, x2  ; call getCoord macro for "at point"
        getCoord prompt3, x3	; call getCoord macro for "v_up"				  
        printPoint prompt4, x1, x2, x3  
        ENDM                            


printPoint  MACRO   point, xvar, yvar, zvar
        output  eol
        mov     point, "("
        itoa    point + 1, xvar  ; convert xvar to digits and place after the "("
        mov     point + 7, ","   ; insert the comma after the digits for xvar
        itoa    point + 8, yvar  ; convert yvar to digits and place after the ","
        mov     point + 14, ","  ; insert the comma after the digits for yvar 
        itoa    point + 15, zvar ; convert zvar to digits and place after the ","
       	mov     point + 21, ")"  ; insert the ")" after the digits for zvar
	output  point
	output  eol 
			   
        ENDM

printNormPoint  MACRO   point, xvar, yvar, zvar, len
        itoa point + 5, len   ; insert the current length value at the proper position
        itoa point + 16, len
        itoa point + 27, len
        output eol
        mov     point + 0, "("

        itoa    point + 1, xvar  
        mov     point + 7, "/"  
        mov     point + 11, ","
        itoa    point + 12, yvar
	mov     point + 18, "/"
	mov     point + 22, ","
	itoa    point + 23, zvar
	mov     point + 29, "/"
	mov     point + 33, ")"			   
        output  point
        output  eol
        ENDM

; computes the dot product of two vectors
dot_product MACRO   x1, y1, z1, x2, y2, z2
        mov ax, x1
        mov bx, x2
        imul bx        ; x1 * x2 is in ax  (actually dx::ax, high order bits dropped)
        mov cx, ax     ; the accumulating result will be in cx
	mov ax, y1 
	mov bx, y2 
	imul bx        ; y1 * y2 is in ax 
	add cx, ax     ; accumulating result in cx
	mov ax, z1 
	mov bx, z2 
	imul bx        ; z1 * z2 is in ax
	add cx, ax     ; accumulating result in ax
        ENDM

; computes the cross product of two vectors
cross_product MACRO   x1, y1, z1, x2, y2, z2, x3, y3, z3
        mov ax, y1
        mov bx, z2
        mul bx         ; result in dx::ax
        mov cx, ax

        mov ax, z1     
        mov bx, y2
        mul bx         ; result in dx::ax
        neg ax

        add ax, cx
        mov x3, ax
			   
	mov ax, z1     ; move z1 into ax
	mov bx, x2     ; move x2 into bx 
	mul bx         ; multiple ax * bx, result in ax 
	mov cx, ax     ; move result to cx
			   
	mov ax, x1     ; move x1 into ax 
	mov bx, z2     ; move z2 into bx 
	mul bx         ; multiple ax * bx, result in ax 
	neg ax         ; negate the result in ax
			   
	add ax, cx     ; combine cx and ax
	mov y3, ax     ; move result from ax into y3 
		   
	mov ax, x1     ; repeat steps from above...
	mov bx, y2
	mul bx
	mov cx, ax
		   
	mov ax, y1
	mov bx, x2
	mul bx
        neg ax
		   
	add ax, cx
	mov z3, ax

        ENDM

; performs point-point subtraction to obtain a vector
point_subtract MACRO x1, y1, z1, x2, y2, z2, vx, vy, vz
        mov ax, x1
        mov bx, x2
        sub ax, bx
        mov vx, ax
				  
        mov ax, y1  ; move y1 into ax
        mov bx, y2  ; move y2 into bx 
        sub ax, bx  ; subtract y2 from y1, result in ax
        mov vy, ax  ; move result from ax into vy

        mov ax, z1  ; repeat steps from above...
        mov bx, z2 
        sub ax, bx 
        mov vz, ax 

        ENDM

; performs point-vector addition to obtain a new point
point_vector_add MACRO x, y, z, vx, vy, vz, xn, yn, zn
        mov ax, x
        mov bx, vx
        add ax, bx
        mov xn, ax

        mov ax, y   ; move y-coordinate into ax
        mov bx, vy  ; move vy-coordinate into bx 
        add ax, bx  ; combine ax and bx, result in ax
        mov yn, ax  ; move result from ax into yn

        mov ax, z   ; repeat steps from above...
        mov bx, vz
        add ax, bx
        mov zn, ax 

	ENDM
			  
				  
vector_length	MACRO x, y, z
        dot_product x, y, z, x, y, z   ; perform dot_product on x, y, and z values, results stored in cx
        sqrt cx                        ; get the square root of value in cx, result is stored in ax 
				   
        ENDM

_start:

        get_and_display eyexprompt, eyeyprompt, eyezprompt, display, eye_x, eye_y, eye_z        ; macros to get and display input
        get_and_display lookXPrompt, lookYPrompt, lookZPrompt, display, look_x, look_y, look_z
	get_and_display upXPrompt, upYPrompt, upZPrompt, display, up_x, up_y, up_z

        point_subtract eye_x, eye_y, eye_z, look_x, look_y, look_z, nPoint_x, nPoint_y, nPoint_z ; perform subtraction "E-A" to get n 
		  
	dot_product nPoint_x, nPoint_y, nPoint_z, nPoint_x, nPoint_y, nPoint_z     ; perform n.n dot product, results in cx
	mov nDotn, cx                                                              ; move results from cx to nDotn
		  
	dot_product up_x, up_y, up_z, nPoint_x, nPoint_y, nPoint_z                 ; perform v_up.n dot product, results in cx 
	mov v_upDotn, cx                                                           ; move results from cx to v_upDotn

        mov ax, nPoint_x   ; move nPoint_x to ax 
	mov bx, v_upDotn   ; move v_upDotn to bx 
        imul bx            ; perform signed integer multiplication of ax * bx
        neg ax 		     ; negate the result in ax 
        mov tempV_x1, ax   ; move result from ax to tempV_x1
		  
	mov ax, nPoint_y   ; repeat steps from above...
	imul bx 
	neg ax 
	mov tempV_y1, ax 
	  
	mov ax, nPoint_z
	imul bx 
	neg ax
	mov tempV_z1, ax
	  
	mov ax, up_x       ; move up_x to ax 
	mov bx, nDotn      ; move nDotn to bx
	mul bx             ; perform unsigned multiplication of ax * bx
	mov tempV_x2, ax   ; move result from ax to tempV_x2
	  
	mov ax, up_y       ; repeat steps from above...
	mul bx
	mov tempV_y2, ax
	  
	mov ax, up_z
	mul bx
	mov tempV_z2, ax
	  
	point_vector_add tempV_x1, tempV_y1, tempV_z1, tempV_x2, tempV_y2, tempV_z2, v_x, v_y, v_z  ; perform vector addition to calculate v
	  
	cross_product v_x, v_y, v_z, nPoint_x, nPoint_y, nPoint_z, u_x, u_y, u_z                    ; perform cross product of v x n
	  
	vector_length u_x, u_y, u_z   ; get the length of the u vector, result stored in ax
	mov len_u, ax                 ; move result from ax to len_u 
	  
	vector_length v_x, v_y, v_z   ; repeat steps from above...
	mov len_v, ax
	  
	vector_length nPoint_x, nPoint_y, nPoint_z
	mov len_n, ax

        output eol
        output eol
		  
        output output_u
        printNormPoint display, u_x, u_y, u_z, len_u
	  
	output output_v                                              ; output the character 'v'
	printNormPoint display, v_x, v_y, v_z, len_v                 ; call printNormPoint macro to output new vector v
	  
	output output_n                                              ; output the character 'n'
	printNormPoint display, nPoint_x, nPoint_y, nPoint_z, len_n  ; call printNormPoint macro to output new vector n 

        INVOKE  ExitProcess, 0  ; exit with return code 0

PUBLIC _start                   ; make entry point public

END                             ; end of source code

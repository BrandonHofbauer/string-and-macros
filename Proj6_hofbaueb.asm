TITLE Project 6     (Proj6_hofbaueb.asm)

; Author: Brandon Hofbauer
; Last Modified: 8/11/2022
; OSU email address: hofbaueb@oregonstate.edu
; Course number/section:   CS271 Section 401
; Project Number:  6              Due Date: 8/12/2022
; Description: A program that implements macros to process strings using string primitives. ASCII digits are converted to their numeric SDWORD representation for storing, and then converted back out to ASCII for display
;              to the user. Data validation will ensure that the numbers are appropriate signed integers. Does not validate numbers that are too large.

INCLUDE Irvine32.inc

; Name: mGetString
; Description: Displays an associated prompt before reading a string from the user. 
; Pre:
; Post: user input array (buffer_32) and the buffer_count will be modified. 
; Receives: prompt = message to user, buffer = empty array to hold user input, buffer_count = length of the empty array being passed through, byteCount = variable to hold the length of the input
; Returns: buffer = user input string, byteCount = length of inputted string
mGetString MACRO prompt, buffer, buffer_count, byteCount
	push	EDX
	push	ECX
	push	EAX

	mov		EDX, prompt
	call	WriteString

	mov		EDX, buffer
	mov		ECX, buffer_count
	call	ReadString ; eax has number of characters, necessary?
	mov		byteCount, EAX

	pop		EAX
	pop		ECX
	pop		EDX
ENDM

; Name: mDisplayString
; Description: Displays a string, given an address offset
; Pre: input must be an address offset
; Post: 
; Receives: string = OFFSET of string array
; Returns:
mDisplayString MACRO string
	push	EDX

	mov		EDX, string
	call	WriteString

	pop		EDX
ENDM

ARRAYLENGTH = 10

.data

intro			BYTE	"Low-level I/O procedures - String primitives and macros, by Brandon Hofbauer",13,10,13,10,0
intro_1			BYTE	"Please provide 10 signed decimal integers.",0
intro_2			BYTE	"Each number needs to be able to fit in a 32 bit register",13,10,0
intro_3			BYTE	"Once complete, I will display a list of those numbers, their sum, and their average value.",13,10,0

input			BYTE	"Please enter a signed number: ",0
error			BYTE	"Either the number was too big, or it wasn't a signed decimal integer",13,10,"Try again: ",0

buffer_32		BYTE	11 DUP(?)
byteCount		DWORD	?

array			SDWORD	ARRAYLENGTH DUP(?)			; hold ASCII to SDWORD int
out_str			BYTE	?,0							; single SDWORD conversion to ASCII for printing

out_message		BYTE	"Here is what you entered: ",13,10,0
sum_mes			BYTE	"The sum of your numbers is: ",0
average_mes		BYTE	"The average (truncated) is: ",0
sum				SDWORD	1 DUP(?)
average			SDWORD	1 DUP(?)

exunt			BYTE	"Goodbye, CS 271",0

.code
main PROC
	push	OFFSET intro
	push	OFFSET intro_1
	push	OFFSET intro_2
	push	OFFSET intro_3
	CALL	introduction

	mov		ECX, ARRAYLENGTH						; loop will attempt to collect the specified number of 'integers'
	mov		EDI, OFFSET array
 _get_value:
	push	OFFSET input 
	push	OFFSET error
	push	EDI
	push	OFFSET buffer_32
	push	OFFSET byteCount 
	CALL	ReadVal
	add		EDI, 4
	loop	_get_value
	call	CrLf

	push	OFFSET out_message
	push	LENGTHOF array
	push	OFFSET array
	push	OFFSET out_str
	CALL	WriteVal
	call	CrLf

	push	OFFSET array
	push	OFFSET sum
	CALL	SumCalc

	push	OFFSET sum_mes
	push	LENGTHOF sum
	push	OFFSET sum
	push	OFFSET out_str
	CALL	WriteVal

	push	OFFSET sum
	push	OFFSET average
	CALL	AverageCalc

	push	OFFSET average_mes
	push	LENGTHOF average
	push	OFFSET average
	push	OFFSET out_str
	CALL	WriteVal

	push	OFFSET exunt
	CALL	exit_message

	Invoke ExitProcess,0	
main ENDP

; Name: introduction
; Description: this procedure simply introduces the program to the user
; Pre: everything passed as a parameter must be an address offset of a string array
; Post:
; Receives [EBP + 20] = intro offset, [EBP + 16] = intro_1 offset, [EBP + 12] = intro_2 offset, [EBP + 8] = intro_3 offset
; Returns:
introduction PROC
	push	EBP
	mov		EBP, ESP
	push	EDX

	mov		EDX, [EBP+20]
	call	WriteString
	mov		EDX, [EBP+16]
	call	WriteString
	mov		EDX, [EBP+12]
	call	WriteString
	mov		EDX, [EBP+8]
	call	WriteString
	call	CrLf

	pop		EDX
	pop		EBP
	RET		16
introduction ENDP

; Name: ReadVal
; Description: Uses the mGetString MACRO to recieve a single user string array (which should always be 'signed integers' in this program). Validates if the input is indeed
;				a signed integer or out of bounds, using EBX to hold a boolean value to indicate sign. Once the value is validated, a conversion from ASCII to SDWORD is made, before storing in 
;				an array. Utilizes string primitives.
;				ASCII 48-57 is 0-9, and 43 is +, 45 is -, 32 is ' '
; Pre: Loop will occur in main procedure - loop count needs to be equal to the length of the array to be filled, with EDI manually adjusted outside of this procedure.
; Post: 
; Receives: [EBP + 24] = offset input prompt, [EBP + 20] = offset error prompt, [EBP + 16] = value in EDI register, which should be the current index of the array to place a new value in
;			 [EBP + 12] = offset buffer_32 ie user inputted string, [EBP + 8] = byteCount ie length of the user input
; Returns: array should now be filled with SDWORD ints according to the 'values' inputted by the user
ReadVal PROC
	push	EBP
	mov		EBP, ESP
	push	EDI
	push	ESI
	push	EAX
	push	EDX
	push	EBX
	push	ECX
	
	mov		EDI, [EBP + 16] 
	mGetString [EBP + 24], [EBP + 12], 11, [EBP + 8]

 _input_start:
	mov		ECX, [EBP + 8]
	mov		ESI, [EBP + 12]
	mov		EBX, 0 

	cld
	lodsb						; checking first to see if there is a + or - in the input at the first position at ESI
	cmp		AL, 43
	je		_pos
	cmp		AL, 45
	je		_neg
	jmp		_validate

 _invalid:
	mGetString [EBP + 20], [EBP + 12], 11, [EBP + 8]
	jmp		_input_start

 _neg:
	mov		EBX, 1 
	dec		ECX 
	jmp		_next_in_string

 _pos:
	dec		ECX 

 _next_in_string:
	lodsb

 _validate:
	cmp		AL, 48
	jl		_invalid
	cmp		AL, 57
	jg		_invalid

	push	EAX					; This block takes the current value in the SDWORD array, and multiplies it by 10 before adding (ie affixing) the next ASCII conversion.
	mov		EAX, [EDI]			; Won't do anything on the first loop through.
	push	EDX
	mov		EDX, 10
	mul		EDX
	mov		[EDI], EAX
	pop		EDX
	pop		EAX
	sub		AL, 48				; ASCII calculation
	add		[EDI], AL

	loop	_next_in_string

	cmp		EBX, 1
	je		_negative
	jmp		_size

 _negative: 
	mov		EAX, [EDI]
	neg		EAX
	mov		[EDI], EAX

 _size: 
	;jc		_invalid			; check carry flag! 

	pop		ECX
	pop		EBX
	pop		EDX
	pop		EAX
	pop		ESI
	pop		EDI
	pop		EBP
	RET		20
ReadVal ENDP

; Name: WriteVal
; Description: Converts a number SDWORD value to an ASCII digit to print. Utilizes the mDisplayString macro to print the ASCII representation after conversion. Utilizes a similar conversion algorithm
;				as ReadVal, with an extra 0 pushed to indicate when an ASCII has been fully popped. Will first check the first byte to see if a + or - has been placed, before moving forward with string
;				primitives.
;				ASCII 48-57 is 0-9, and 43 is +, 45 is -, 32 is ' '
; Pre:
; Post: out_str will be continuously overwritten and adjusted as conversion are made. 
; Receives: [EBP+20] = address offset of descriptive display, [EBP+16] = length of array passed through for conversion and printing, [EBP+12] = OFFSET of array to iterate through for printing, 
;			[EBP+8] = address offset of single length array used to temporarily hold values for conversion
; Returns:
WriteVal PROC
	push	EBP
	mov		EBP, ESP
	push	ESI
	push	EDI	
	push	ECX
	push	EAX
	push	EBX
	push	EDX

	mDisplayString [EBP + 20]  
	mov		EDI, [EBP + 8] 
	mov		ESI, [EBP + 12] 
	mov		ECX, [EBP + 16] 

 _printNumber:
	mov		EAX, [ESI]		
	cmp		EAX, 0
	js		_negative
	jmp		_zero

 _negative:						; prints a negative sign if the value is negative, before negating the value for easier conversion
	push	EAX
	mov		AL, 45
	stosb
	mDisplayString [EBP + 8]
	dec		EDI
	pop		EAX
	neg		EAX					

 _zero:
	push	0

 _ASCIIjunk:
	mov		EBX, 10				; Takes the current value and divides by 10, taking and pushing the remainder in EDX to affix until a quotient of zero is reached.
	mov		EDX, 0
	div		EBX
	add		EDX, 48
	push	EDX
	cmp		EAX, 0
	jz		_print
	jmp		_ASCIIjunk

 _print:
	pop		EAX					; will take the EDX quotient, until a zero is hit, ie the 0 pushed on the stack (or a remainder of 0 i guess)
	stosb
	mDisplayString [EBP + 8]
	dec		EDI

	cmp		EAX, 0
	jz		_comma
	jmp		_print

 _comma:
	cmp		ECX, 1				; one less comma than values to print
	je		_space

	mov		AL, 44
	stosb
	mDisplayString [EBP + 8]
	dec		EDI

 _space:
	mov		AL, 32
	stosb
	mDisplayString [EBP + 8]
	dec		EDI

	add		ESI, 4
	loop	_printNumber

	call	CrLf

	pop		EDX
	pop		EBX
	pop		EAX
	pop		ECX
	pop		EDI
	pop		ESI
	pop		EBP
	RET		16
WriteVal ENDP

; Name: CalculateSum
; Description: Iterates through the array holding the SDWORD representations of the user input, and calculates the sum
; Pre: Array to iterate through must contain SDWORD values
; Post:
; Receives: [EBP + 12] = offset of SDWORD array, [EBP + 8] = offset of sum array
; Returns: sum array holds the sum total
SumCalc PROC
	push	EBP
	mov		EBP, ESP
	push	EAX
	push	EBX
	push	ECX
	push	ESI

	mov		ESI, [EBP + 12]
	xor		EAX, EAX

	mov		ECX, ARRAYLENGTH
 _sum:
	add		EAX, [ESI]
	add		ESI, 4
	loop	_sum

	mov		EBX, [EBP + 8]
	mov		[EBX], EAX

	pop		ESI
	pop		ECX
	pop		EBX
	pop		EAX
	pop		EBP
	RET		8
SumCalc ENDP

; Name: AverageCalc
; Description: Calculates the truncated average value given sum of the array and its length
; Pre: sum array must contain a value
; Post:
; Receives: [EBP + 12] = offset of the sum array, [EBP + 8] = offset of the average address
; Returns: Average value stored in the average array
AverageCalc PROC
	push	EBP
	mov		EBP, ESP
	push	EDX
	push	EAX
	push	EBX

	mov		EDX, [EBP + 12] 
	mov		EAX, [EDX]
	mov		EBX, ARRAYLENGTH
	CDQ
	idiv	EBX					

	mov		EBX, [EBP + 8] 
	mov		[EBX], EAX

	pop		EBX
	pop		EAX
	pop		EDX
	pop		EBP
	RET		8
AverageCalc ENDP

; Name: exit_message
; Description: this procedure simply says sayonara to the user
; Pre: everything passed as a parameter must be an address offset of a string array
; Post:
; Receives: [EBP + 8] = exunt memory address
; Returns:
exit_message PROC
	push	EBP
	mov		EBP, ESP
	push	EDX

	call	CrLf
	mov		EDX, [EBP + 8]
	call	WriteString

	pop		EDX
	pop		EBP
	RET		4
exit_message ENDP
END main

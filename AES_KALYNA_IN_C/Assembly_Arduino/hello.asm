;hello.asm
;  turns on an LED which is connected to PB5 (digital out 13)

.nolist
.include "./m328Pdef.inc"
.list

;============
;DECLARATIONS

.def temp = r16    
.def overflows = r17

.org 0x0000					; '.org addr' set the next statement at addr
rjmp Reset

.org 0x0020
rjmp overflow_handler

;================	

Reset:
	ldi temp, 0b00000101
	out TCCR0B, temp		; set the Clock Selector Bits CS00, CS01, CS02 to 101
							; this puts Timer Counter0, TCNT0 in to FCPU/1024 mode
							; so it ticks at the CPU freq/1024
	ldi temp, 0b00000001
	sts TIMSK0, temp		; set the Timer Overflow Interrupt Enable (TOIE0) bit 
							; of the Timer Interrupt Mask Register (TIMSK0)

	sei						; enable global interrupts -- equivalent to "sbi SREG, I"

	clr temp
	out TCNT0, temp			; initialize the Timer/Counter to 0
 	
	sbi DDRB, 5				; set PB5 (digital out 13) to output

;======================
; Main body of program:

blink:
	sbi PORTB, 5			; turn on LED on PB5 (digital out 13)
	rcall delay				; delay will be 1/2 second
	cbi PORTB, 5			; turn off LED on PB5 (digital out 13)
	rcall delay
	rjmp blink

delay:
	clr overflows
	sec_count:
		cpi overflows,30	; compare number of overflows(r17) and 30
	brne sec_count			; branch to back to sec_count if not equal
	ret 					; if 30 overflows have occured return to blink

overflow_handler:
	inc overflows			; add 1 to the overflows(r17) variable
	cpi overflows, 61		; comp with 61
	brne PC+2				; pass a line if not equal
	clr overflows			; if 61 overflows occured reset the counter to zero
	reti					; return from interrupt
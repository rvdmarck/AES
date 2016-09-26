.include "m328pdef.inc"
.section .text


;USART needs to be init to enable communications
.global USART_init
USART_init:

	;init baudrate
	ldi r24, lo8(BAUD_PRESCALLER)
	sts UBRR0L, r24					;USART Baud Rate Register Low
	ldi r24, hi8(BAUD_PRESCALLER)
	sts UBRR0H, r24				;USART Baud Rate Register High

	;Enable receiver and transmitter
	ldi r24, (1<<RXEN0)|(1<<TXEN0)
	sts UCSR0B, r24

	;Set frame format : 8 data bit
	ldi r24, (3<<UCSZ00)
	sts UCSR0C, r24
	ret

;Receives the data in the Receive Shift Register
.global USART_receive
USART_receive:

	;wait for data to be received
	lds r24, UCSR0A
	sbrs r24, RXC0  			
	rjmp USART_receive

	; Get and return received data from buffer
	lds r24, UDR0
	ret

.global USART_send
USART_send:
	lds r21, UCSR0A
	sbrs r21, UDRE0
	rjmp USART_send

	sts UDR0, r24
	ret
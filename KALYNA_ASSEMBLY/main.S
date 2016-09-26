.section .data

.global keyyek
.type keyyek, @object
.size keyyek, 16
keyyek: .byte 0X00, 0X01, 0X02, 0X03, 0X04, 0X05, 0X06, 0X07, 0X08, 0X09, 0X0a, 0X0b, 0X0c, 0X0d, 0X0e, 0X0f

.global kt
.type kt, @object
.size kt, 16
kt: .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

.global k0
.type k0, @object
.size k0, 16
k0: .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

.global k1
.type k1, @object
.size k1, 16
k1: .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00


.section .text
.global __do_copy_data
readPlainText:
	ldi r20, 0   				;r20 used as index for the matrix
	readPlainTextLoop:			;will loop 16 times
		push r20				;push index on stack
		call USART_receive		;r16 <- received data
		pop r20					;recup index from stack
		mov r22, r24			;r22 <- received data (from r24)
		mov r24, r20			;r16 <- index
		call setMatrix			
		inc r20					;index++
		cpi r20, 16
		brlt readPlainTextLoop	; if r20-16 < 0
	ret


loop:
	;Sets the matrix with plain text
	call readPlainText

	call keyExpansion
	call cipher

	ldi r24, lo8(state)
    ldi r25, hi8(state)
    call print

    rjmp loop
	ret


.global main
main:
	call USART_init
	ldi r24, 42   		
	call USART_send		
	call loop
	mov r24,1
	ret
.end

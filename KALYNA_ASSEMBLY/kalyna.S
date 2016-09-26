;kalyna functions
.section .text


.global generateIntermediateKey
generateIntermediateKey:
	;copy key in k0
	ldi r24, lo8(keyyek)
	ldi r25, hi8(keyyek)
	ldi r22, lo8(k0)
	ldi r23, hi8(k0)
	call copy
	
	;copy key in k1
	ldi r22, lo8(k1)
	ldi r23, hi8(k1)
	call copy

    ldi r24, lo8(state)
    ldi r25, hi8(state)
    ldi r22, lo8(k0)
    ldi r23, hi8(k0)
	call keyExpansion_addRoundKey

	call executeRound

    ldi r24, lo8(state)
    ldi r25, hi8(state)
    ldi r22, lo8(k0)
    ldi r23, hi8(k0)
    call keyExpansion_xorRoundKey

    call executeRound

    ldi r24, lo8(state)
    ldi r25, hi8(state)
    ldi r22, lo8(k0)
    ldi r23, hi8(k0)
    call keyExpansion_addRoundKey

    call executeRound

    ;copy state in kt
    ldi r24, lo8(state)
    ldi r25, hi8(state)
    ldi r22, lo8(kt)
    ldi r23, hi8(kt)
    call copy

    




.global getState
; r24: index for the state
; return in r24 the value
; change r24, r30, r31
getState:
    mov r30, r24
    ldi r31, 0
    subi r30, lo8(-(state))
    sbci r31, hi8(-(state))
    ld r24, Z
    ret

.global setState
; r24: index, r22: data to set  (init from main.S)
; change r30, r31
setState:
	mov r30, r24		;r30 <- index
	ldi r31, 0
	subi r30, lo8(-(state))
	sbci r31, hi8(-(state))
	st Z, r22
	ret

.global getTmpState
; r24: index for the tmpState
; return in r24 the value
; change r24, r30, r31
getTmpState:
    mov r30, r24
    ldi r31, 0
    subi r30, lo8(-(tmpState))
    sbci r31, hi8(-(tmpState))
    ld r24, Z
    ret

.global setTmpState
; r24: index, r22: data to set  (init from main.S)
; change r30, r31
setTmpState:
    mov r30, r24        ;r30 <- index
    ldi r31, 0
    subi r30, lo8(-(tmpState))
    sbci r31, hi8(-(tmpState))
    st Z, r22
    ret

.global getk0
; r24: index for the k0
; return in r24 the value
; change r24, r30, r31
getk0:
    mov r30, r24
    ldi r31, 0
    subi r30, lo8(-(k0))
    sbci r31, hi8(-(k0))
    ld r24, Z
    ret


; (r24, r25): the address of the array to add roundkey
; (r22, r23): the roundKey
.global keyExpansion_addRoundKey_
keyExpansion_addRoundKey_:
    ldi r21, 0

    mov r30, r24
    mov r31, r25
    mov r28, r22
    mov r29, r23

    ldi r18, 0
    keyExpansion_addRoundKeyLoop_:
        ld r16, Z
        ld r17, Y+

        sts 0x5f, r18                       ; set sreg(0x5f=SREG)
        adc r16, r17
        lds r18, 0x5f                       ; save sreg (in order to keep
                                            ; the C value for adc operation)
        st Z+, r16

        inc r21                             ;loop handling
        cpi r21, 16                         ;
        brlt keyExpansion_addRoundKeyLoop_   ;
    ret


; (r24, r25): the address of the array to add roundkey
; (r22, r23): the roundKey
.global keyExpansion_addRoundKey
keyExpansion_addRoundKey:
    ldi r21, 0

    mov r30, r24
    mov r31, r25
    mov r28, r22
    mov r29, r23

    ldi r18, 0
    keyExpansion_addRoundKeyLoop:
        cpi r21, 8
        breq clearCarry                         ; clear carry after 1st word
        brne skipClearCarry                     ;
        clearCarry:                             ;
            ldi r18, 0                          ;
        skipClearCarry:                         ;

            ld r16, Z
            ld r17, Y+

            sts 0x5f, r18                       ; set sreg(0x5f=SREG)
            adc r16, r17
            lds r18, 0x5f                       ; save sreg (in order to keep
                                                ; the C value for adc operation)
            st Z+, r16

            inc r21                             ;loop handling
            cpi r21, 16                         ;
            brlt keyExpansion_addRoundKeyLoop   ;
    ret


; (r24, r25): the address of the array to xor roundkey
; (r22, r23): the roundKey
.global keyExpansion_xorRoundKey
keyExpansion_xorRoundKey:
    ldi r21, 0

    mov r30, r24
    mov r31, r25
    mov r28, r22
    mov r29, r23
    keyExpansion_xorRoundKeyLoop_:
        ld r16, Z
        ld r17, Y+
        eor r16, r17
        st Z+, r16

        inc r21                             ;loop handling
        cpi r21, 16                         ;
        brlt keyExpansion_xorRoundKeyLoop_  ;
    ret

;change r16, r17, r18, r19, r20, r21, r22, r23, r24, r25, r26, r27, r28, r29, r30, r31 
.global executeRound
executeRound:
	call subBytesKalyna
	call shiftRowsKalyna
    call mixColumns
    ret
	

.global subBytesKalyna
subBytesKalyna:
    ldi r20, 0
    ldi r21, 0				; r21 loops between values : 0,1,2,3 (for modulo nb SBOXES)
    subBytesLoop:
        mov r24, r20
        call getState
        cpi r21, 0
        breq subSBOX1
        cpi r21, 1
        breq subSBOX2
        cpi r21, 2
        breq subSBOX3
        cpi r21, 3
        breq subSBOX4
    subSBOX1:
    	call subByte1
    	call move
        call setState
        call inc_cpi
        brlt subBytesLoop
    subSBOX2:
    	call subByte2
    	call move
        call setState
        call inc_cpi
        brlt subBytesLoop
    subSBOX3:
    	call subByte3
    	call move
        call setState
        call inc_cpi
        brlt subBytesLoop
    subSBOX4:
    	call subByte4
    	call move
        call setState
        call inc_cpi
        ldi r21, 0				; refresh r21 
        brlt subBytesLoop
    ret

move:
	mov r22, r24
	mov r24, r20
	ret

inc_cpi:
	inc r21
    inc r20
    cpi r20, 16
    ret




; change r24, r16, r17, r18, r22
.global shiftRowsKalyna
shiftRowsKalyna:
    
    ldi r16, 4          ;value that will loop between 4-7 
    ldi r17, 12         ;value that will loop between 12-15
    shiftRowsLoop:
        mov r24, r16
        call getState
        mov r18, r24    ; r18 holds value to shift

        mov r24, r17
        call getState
        mov r22, r24    ; r22 holds holds value to shift 

        mov r24, r16    ;value and INDEX are set for setState
        call setState

        mov r22, r18
        mov r24, r17
        call setState

        inc r16
        inc r17
        cpi r17, 16
        brlt shiftRowsLoop
	ret


.global mixColumns
mixColumns:
    ldi r23, 0              ; r23 : col
    mixColumnsLoop:
        call mixColumn
        inc r23
        cpi r23, 2
        brlt mixColumnsLoop

    ; copy tmpState into state    
    ldi r24, lo8(tmpState)
    ldi r25, hi8(tmpState)
    ldi r22, lo8(state)
    ldi r23, hi8(state)
    call copy

    ret

mixColumn:
    ldi r17, 0              ; r17 : row
    
    rowLoop:
        ldi r16, 0          ; r16 : product
        ldi r18, 0          ; r18 : b
        productLoop:
            ;get state at index b+8*col
            
            ldi r24, 0
            call incCol
            add r24, r18
            call getState
            mov r19, r24        ; r19 <- value of state at index b+8*col

            ldi r24, 0
            call incColMds
            add r24, r18        
            call getMdsMatrix
            mov r20, r24        ; r20 <- value of mds_matrix at index row*8+b


            ;r19 and r20 contain the value to be multiplied GF

            call multiplyGF     ; result in r19
            ;call sum

            eor r16, r19


            inc r18
            cpi r18, 8
            brlt productLoop


        ldi r24, 0
        call incCol
        add r24, r17        ; index of state to set value
        mov r22, r16
        call setTmpState

        inc r17
        cpi r17, 8
        brlt rowLoop
    ret


;multiplyGF values at r19 and r20
;change r20, r21, r22, r24, r25, r26, r27
multiplyGF:
    ldi r21, 0                          ; r21 used for loop
    ldi r24, 0                          ; r24 : result
    
    multiplyLoop:
        mov r22, r20
        andi r22, 0x1
        cpi r22, 1
        breq odd
        not_odd:
            jmp next_odd

        odd:
            eor r24, r19
        next_odd:
            mov r25, r19               ; r25 : hbit
            andi r25, 0x80

            lsl r19                     ; r19 << 1

            mov r26, r25
            cpi r26, 0x80
            breq reduce
            no_reduce:
                jmp next_reduce

            reduce:
                ldi r27, 0x1d
                eor r19, r27

            next_reduce:
                lsr r20

                inc r21                 ; loop handling
                cpi r21, 8              ;
                brlt multiplyLoop       ;

    mov r19, r24                        ; result in r19
    ret


incCol:
    cpi r23, 0
    breq case0
    cpi r23, 1
    breq case1
    case0:
        ldi r24, 0
        ret
    case1:
        ldi r24, 8
        ret

incColMds:
    cpi r17, 0
    breq case0Mds
    cpi r17, 1
    breq case1Mds
    cpi r17, 2
    breq case2Mds
    cpi r17, 3
    breq case3Mds
    cpi r17, 4
    breq case4Mds
    cpi r17, 5
    breq case5Mds
    cpi r17, 6
    breq case6Mds
    cpi r17, 7
    breq case7Mds
    case0Mds:
        ldi r24, 0
        ret
    case1Mds:
        ldi r24, 8
        ret
    case2Mds:
        ldi r24, 16
        ret
    case3Mds:
        ldi r24, 24
        ret
    case4Mds:
        ldi r24, 32
        ret
    case5Mds:
        ldi r24, 40
        ret
    case6Mds:
        ldi r24, 48
        ret
    case7Mds:
        ldi r24, 56
        ret

keyExpansionEven:

    call initTmv        ; using tmpState instead of creating new array tmv

    ; copy key into initialData
    ldi r24, lo8(keyyek)
    ldi r25, hi8(keyyek)
    ldi r22, lo8(initialData)
    ldi r23, hi8(initialData)
    call copy

    ldi r20, 0              ; r20 <- rounds

    keyExpansionEvenLoop:

        call copyKt_state       

        ; state <- addRoundKey with tmv
        ldi r24, lo8(state)
        ldi r25, hi8(state)
        ldi r22, lo8(tmv)
        ldi r23, hi8(tmv)
        call keyExpansion_addRoundKey

        
        call copyState_ktRound
        call copyInitialData_state

        ; state <- addRoundKey with ktRound
        ldi r24, lo8(state)
        ldi r25, hi8(state)
        ldi r22, lo8(ktRound)
        ldi r23, hi8(ktRound)
        call keyExpansion_addRoundKey

        push r20                                    ; save loop index (r20 used in executeRound)
        call executeRound
        

        ldi r24, lo8(state)
        ldi r25, hi8(state)
        ldi r22, lo8(ktRound)
        ldi r23, hi8(ktRound)
        call keyExpansion_xorRoundKey

        call executeRound
        pop r20                                     ; restore loop index

        ldi r24, lo8(state)
        ldi r25, hi8(state)
        ldi r22, lo8(ktRound)
        ldi r23, hi8(ktRound)
        call keyExpansion_addRoundKey

        call setRoundKeys

        cpi r20, 10
        brge endKeyExpansionEven
        inc r20
        inc r20

        call shiftLeft
        call rotate


        cpi r20, 11
        brlt keyExpansionEvenLoop

    endKeyExpansionEven:
        
    ret


.global keyExpansion
keyExpansion:
    call generateIntermediateKey
    call keyExpansionEven
    call keyExpansionOdd

    ret


initTmv:
    ldi r24, 0              ; index for loop

    initTmvLoop:
        ldi r22, 0x01
        call setTmv
        push r24
        inc r24
        ldi r22, 0x00
        call setTmv
        pop r24

        inc r24             ; loop handling
        inc r24             ;
        cpi r24, 16         ;
        brlt initTmvLoop    ;
    ret

setRoundKeys:
    ldi r21, 0                          ; r21 keyExpansionEvenSetRoundKeyLoop index
    keyExpansionEvenSetRoundKeyLoop:
        mov r23, r21
        ldi r18, 16                     ; r18 <- nb*8
        mov r16, r20                    ; r16 <- round
        mul r16, r18
        add r23, r0                    ; index for roundKey

        mov r24, r21
        call getState
        mov r22, r24
        mov r24, r23
        call setRoundKey


        inc r21                                 ;loop handling
        cpi r21, 16                             ;
        brlt keyExpansionEvenSetRoundKeyLoop    ;
    ret

shiftLeft:
    ldi r21, 0
    shiftLoop:

        mov r24, r21
        call getTmv
        lsl r24
        mov r22, r24
        mov r24, r21
        call setTmv

        inc r21
        cpi r21, 16
        brlt shiftLoop
    ret

rotate:
    ldi r21, 0
    ldi r18, 8
    rotateLoop:

        mov r24, r21
        call getInitialData
        mov r16, r24                  ; r16 <- tmp value 

        mov r17, r21
        add r17, r18                  ; r17 <- r21(index)+8
        mov r24, r17
        call getInitialData
        mov r22, r24
        mov r24, r21
        call setInitialData

        mov r22, r16
        mov r24, r17
        call setInitialData

        inc r21
        cpi r21, 8
        brlt rotateLoop
    ret

copyState_ktRound:
    ldi r24, lo8(state)
    ldi r25, hi8(state)
    ldi r22, lo8(ktRound)
    ldi r23, hi8(ktRound)
    call copy
    ret

copyInitialData_state:
    ldi r24, lo8(initialData)
    ldi r25, hi8(initialData)
    ldi r22, lo8(state)
    ldi r23, hi8(state)
    call copy
    ret

copyKt_state:
    ldi r24, lo8(kt)
    ldi r25, hi8(kt)
    ldi r22, lo8(state)
    ldi r23, hi8(state)
    call copy 
    ret

keyExpansionOdd:
    ldi r16, 16                                     ; r16 <- step (16)                                
    ldi r20, 1
    keyExpansionOddLoop:
        ldi r21, 0
        copyEvenIntoOdd:
            ;r24 = (r20*r16+r21)-r16 = (indexOddLoop*step+indexThisLoop)-step
            mul r16, r20
            mov r24, r0 
            add r24, r21
            mov r23, r24                            ; r23 <- (r20*r16+r21)
            sub r24, r16
            call getRoundKey
            mov r22, r24                            ; r22 <- value of Even 
            mov r24, r23
            call setRoundKey

            inc r21
            cpi r21, 16
            brlt copyEvenIntoOdd

        ldi r21, 0
        copyOddInTest:
            mul r16, r20
            mov r24, r0 
            add r24, r21
            call getRoundKey
            mov r22, r24
            mov r24, r21
            call setTest

            inc r21
            cpi r21, 16
            brlt copyOddInTest
        call rotateLeft                             ; rotated array in tmpState

        ldi r21, 0
        copyRotatedArray:
            mov r24, r21
            call getTmpState
            mov r22, r24

            mul r16, r20
            mov r24, r0 
            add r24, r21
            call setRoundKey
            inc r21
            cpi r21, 16
            brlt copyRotatedArray

        inc r20
        inc r20
        cpi r20, 10
        brlt keyExpansionOddLoop
    ret

rotateLeft:
    ldi r18, 0
    ldi r19, 9
    rotateLeftLoop:
        mov r24, r18
        call getTest
        mov r26, r24            ; r26 <- value to rotate

        mov r25, r18
        add r25, r19            ;index + 9

        cpi  r25, 16             ; (index+9) >= 16? 
        brge greaterCase
        mov r24, r25
        mov r22, r26
        call setTmpState

        inc r18
        jmp rotateLeftLoop

        greaterCase:   
        mov r24, r18
        subi r24, 7
        mov r22, r26
        call setTmpState

        inc r18
        cpi r18, 16
        brlt rotateLeftLoop
 
    ret

.global cipher
cipher:

    ;copy matrix in state
    ldi r24, lo8(matrix)
    ldi r25, hi8(matrix)
    ldi r22, lo8(state)
    ldi r23, hi8(state)
    call copy

    ldi r16, 0                         ;r16 <- round
    push r16
    call addRoundKey
    pop r16
    inc r16

    roundLoop:
        push r16
        call executeRound
        pop r16
        push r16
        call xorRoundKey
        pop r16

        inc r16
        cpi r16, 10
        brlt roundLoop

    call executeRound
    ldi r16, 10
    call addRoundKey

    ret
    
addRoundKey:
    ldi r24, lo8(state)
    ldi r25, hi8(state)
    call getRoundKeyToAdd
    call keyExpansion_addRoundKey
    ret

xorRoundKey:
    ldi r24, lo8(state)
    ldi r25, hi8(state)
    call getRoundKeyToAdd
    call keyExpansion_xorRoundKey
    ret

getRoundKeyToAdd:
    cpi r16, 0
    breq case0RK
    cpi r16, 1
    breq case1RK
    cpi r16, 2
    breq case2RK
    cpi r16, 3
    breq case3RK
    cpi r16, 4
    breq case4RK
    cpi r16, 5
    breq case5RK
    cpi r16, 6
    breq case6RK
    cpi r16, 7
    breq case7RK
    cpi r16, 8
    breq case8RK
    cpi r16, 9
    breq case9RK
    cpi r16, 10
    breq case10RK

    case0RK:
        ldi r22, lo8(roundKey)
        ldi r23, hi8(roundKey)
        ret
    case1RK:
        ldi r22, lo8(roundKey+16)
        ldi r23, hi8(roundKey+16)
        ret
    case2RK:
        ldi r22, lo8(roundKey+32)
        ldi r23, hi8(roundKey+32)
        ret
    case3RK:
        ldi r22, lo8(roundKey+48)
        ldi r23, hi8(roundKey+48)
        ret
    case4RK:
        ldi r22, lo8(roundKey+64)
        ldi r23, hi8(roundKey+64)
        ret
    case5RK:
        ldi r22, lo8(roundKey+80)
        ldi r23, hi8(roundKey+80)
        ret
    case6RK:
        ldi r22, lo8(roundKey+96)
        ldi r23, hi8(roundKey+96)
        ret
    case7RK:
        ldi r22, lo8(roundKey+112)
        ldi r23, hi8(roundKey+112)
        ret
    case8RK:
        ldi r22, lo8(roundKey+128)
        ldi r23, hi8(roundKey+128)
        ret
    case9RK:
        ldi r22, lo8(roundKey+144)
        ldi r23, hi8(roundKey+144)
        ret
    case10RK:
        ldi r22, lo8(roundKey+160)
        ldi r23, hi8(roundKey+160)
        ret
    

  
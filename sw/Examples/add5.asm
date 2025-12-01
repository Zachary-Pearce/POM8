            LDI r0, 240
            STA r0, 0x202   ; store 11110000 in the GPIO DDR
start:      LDA r0, 0x200   ; get input
            ADDI r1, r0, 5  ; add 5 to the input
            LDI r2, 4
shift:      LSL r1, r1      ; shift result to align with output pins
            SUBI r2, r2, 1
            BRZ done
            JMP shift
done:       STA r1, 0x201   ; output result
            JMP start
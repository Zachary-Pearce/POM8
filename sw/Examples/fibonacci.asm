            LDI r0, 0b11110000
            STA r0, 0x202   ; store 11110000 in the GPIO DDR
            LDI r0, 1       ; input 1
            LDI r1, 0       ; input 2
            LDI r2, 20      ; number of terms to calculate
loop:       ADD r1, r0, r0  ; calculate next number in the sequence
            STA r1, 0x201   ; output term
            SUBI r2, r2, 1
            BRZ done
            PUSH r0         ; avoid overwriting calculated term by moving it to r0
            MOV r0, r1
            POP r1
            JMP loop        ; loop back around
done:       HLT
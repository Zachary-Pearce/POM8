            LDI r0, 0b00000001
            LDI r14, 1      ; 1 constant
            LDI r15, 0      ; 0 constant
            STA r0, 0x202   ; store 00000001 in the GPIO DDR
            JMP start

delay:      PUSH r0         ; preserve the original input
            SUBI r0, r0, 0  ; check if the input delay is 0
            BRZ loopDone
redo:       LDI r1, 255     ; 255 * r0 cycle delay
loopa:      SUBI r1, r1, 1  ; burn a cycle
            BRZ loopb
            JMP loopa
loopb:      SUBI r0, r0, 1  ; burn a cycle
            BRZ loopDone
            JMP redo        ; if not zero, do it all again
loopDone:   POP r0
            RET

pwmGen:     STA r14, 0x201  ; set the PWM high
            CALL delay
            PUSH r0         ; save the delay cycles for high PWM
            SUB r3, r0, r0  ; the delay cycles for low PWM
            STA r15, 0x201  ; set the PWM low
            CALL delay
            POP r0          ; restore the delay cycles for high PWM
            RET

start:      LDI r0, 0       ; 0% duty cycle
            LDI r3, 127     ; 127 255*255 delay cycles for 100% duty cycle

incDuty:    CALL pwmGen     ; generate the PWM signal
            ADDI r0, r0, 1  ; increase LED brightness
            SUB r3, r0, r2  ; check if the duty cycle is 100%
            BRZ decDuty     ; if it is start to decrease brightness
            JMP incDuty

decDuty:    SUBI r0, r0, 1  ; decrease LED brightness
            BRZ start       ; when brightness is 0, restart
            CALL pwmGen
            JMP decDuty

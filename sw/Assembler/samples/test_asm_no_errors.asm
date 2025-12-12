; this is an an asm file with non-standard but legal asm code,
;       to test that the tokenisation process does not result in odd tokens within the stream under any coding style
;This line has just another comment with no whitespace between the semicolon and text
;; ;; ; ; This line has a lot of semicolons ; ; ;   ;;     
     ;
        LDA                 r0,         0x000       ;   a lot of whitespace, no errors
STA r15, 0x000 ; A line with readable whitespaces and no indents
ADDI r0,r0,255 ; A line with only required whitespace
start: LDI r0, 0b11111111 ; This is a standard line with a label
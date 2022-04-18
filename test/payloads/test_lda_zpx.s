.segment "CODE"
reset:
    ldx #$2
    lda $40,X

.asciiz "END OF TEST"

.segment "VECTORS"
.word 0
.word reset

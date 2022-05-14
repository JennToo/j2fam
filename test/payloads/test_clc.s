.segment "CODE"
reset:
    lda #142
    adc #174
    clc

.asciiz "END OF TEST"

.segment "VECTORS"
.word 0
.word reset

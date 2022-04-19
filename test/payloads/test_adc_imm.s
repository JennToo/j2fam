.segment "CODE"
reset:
    lda #142
    adc #74

.asciiz "END OF TEST"

.segment "VECTORS"
.word 0
.word reset

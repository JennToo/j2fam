.segment "CODE"
reset:
    lda #142
    adc data

.asciiz "END OF TEST"

data:
.word 74

.segment "VECTORS"
.word 0
.word reset

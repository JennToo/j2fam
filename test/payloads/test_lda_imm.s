.segment "CODE"
reset:
    lda #142

.asciiz "END OF TEST"

.segment "VECTORS"
.word 0
.word reset

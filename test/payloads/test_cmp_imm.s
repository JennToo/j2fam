.segment "CODE"
reset:
    lda #73
    cmp #74

.asciiz "END OF TEST"

.segment "VECTORS"
.word 0
.word reset

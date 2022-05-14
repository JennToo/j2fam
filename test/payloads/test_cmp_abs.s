.segment "CODE"
reset:
    lda #73
    cmp data

.asciiz "END OF TEST"

data:
.word 74

.segment "VECTORS"
.word 0
.word reset

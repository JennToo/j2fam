.segment "CODE"
reset:
    ldy #42
    tya

.asciiz "END OF TEST"

.segment "VECTORS"
.word 0
.word reset

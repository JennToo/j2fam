.segment "CODE"
reset:
    nop

.asciiz "END OF TEST"

.segment "VECTORS"
.word 0
.word reset

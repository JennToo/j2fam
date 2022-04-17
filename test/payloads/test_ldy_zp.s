.segment "CODE"
reset:
    ldy $42

.asciiz "END OF TEST"

.segment "VECTORS"
.word 0
.word reset

.segment "CODE"
reset:
    sec

.asciiz "END OF TEST"

.segment "VECTORS"
.word 0
.word reset

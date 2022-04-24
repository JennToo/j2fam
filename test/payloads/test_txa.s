.segment "CODE"
reset:
    ldx #42
    txa

.asciiz "END OF TEST"

.segment "VECTORS"
.word 0
.word reset

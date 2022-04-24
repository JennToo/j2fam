.segment "CODE"
reset:
    lda #42
    tax

.asciiz "END OF TEST"

.segment "VECTORS"
.word 0
.word reset

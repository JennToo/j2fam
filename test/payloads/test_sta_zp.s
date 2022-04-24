.segment "CODE"
reset:
    lda #74
    sta $42

.asciiz "END OF TEST"

.segment "VECTORS"
.word 0
.word reset

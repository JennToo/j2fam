.segment "CODE"
reset:
    lda #%00001010
    and #%00001100

.asciiz "END OF TEST"

.segment "VECTORS"
.word 0
.word reset

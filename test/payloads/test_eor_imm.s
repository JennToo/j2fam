.segment "CODE"
reset:
    lda #%00001010
    eor #%00001100

.asciiz "END OF TEST"

.segment "VECTORS"
.word 0
.word reset

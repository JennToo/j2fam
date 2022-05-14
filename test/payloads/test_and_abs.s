.segment "CODE"
reset:
    lda #%00001010
    and data

.asciiz "END OF TEST"

data:
.word %00001100

.segment "VECTORS"
.word 0
.word reset

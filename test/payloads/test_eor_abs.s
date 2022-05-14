.segment "CODE"
reset:
    lda #%00001010
    eor data

.asciiz "END OF TEST"

data:
.word %00001100

.segment "VECTORS"
.word 0
.word reset

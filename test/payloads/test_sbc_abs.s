.segment "CODE"
reset:
    lda #142
    sbc data

.asciiz "END OF TEST"

data:
.word 74

.segment "VECTORS"
.word 0
.word reset

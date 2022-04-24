.segment "CODE"
reset:
    lda data

.asciiz "END OF TEST"

data:
.word 42

.segment "VECTORS"
.word 0
.word reset

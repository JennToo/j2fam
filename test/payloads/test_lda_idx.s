.segment "CODE"
reset:
    lda #<data
    sta 7
    lda #>data
    sta 8
    ldx #2
    lda (5,X)

.asciiz "END OF TEST"

data:
.word 42

.segment "VECTORS"
.word 0
.word reset

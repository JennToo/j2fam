.segment "CODE"
reset:
    ldx #42
    txs
    ldx #74
    tsx

.asciiz "END OF TEST"

.segment "VECTORS"
.word 0
.word reset

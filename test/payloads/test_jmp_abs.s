.segment "CODE"
reset:
    jmp ok

bad:
.asciiz "TEST FAILED"

ok:
.asciiz "END OF TEST"

.segment "VECTORS"
.word 0
.word reset

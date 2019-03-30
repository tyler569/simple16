; test comments

;; Fibonacci

ldi r0, 1
ldi r1, 1
ldi r10, 0xFF01
ldi r14, 20000

st r10, r1
add r0, r1
st r10, r0
add r1, r0

cmp r0, r14
jl -10
stop

;; Jump test

; ldi r0, 0
; ldi r1, 5
; 
; ldi r9, 1
; ldi r10, 0xff01
; 
; st r10, r0
; add r0, r9
; cmp r0, r1
; jl -6
; stop

;; Speed test

; ldi r0, 0
; ldi r1, 0
; 
; ldi r4, 1
; 
; ldi r10 FF01h
; 
; add r0, r4
; jnc -2
; st r10, r0
; add r1, r4
; jnc -8
; stop

; IDEAS
; #macro push 1
;   sub r15, 2
;   st r15, %1
; #endmacro
; #macro pop 1
;   ld %1, r15
;   add r15, 2
; #endmacro

; ldi r15, 0x1000


stop


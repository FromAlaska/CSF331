; evenitems.scm
; Jim Samson
; CSF331 Spring 2019
; Assignment 7
; Exercize C


#lang scheme

; Takes a list of all even indices from the list.
(define (evenitems xs)
    (if (not (null? xs))
        (if (not (null? (cdr xs)))
            (cons (car xs) (evenitems (cdr (cdr xs))))
            (cons (car xs) '())
            )
        '()
    )
)
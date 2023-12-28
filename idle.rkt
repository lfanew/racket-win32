#lang racket

(require "w32.rkt")

(define (idle)
  (let ([x (random -20 20)]
        [y (random -20 20)]
        [break (add1 (random 30))])
    (if (mouse-move x y #t)
        (printf "Mouse moved by ~a,~a\r\n" x y)
        (displayln "Failed to move mouse"))
    (printf "Breaking for ~a seconds\r\n" break)
    (sleep break)
    (idle)))

(idle)
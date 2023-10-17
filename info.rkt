#lang info
(define collection "yaml-exp")
(define version "0.1.0")
(define deps '("base" "yaml"))

(define build-deps '("racket-doc" "scribble-lib"))
(define scribblings '(("scribblings/yaml-exp.scrbl" ())))

(define license '(Apache-2.0 OR MIT))

#lang info
(define collection "yaml-exp")
(define version "0.2")
(define deps '("base" "yaml" "rackunit-lib"))

(define build-deps '("racket-doc" "scribble-lib"))
(define scribblings '(("scribblings/yaml-exp.scrbl" ())))

(define license '(Apache-2.0 OR MIT))

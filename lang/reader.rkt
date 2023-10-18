#lang s-exp syntax/module-reader
#:language read
#:read read-yaml-exp-whole-body
#:read-syntax read-yaml-exp-syntax-whole-body
#:whole-body-readers? #true
(require "../reader-impl.rkt")

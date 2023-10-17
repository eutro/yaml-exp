#lang s-exp syntax/module-reader
#:language read
#:read read-yaml-exp
#:read-syntax read-yaml-exp-syntax
#:whole-body-readers? #true
(require "../reader-impl.rkt")

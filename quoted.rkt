#lang racket/base

(require (for-syntax racket/base))
(provide (rename-out
          [quoted-modbeg #%module-begin]
          [quoted-top-interaction #%top-interaction]))

(define-syntax (quoted-modbeg stx)
  (syntax-case stx ()
    [(_ data ...)
     (syntax/loc stx
       (#%module-begin
        (writeln 'data) ...))]))

(define-syntax (quoted-top-interaction stx)
  (syntax-case stx ()
    [(_ . expr)
     (syntax/loc stx
       (writeln 'expr))]))

(module reader syntax/module-reader
  yaml-exp/quoted
  #:read read-yaml-exp
  #:read-syntax read-yaml-exp-syntax
  #:whole-body-readers? #true
  (require "reader-impl.rkt"))

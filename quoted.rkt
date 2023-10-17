#lang yaml-exp racket/base

- require:
  - for-syntax:
    - racket/base
- provide:
  - rename-out:
    - quoted-modbeg: [!sym "#%module-begin"]
    - quoted-top-interaction: [!sym "#%top-interaction"]

- define-syntax:
  - quoted-modbeg: [stx]
  - syntax-case:
    - stx
    - null
    - [_, data, ...]:
      - syntax/loc:
        - stx
        - !sym "#%module-begin":
          - writeln: [quote: [data]]
          - ...

- define-syntax:
  - quoted-top-interaction: [stx]
  - syntax-case:
    - stx
    - null
    - {_: expr}:
      - syntax/loc:
        - stx
        - writeln: [quote: [expr]]

- module:
  - reader
  - syntax/module-reader
  - yaml-exp/quoted

  - !kw read
  - read-yaml-exp

  - !kw read-syntax
  - read-yaml-exp-syntax

  - !kw whole-body-readers?
  - true

  - require: ["reader-impl.rkt"]

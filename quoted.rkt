#lang yaml-exp racket/base

- require:
  - for-syntax:
    - racket/base
  - only-in:
    - "reader.rkt"
    - install-yaml-read-interaction
- provide:
  - rename-out:
    - quoted-modbeg: [!sym "#%module-begin"]
    - quoted-top-interaction: [!sym "#%top-interaction"]
  - top-interacted

- install-yaml-read-interaction:

- define:
  - top-interacted: [doc]
  - writeln: [doc]

- define-syntax:
  - quoted-modbeg: [stx]
  - syntax-case:
    - stx
    - null
    - [_, data, ...]:
      - syntax/loc:
        - stx
        - !sym "#%module-begin":
          - for-each: [writeln, [quote: [data]]]
          - ...

- define-syntax:
  - quoted-top-interaction: [stx]
  - syntax-case:
    - stx
    - null
    - {_: expr}:
      - syntax/loc:
        - stx
        - top-interacted: [quote: [expr]]

- module:
  - reader
  - syntax/module-reader
  - yaml-exp/quoted

  - !kw read
  - read-yaml-exp

  - !kw read-syntax
  - read-yaml-exp-syntax

  - require: ["reader-impl.rkt"]

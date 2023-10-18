#lang yaml-exp racket/base

- require: ["reader-impl.rkt"]
- provide:
  - rename-out:
    - read-yaml-exp: [read]
    - read-yaml-exp-syntax: [read-syntax]
  - install-yaml-read-interaction

- define:
  - install-yaml-read-interaction:
  - current-read-interaction: [yaml-read-interaction]

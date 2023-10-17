#lang yaml-exp racket

- define:
  - fibbi: [x]
  - if:
    - <=:
      - x
      - 1
    - x
    - +:
      - fibbi:
        - -:
          - x
          - 1
      - fibbi:
        - -:
          - x
          - 2

- displayln:
  - fibbi: [10]

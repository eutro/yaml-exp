#lang yaml-exp racket

- require:
  - rackunit

- check-equal?:
  - quote:
    - define:
      - fib: [x]
      - if:
        - [<=, x, 1]
        - x
        - +:
          - fib:
            - [-, x, 1]
          - fib:
            - [-, x, 2]
  - quote:
    - !read |
      (define (fib x)
        (if (<= x 1)
            x
            (+ (fib (- x 1))
               (fib (- x 2)))))

- check-equal?:
  - quote:
    - define:
      - marks->srcloc: [src, start, end]
      - define-values:
        - [line-off, col-off, pos-off]
        - apply:
          - values
          - yaml-position-offset:
      - srcloc:
        - src
        # line
        - +:
          - line-off
          - mark-line: [start]
        # col
        - +:
          - if:
            - =:
              - 0
              - mark-line: [start]
            - col-off
            - 0
          - mark-column: [start]
        # pos
        - +:
          - pos-off
          - mark-index: [start]
        # span
        - -:
          - mark-index: [end]
          - mark-index: [start]
  - quote:
    - !read |
      (define (marks->srcloc src start end)
        (define-values (line-off col-off pos-off)
          (apply values (yaml-position-offset)))
        (srcloc
         src
         (+ line-off (mark-line start))
         (+ (if (= 0 (mark-line start))
                col-off 0)
            (mark-column start))
         (+ pos-off (mark-index start))
         (- (mark-index end) (mark-index start))))

- check-equal?:
  - No
  - !read |
    #false

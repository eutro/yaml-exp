#lang yaml-exp/quoted

- define: [x, 10]

- define:
  - foo: args
  - args

- define:
  - foo:
     a:
      b: tail
  - tail: !read |
      10
      20
      30

- check-equal?:
  - No
  - !read |
    #false

- foo: [
     foo
     bar
    ]

- let*:
  - { y: [f: [x]]
    , z: [+: [y, 1]] }
  - !sym "*": [y, z]

- define: [some-char, !char u00A0]

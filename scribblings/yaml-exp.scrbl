;; -*- Mode: yaml -*-
#lang yaml-exp scribble/manual/lang
---

- doc

- require:
  - for-label:
    - racket/base
    - yaml

- title: [YAML Syntax for Racket Languages]

- author: ["Eutro"]

- defmodulelang:
  - yaml-exp
  - [list, "The ", racketmodname: [yaml-exp], "  language replaces the reader
     for any module language with a YAML reader using the ",
     racketmodname: [yaml], " package.\n\nHere's an example:"]

- codeblock:
  - |-
    #lang yaml-exp racket/base
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

- section: [YAML to Code Mapping]

- |
  The reader clearly doesn't spit out beautiful maps for you like it
  might for a pure YAML document. In fact, it performs a few
  conversions to produce "usable" source code. These are:

- define-syntax-rule:
  - expected-expansions: [[yaml, racket], ...]
  - itemlist:
    - item:
      - "YAML:"
      - codeblock:
        - !kw keep-lang-line?
        - no
        - |
          #lang yaml-exp racket/base
        - yaml
      - "Becomes:"
      - racketblock: [racket]
    - ...

- itemlist:
  - item:

    - [ list, "Plain, unquoted strings are converted to symbols when
        the entire string is a ", racket: [read], "able symbol
        as-is. (Otherwise they remain as strings).\n\n For example, ",
        racketvalfont: ["define"], " would be read as a symbol, but ",
        racketvalfont: [Hello world!], " would be read as a string
        (though be careful with commas if you are in a flow-style
        sequence), and ", racketvalfont: ["no"], " would be a boolean
        as usual." ]

  - item:

    - [ list, "Mappings are interpreted as a sequence of forms, one
        for each key-value pair, where each key is simply ", racket:
        [cons], "ed with its associated value. If the map only has one
        key-value pair, then it is returned alone, otherwise all the
        key-value pairs are returned as a list. Pairs and improper
        lists can be constructed this way. These cannot use ",
        racketparenfont: ["!!merge"], " tags, use ", racketparenfont:
        ["!hash"] ," (below) for that.\n\nExamples:" ]

    - expected-expansions:
      - - |-
          - define: [x, 10]
        - !read (define x 10)
      - - |-
          - define:
            - foo: args
            - args
        - !read |
          (define (foo . args)
            args)
      - - |-
          - define:
            - foo:
               a:
                b: tail
            - tail
        - !read |
          (define (foo a b . tail)
            tail)
      - - |-
          - let*:
            - { y: [f: [x]]
              , z: [+: [y, 1]] }
            - !sym "*": [y, z]
        - !read |
          (let* ((y (f x))
                 (z (+ y 1)))
            (* y z))

  - item:
    - Sequences continue to be lists, flow-style or not.

  - item:
    - "Finally, there are some tags available:"
    - itemize:
        - item: [
            racketparenfont: ["!kw keyword"], " produces ", racket:
            [!kw keyword], "s, while ", racketidfont: ["!sym symbol"],
            " produces ", racket: [symbols], ", without any
            restrictions on the content."
            ]
        - item: [
            racketparenfont: ["!vector"], " and ", racketparenfont:
            ["!hash"], " both produce ", racket: [!sym "vector?"], "s
            and ", racket: [!sym "hash?"], "es, from sequences and mappings,
            respectively."
            ]
        - item: [
            racketvalfont: ["!char <char-constant>"], " reads as ",
            racketvalfont: ["#\\<char-constant>"], " does; see ",
            secref: ["parse-character", !kw doc, quote: [lib:
            ["scribblings/reference/reference.scrbl"]]], "."
            ]
        - item: [
            "All the tags (global and local) from base ",
            racketmodname: [yaml], " are also available; see ",
            secref: ["expressions", !kw doc, quote: [lib:
            ["yaml/scribblings/yaml.scrbl"]]], "."
            ]

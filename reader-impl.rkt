#lang racket/base

(require yaml yaml/nodes yaml/errors
         racket/port racket/list
         syntax/readerr)

(provide read-yaml-exp read-yaml-exp-syntax
         read-yaml-exp-whole-body read-yaml-exp-syntax-whole-body
         yaml-read-interaction)

(define (yaml-read-interaction src in)
  (parameterize ([read-accept-reader #true]
                 [read-accept-lang #false])
    (read-yaml-exp-syntax src in)))

(define (yaml-org-tag nm)
  (string-append "tag:yaml.org,2002:" nm))
(define yaml-seq-tag (yaml-org-tag "seq"))
(define yaml-str-tag (yaml-org-tag "str"))
(define yaml-map-tag (yaml-org-tag "map"))

(define (read-yaml-exp in)
  (read-yaml-impl in #false #false))

(define (read-yaml-exp-syntax src in)
  (read-yaml-impl in #true src))

(define (read-yaml-whole-body f . args)
  (append*
   (port->list
    (lambda (_ignored)
      (apply f args))
    (last args))))

(define (read-yaml-exp-whole-body in)
  (read-yaml-whole-body read-yaml-exp in))

(define (read-yaml-exp-syntax-whole-body src in)
  (read-yaml-whole-body read-yaml-exp-syntax src in))

(define yaml-position-offset (make-parameter (list 1 0 0)))

;; ensure that syntax? is always yaml?
(yaml-representers
 (list*
  (yaml-representer
   syntax?
   (lambda (stx)
     (define value (syntax->datum stx))
     ;; recurse
     (define as-seq (represent-sequence yaml-seq-tag (list value)))
     (car (sequence-node-value as-seq))))
  (yaml-representers)))

(define (read-yaml-impl in stx? src)
  (port-count-lines! in)
  (parameterize ([yaml-constructors (yaml-exp-constructors stx? src)]
                 [yaml-null null]
                 [yaml-position-offset
                  (call-with-values
                   (λ () (port-next-location in))
                   list)])
    (or (read-yaml in) eof)))

(define (marks->srcloc src start end)
  (define-values (line-off col-off pos-off)
    (apply values (yaml-position-offset)))
  (srcloc
   src
   #;line (and start (+ line-off (mark-line start)))
   #;col (and start
              (+ (if (zero? (mark-line start))
                     col-off 0)
                 (mark-column start)))
   #;pos (and start (+ pos-off (mark-index start)))
   #;span (and start end (- (mark-index end) (mark-index start)))))

(define (node->srcloc src node)
  (marks->srcloc src (node-start node) (node-end node)))

(define (node->syntax src node datum)
  (datum->syntax #f datum (node->srcloc src node)))

(define (yaml-exp-constructors stx? src)

  (define (syntaxify node datum)
    (if stx?
        (node->syntax src node datum)
        datum))

  (define (unsyntaxify maybe-stx)
    (if (syntax? maybe-stx)
        (syntax->datum maybe-stx)
        maybe-stx))

  (define (call-with-input-node node f #:preserve-column? [pc? #true])
    (call-with-input-string
     (construct-scalar node)
     (λ (in)
       (port-count-lines! in)
       (define srcl (node->srcloc src node))
       (when srcl
         (set-port-next-location!
          in
          (srcloc-line srcl)
          ;; column/position will unfortunately be inaccurate beyond
          ;; the first line; it may be better to keep the column at 0,
          ;; even if it's (probably) completely wrong
          (if pc? (srcloc-column srcl) 0)
          (srcloc-position srcl)))
       (f in))))

  (define (symbolify node)
    (define str (construct-scalar node))
    (cond
      [(scalar-node-style node)
       (syntaxify node str)]
      [else
       (define as-sym
         (call-with-input-node
          node
          (lambda (port)
            (define value (read-syntax src port))
            (if (and (identifier? value)
                     (eof-object? (read-char port)))
                value
                #f))))
       (or as-sym (syntaxify node str))]))

  (define (construct-objects . nodes)
    ;; this isn't provided by the YAML package, so this is a
    ;; workaround
    (apply
     values
     (construct-sequence
      (sequence-node
       (node-start (car nodes))
       (node-end (last nodes))
       yaml-seq-tag
       nodes
       #;flow-style #true))))

  (define (flatten-if-single vals node)
    (if (= 1 (length vals))
        (car vals)
        (syntaxify node vals)))

  (list*
   ;; Symbol override, a node that's otherwise a string becomes a
   ;; symbol instead if it's plain and is fully readable as a
   ;; symbol. This is, of course, completely horrendous, but that's
   ;; the YAML way.
   (yaml-constructor
    (if stx? syntax? (λ (x) (or (symbol? x) (string? x))))
    yaml-str-tag
    symbolify)
   (yaml-constructor
    (if stx? syntax? (λ (x) (or (symbol? x) (string? x))))
    (yaml-org-tag "value")
    symbolify)

   ;; Just add source locations
   (yaml-constructor
    (if stx? syntax? list?)
    yaml-seq-tag
    (λ (node)
      (syntaxify node (construct-sequence node))))

   ;; Parse into a sequence of forms, each key is `cons`ed to its
   ;; mapped value. Returns either a list of all entries (if there is
   ;; more than one key-value pair) or just the first entry, if there
   ;; is only one.
   ;;
   ;; Examples:
   ;;
   ;; - define: [x, 10]
   ;; => (define x 10)
   ;;
   ;; - define:
   ;;   - foo: args
   ;;   - args
   ;; => (define (foo . args) args)
   ;;
   ;; - define:
   ;;   - foo:
   ;;      a:
   ;;       b: tail
   ;;   - tail
   ;; => (define (foo a b . tail) tail)
   (yaml-constructor
    (λ (x) (or (hash? x) (list? x) (syntax? x)))
    yaml-map-tag
    (λ (node)
      (define exprs
        (for/list ([entry (in-list (mapping-node-value node))])
          (define-values (key value)
            (construct-objects (car entry) (cdr entry)))
          (datum->syntax
           #f
           (cons key value)
           (marks->srcloc
            src
            (node-start (car entry))
            (node-end (cdr entry))))))
      (flatten-if-single exprs node)))
   ;; !hash gets you the old !!map behaviour if you want
   (yaml-constructor
    hash? "!hash"
    (λ (node)
      (syntaxify
       node
       (for/hash ([(key val) (in-hash (construct-mapping node))])
         (values (unsyntaxify key) (unsyntaxify val))))))

   ;; !read just `read`s the values of a scalar, fails if used on
   ;; anything else; returns a list of values if more than one thing
   ;; is read
   (yaml-constructor
    (λ (_x) #true)
    "!read"
    (λ (node)
      (define read-vals
        (call-with-input-node
         node
         (λ (in)
           (port->list (λ (port) (read-syntax src port)) in))
         #:preserve-column? #false))
      (flatten-if-single read-vals node)))

   ;; !kw always parses as a keyword
   (yaml-constructor
    keyword? "!kw"
    (λ (node) (string->keyword (construct-scalar node))))

   ;; !sym always parses as a symbol
   (yaml-constructor
    symbol? "!sym"
    (λ (node) (string->symbol (construct-scalar node))))

   ;; !vector parses a sequence to a vector
   (yaml-constructor
    vector? "!vector"
    (λ (node) (list->vector (construct-sequence node))))

   ;; !char tries to read a char
   (yaml-constructor
    char? "!char"
    (λ (node)
      (define node-src (node->srcloc src node))
      (call-with-input-string
       (string-append "#\\" (construct-scalar node))
       (lambda (port)
         (port-count-lines! port)
         (when node-src
           (define (maybe-sub2 n)
             (and n (- n 2)))
           (set-port-next-location!
            port
            (srcloc-line node-src)
            (maybe-sub2 (srcloc-column node-src))
            (maybe-sub2 (srcloc-position node-src))))
         (define value (read-syntax src port))
         (unless (and (char? (syntax-e value))
                      (eof-object? (read-char port)))
           (raise-read-error
            "not a character"
            (srcloc-source node-src)
            (srcloc-line node-src)
            (srcloc-column node-src)
            (srcloc-span node-src)))
         value))))

   (yaml-constructors)))

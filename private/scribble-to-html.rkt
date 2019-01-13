#lang at-exp racket/base

(module+ test
  (require rackunit))


(require raco/all-tools)
;;scribble-to-html : source target body
;; generate html file from scribble file
(define (scribble-to-html source target)
  (define raco-scribble-spec (hash-ref (all-tools) "scribble"))  
  (parameterize
      ([current-namespace (make-base-namespace)]
       [current-command-line-arguments (vector "--html" (path->string source))]
       [current-directory target])
    (dynamic-require (cadr raco-scribble-spec) #f)))

(provide scribble-to-html)


(module+ test
  ;; Any code in this `test` submodule runs when this file is run using DrRacket
  ;; or with `raco test`. The code here does not run when this file is
  ;; required by another module.
  (define testscribble "#lang scribble/base

@title{On the Cookie-Eating Habits of Mice}

If you give a mouse a cookie, he's going to
ask for a glass of milk."))
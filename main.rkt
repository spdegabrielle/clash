#lang at-exp racket/base

(module+ test
  (require rackunit))

;; Notice
;; To install (from within the package directory):
;;   $ raco pkg install
;; To install (once uploaded to pkgs.racket-lang.org):
;;   $ raco pkg install <<name>>
;; To uninstall:
;;   $ raco pkg remove <<name>>
;; To view documentation:
;;   $ raco docs <<name>>
;;
;; For your convenience, we have included a LICENSE.txt file, which links to
;; the GNU Lesser General Public License.
;; If you would prefer to use a different license, replace LICENSE.txt with the
;; desired license.
;;
;; Some users like to add a `private/` directory, place auxiliary files there,
;; and require them in `main.rkt`.
;;
;; See the current version of the racket style guide here:
;; http://docs.racket-lang.org/style/index.html

;;
;My design is; 
;
;GET http(s)://server/<filename in #:server-root-path> 
;-> serve static file at specified path
;GET http(s)://server/<filename in #:server-root-path>?action=edit 
;-> serve edit page servlet that retrieves scribble source
;GET http(s)://server/<filename not found in #:server-root-path> 
;-> serve edit page adding parameters ?action=edit or maybe new
;POST http(s)://server/<filename in #:server-root-path>   
;-> update scribble source file,  generate target html file in #:server-root-path and redirect to target html file at http(s)://server/<filename in #:server-root-path>

;; TODO
; 
; 1. users
;  - authentication mechanism?
;  - user accounts (need a database!)
;  - sessions (cookies? JWT's?)
; 2. git for versioning
;  - commit & Sync on save
;  - page history
;  - perhaps #lang scribble/wiki

;; Code here

(require web-server/servlet
         web-server/servlet-env
         racket/contract
         racket/list
         racket/string)

(require web-server/servlet
         web-server/dispatchers/dispatch
         "private/scribble-to-html.rkt")

(provide/contract (start (request? . -> . response?)))

;; get the filename from a request
(define (req->filename req) (path/param-path (last (url-path (request-uri req)))))

(require racket/file)
;; folder to store html static files
(define page-root (build-path (current-directory) "html"))
;; folder to store scribble source (or other source format)
(define scribble-root (build-path (current-directory) "scribble"))
;(static-files-path page-root)
;; read scribble file
(define (read-scribble name source)
  ;(displayln (build-path source (string-append name ".scrbl")))
  (file->string (build-path source (string-append name ".scrbl"))))

;; write scribble file
(define (write-scribble name body destinaton)
  (call-with-output-file (build-path destinaton (string-append name ".scrbl"))
    (lambda (out) (display body out)) #:mode 'text #:exists 'replace))

(define (name->scrbl-filename root name)
  (build-path root (string-append name ".scrbl")))

(define (name->html-filename root name)
  (build-path root (string-append name ".html")))
 
; and post is a (post title body)
; where title is a string, and body is a string
(struct post (title body))
  
(define (start request)
  (render-edit-page request))
 
; parse-post: bindings -> post
; Extracts a post out of the bindings.
(define (parse-post bindings)
  (post (extract-binding/single 'title bindings)
        (extract-binding/single 'body bindings)))
 
; render-blog-page: request -> doesn't return
; Produces an HTML page of the content of the BLOG.
(define (render-edit-page req)
  
  ;; show the edit page
  (define (edit-page-generator embed/url)
    (define scribbletitle (string-trim (req->filename req) ".html"))
    (define scribblebody (read-scribble scribbletitle scribble-root))
    (response/xexpr
     `(html
       (head (title "page Details"))
       (body
        (h1 "Editor")
        (form ((action ,(embed/url save-handler)))
              "Title:" (input ((name "title")(value ,scribbletitle)))
              (br) "text:" (br)
              (textarea
               ((name "body") (wrap "hard") (rows "35") (cols "80"))
               ,scribblebody)
              (button ((type "submit")) "save" ))))))


    ;; show the edit page
  (define (new-page-generator embed/url)
    (define scribbletitle (string-trim (req->filename req) ".html"))
    (response/xexpr
     `(html
       (head (title "page Details"))
       (body
        (h1 "Editor")
        (form ((action ,(embed/url save-handler)))
              "Title:" (input ((name "title")(value ,scribbletitle)))
              (br) "text:" (br)
              (textarea
               ((name "body") (wrap "hard") (rows "35") (cols "80"))
               "#lang scribble/base")
              (button ((type "submit")) "save" ))))))
  
  (define (save-handler req)
    (define a-post (parse-post (request-bindings req)))
    (define scrbl-file (name->scrbl-filename scribble-root (post-title a-post)))
    (call-with-output-file scrbl-file
      #:mode 'text #:exists 'replace
      (lambda (out) (display (post-body a-post) out)))
    (scribble-to-html scrbl-file page-root)
    (redirect-to (string-append "/" (post-title a-post) ".html" )))

  (define query (url-query (request-uri req)))
  (define filename (req->filename req))
  ;(displayln query)
  (cond
    [(and (not (empty? query)) (equal? (caar query) 'action) (equal? (cdar query) "edit"))
     (send/suspend/dispatch edit-page-generator)]
    [(and (regexp-match @regexp{.*\.html$} filename) ; only .html
      (not (file-exists? (build-path page-root filename))))
     (send/suspend/dispatch new-page-generator)]
    [else (next-dispatcher)]))


(module+ test
  ;; Any code in this `test` submodule runs when this file is run using DrRacket
  ;; or with `raco test`. The code here does not run when this file is
  ;; required by another module.
  (define testscribble "#lang scribble/base

@title{On the Cookie-Eating Habits of Extra-LARGE Mice}

If you give a mouse a cookie, he's going to
ask for a glass of milk.")
  (write-scribble "main" testscribble scribble-root)
  (write-scribble "home" testscribble scribble-root)

  )

(module+ main
  ;; (Optional) main submodule. Put code here if you need it to be executed when
  ;; this file is run using DrRacket or the `racket` executable.  The code here
  ;; does not run when this file is required by another module. Documentation:
  ;; http://docs.racket-lang.org/guide/Module_Syntax.html#%28part._main-and-test%29

  (serve/servlet render-edit-page
                 #:launch-browser? #t
                 #:quit? #f
                 #:listen-ip #f
                 #:port 80
                 #:servlet-regexp #rx""
                 #:extra-files-paths (list page-root)
                 #:servlet-path "/mouse.html") ;"/mouse.html?action=edit")

  )

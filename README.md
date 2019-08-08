Clash - a wiki in racket using scribble.
=====

> _We plan to replace this wiki (eventually) with a wiki written in Racket, to which we will migrate the existing content._

(footer of the racket wiki on GitHub at <https://github.com/racket/racket/wiki>) 

## Goal 
A wiki using scribble as the wiki text! 

## Purpose 
To replace <https://github.com/racket/racket/wiki>.


### Design

DRAFT - subject to change

GET http(s)://server/filename.html    
 - file exist -> serve static file at specified path 
 - file missing -> edit form to create new page  
GET http(s)://server/filename.html?action=edit  
  -> serve edit page servlet that retrieves scribble source and puts it in a form
GET http(s)://server/filename <filename not found in #:server-root-path>  
  -> serve edit page adding parameters ?action=edit or maybe new   
POST form to http(s)://server/filename.html  
  -> update scribble source file & generate target html file in #:server-root-path and redirect to target html file at http(s)://server/filename.html  

the Scribble source and the generated html are in separate folders, 

````
;; folder to store html static files
(define page-root (build-path (current-directory) "html"))
;; folder to store scribble source (or other source format)
(define scribble-root (build-path (current-directory) "scribble"))
````

* filename.html is in  `#:extra-files-paths` aka `page-root`
* I'm trying to make it with plain old <form>s hence the use of POST (or can I use PUT or invent a verb in modern browsers?)  

### ToDO  
* users/authentication (openID?)
* git for versions (of the scribble files)
* history, scribble-diff, rollback
* An editor(in RacketScript), to provide a better UX than a form textbox 
* editing from DrRacket
* pollen instead of scribble (pollen allows undefined identifiers - which scribble doesn't - which would be useful in creating new pages in a wiki-like fashion) pollen blog: <https://github.com/otherjoel/thenotepad> may be relevant

### resources

* http://docs.racket-lang.org/continue/index.html
* https://serverracket.com/
* https://github.com/mbutterick/pollen/blob/master/pollen/private/project-server.rkt
* http://matt.might.net/articles/low-level-web-in-racket/
  * https://github.com/mattmight/uiki





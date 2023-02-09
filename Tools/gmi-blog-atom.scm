;;;; gmi-blog-atom.scm - Convert gemtext .gmi file to an .atom file.
;;;
;;; References: 
;;;     Subscribing to Gemini pages -- https://gemini.circumlunar.space/docs/companion/subscription.gmi
;;;     RFC 4287 The Atom Syndication Format -- https://www.rfc-editor.org/info/rfc4287
;;;     RFC 8288 Web Linking -- https://www.rfc-editor.org/info/rfc8288
;;;     RFC 3339 Date and Time on the Internet: Timestamps -- https://www.rfc-editor.org/info/rfc3339
;;;     RFC 3987 Internationalized Resource Identifiers (IRIs) -- https://www.rfc-editor.org/info/rfc3987
;;;     RFC 8141 Uniform Resource Names (URNs) -- https://www.rfc-editor.org/info/rfc8141
;;;     W3C Feed Validation Service -- https://validator.w3.org/feed/
(module gmi-blog-atom ()

(import (scheme))

(import (utf8))

(import (chicken base))
(import (chicken file posix))
(import (chicken io))
(import (chicken irregex))
(import (chicken pathname))
(import (chicken port))
(import (chicken process-context))

(import (args))
(import (loop))
(import (schemepunk show))
(import (srfi 1))
(import (srfi 19))
(import (srfi 152))

(define-syntax dbg
  (syntax-rules ()
    ((_ e1 e2 ...)
     (when *debugging*
       e1 e2 ...
       (flush-output (current-error-port))))))

(define (dfmt . args)
  (apply show (cons (current-error-port) args)))

(define (die status . args)
  (show (current-error-port) (program-name) ": ")
  (apply show (cons (current-error-port) args))
  (show (current-error-port) "\n")
  (exit status))

(define link-irx (string->irregex "^=> *(.+) +([0-9]{4}-[0-9]{2}-[0-9]{2}) ([0-9]{2}:[0-9]{2}:[0-9]{2}) ([A-Z]{3}+) +- *(.+)"))

(define (string-max s1 s2)
  (if (string>=? s1 s2)
      s1
      s2))

(define tz-abbreviation-to-offset
  '(("EST" . "-05:00")
    ("EDT" . "-04:00"))) 

(define (make-date-time date time tz)
  (let ((offset (cdr (assoc tz tz-abbreviation-to-offset))))
    (string-append date "T" time offset)))

(define (drop-directories number-to-drop pathname)
  (let*-values (((directory filename extension)
                 (decompose-pathname pathname))
                ((base-origin base-directory directory-elements)
                 (decompose-directory directory)))
    (let* ((directories (drop directory-elements number-to-drop)))
      (make-pathname directories filename extension))))

(define (process-entry link)
  (let* ((m             (irregex-search link-irx link))
         (relative-href (irregex-match-substring m 1))
         (href          (pathname-replace-extension
                         (string-append *base-url* "blog/" relative-href)
                         ".html"))
         (date          (irregex-match-substring m 2))
         (time          (irregex-match-substring m 3))
         (tz            (irregex-match-substring m 4))
         (title         (irregex-match-substring m 5))
         (updated       (make-date-time date time tz)))
    (show #t "  <entry>" nl)
    (show #t "    <title>" title "</title>" nl)
    (show #t "    <link href=\"" href "\"/>" nl)
    (show #t "    <id>" href "</id>" nl)
    (show #t "    <updated>" updated "</updated>" nl)
    (show #t "  </entry>" nl nl)))

(define (process-feed update-date gmi-filename title links)
  (let* ((relative-gmi-filename (drop-directories *directories-to-drop*
                                                      gmi-filename))
         (relative-html-filename (pathname-replace-extension
                                  relative-gmi-filename ".html"))
         (relative-atom-filename (pathname-replace-extension
                                  relative-gmi-filename ".atom"))

         (html-url (string-append *base-url* relative-html-filename))
         (atom-url (string-append *base-url* relative-atom-filename))
         )
    (show #t "<?xml version=\"1.0\" encoding=\"utf-8\"?>" nl)
    (show #t "<feed xml:lang=\"en\" xmlns=\"http://www.w3.org/2005/Atom\">" nl)
    (show #t "  <title>" title "</title>" nl)
    (show #t "  <link rel=\"alternate\" type=\"text/html\" href=\"" html-url "\"/>" nl)
    (show #t "  <link rel=\"self\" type=\"application/atom+xml\" href=\""
          atom-url "\"/>" nl) 
    (show #t "  <updated>" update-date "</updated>" nl)
    (show #t "  <author>" nl)
    (show #t "    <name>" *author-name* "</name>" nl)
    (show #t "  </author>" nl)
    (show #t "  <id>" atom-url "</id>" nl)
    (show #t "  <rights>Copyright © " (date->string (current-date) "~Y") " "
          *author-name* "</rights>" nl)
    (show #t "  <generator uri=\"https://github.com/tkurtbond/microblog/blob/main/Tools/gmi-blog-atom.scm\">gmi-blog-atom</generator>" nl nl)

    (loop for link in links do (process-entry link))

    (show #t "</feed>" nl)))

(define (generate-atom gmi-filename)
  (let* ((input-port (open-input-file gmi-filename))
         (title #f)
         (links '())
         (update-date #f))
    (define (process-line line)
      (unless title
        (when (string-prefix? "# " line)
          (set! title (string-copy line 2))))
      (let ((m (irregex-search link-irx line)))
        (cond (m
               (let* ((date      (irregex-match-substring m 2))
                      (time      (irregex-match-substring m 3))
                      (tz        (irregex-match-substring m 4))
                      (title     (irregex-match-substring m 5))
                      (date-time (make-date-time date time tz)))
                 (if update-date 
                     (set! update-date (string-max update-date date-time))
                     (set! update-date date-time))
                 (list line)))
              (else '()))))
    (parameterize ((current-input-port input-port)
                   ;; (current-output-port output-port)
                   )
      (let ((links (loop for line = (read-line) then (read-line)
                         until (eof-object? line)
                         nconc (process-line line))))
        (assert title 'generate-atom "Missing title")
        (assert update-date 'generate-atom "Never found the most recent update")
        
        (process-feed update-date gmi-filename title links)))))

;; Variables for command line options.
(define *author-name* #f)
(define *base-url* #f)
(define *directories-to-drop* 0)

(define (usage)
  (with-output-to-port (current-error-port)
    (lambda ()
      (print "Usage: " (program-name) " [options...] [files...]")
      (newline)
      (print (args:usage +command-line-options+))
      (show #t "Current argv: " (written (argv)) nl)))
  (exit 1))

(define +command-line-options+
  (list (args:make-option
         (a author) #:required "Author name"
         (set! *author-name* arg))
        (args:make-option
         (D drop) #:required
         "Drop ARG directory names from the start of relative links."
         (set! *directories-to-drop* (string->number arg)))
        (args:make-option
         (h help) #:none "Print usage message and exit."
         (usage))
        (args:make-option
         (P prefix) #:required "Prefix to make links absolute."
         (set! *prefix* arg))
        (args:make-option
         (b base) #:required "Base URL for blog"
         (set! *base-url* arg))
        ))




(define (main)
  (receive (options operands) (args:parse (command-line-arguments)
                                          +command-line-options+)

    (unless *author-name* (die 127 "Author name was not specified"))
    (unless *base-url*    (die 127 "Base url was not specified"))

    (loop for filename in operands
          do (generate-atom filename))))

;; Only invoke main if this has been compiled.  That way we can load the
;; module into csi and debug it. 
(cond-expand
  (compiling
   (main))
  (else))
)

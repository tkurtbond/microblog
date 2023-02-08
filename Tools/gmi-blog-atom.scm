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
(import (srfi 152))

;; https://gemini.circumlunar.space/docs/companion/subscription.gmi -- Subscribing to Gemini pages
;; https://www.rfc-editor.org/info/rfc4287 -- RFC 4287 The Atom Syndication Format
;; https://www.rfc-editor.org/info/rfc8288 -- RFC 8288 Web Linking
;; https://www.rfc-editor.org/info/rfc3339 -- RFC 3339 Date and Time on the Internet: Timestamps
;; https://www.rfc-editor.org/info/rfc3987 -- RFC 3987 Internationalized Resource Identifiers (IRIs)
;; https://www.rfc-editor.org/info/rfc8141 -- RFC 8141 Uniform Resource Names (URNs)

(define link-irx (string->irregex "^=> *(.+) +([0-9]{4}-[0-9]{2}-[0-9]{2}) ([0-9]{2}:[0-9]{2}:[0-9]{2}) ([A-Z]{3}+) +- *(.+)"))

(define (string-max s1 s2)
  (if (string>=? s1 s2)
      s1
      s2))

(define (make-date-time date time tz)
  (assert #f 'make-date-time "Not yet implemented"))

(define (process-entry link)
  (let* ((m (irregex-search link-irx link))
         (relative-href (irregex-match-substring m 1))
         (href "fake href")
         (date (irregex-match-substring m 2))
         (time (irregex-match-substring m 3))
         (tz   (irregex-match-substring m 4))
         (title (irregex-match-substring m 5))
         (updated "fake updated")
         (urn "fake entry urn"))
    (show #t "  <entry>" nl)
    (show #t "    <title>" title "<title>" nl)
    (show #t "    <link href=\"" href "\"/>" nl)
    (show #t "    <id>" urn "</id>" nl)
    (show #t "    <updated>" updated "</updated>" nl)
    (show #t "  </entry>" nl nl)))

(define (process-feed update-date html-filename title links)
  (let* ((author-name "fake author-name")
         (urn "fake feed urn"))
    (show #t "<?xml version=\"1.0\" encoding=\"utf-8\"?>" nl)
    (show #t "<feed xmlns=\"http://www.w3.org/2005/Atom\">" nl)
    (show #t "  <title>" title "</title>" nl)
    (show #t "  <link href=\"" html-filename "\"/>" nl)
    (show #t "  <updated>" update-date "</updated>" nl)
    (show #t "  <author>" nl)
    (show #t "    <name>" author-name "</name>" nl)
    (show #t "  </author>" nl)
    (show #t "  <id>" urn "</id>" nl nl)

    (loop for link in links do (process-entry link))

    (show #t "</feed>" nl)))

(define (generate-atom gmi-filename)
  (let* ((atom-filename (pathname-replace-extension gmi-filename ".atom"))
         (html-filename (pathname-replace-extension gmi-filename ".html"))
         (input-port (open-input-file gmi-filename))
         (title #f)
         (links '())
         (update-date #f))
    (define (process-line line)
      (unless title
        (when (string-prefix? "# " line)
          (set! title (string-copy line 2))))
      (let ((m (irregex-search link-irx line)))
        (cond (m
               (let* ((date (irregex-match-substring m 2))
                      (time (irregex-match-substring m 3))
                      (tz   (irregex-match-substring m 4))
                      (title (irregex-match-substring m 5))
                      (date-time (make-date-time date time tz)))
                 (set! update-date (string-max update-date date-time))
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
        
        (process-feed update-date gmi-filename html-filename title links)))))

;; Variables for command line options.
(define *directories-to-drop* 0)
(define *prefix* "")

(define +command-line-options+
  (list (args:make-option
         (D drop) #:required
         "Drop ARG directory names from the start of relative links."
         (set! *directories-to-drop* (string->number arg)))
        (args:make-option
         (P prefix) #:required
         "Prefix to make links absolute."
         (set! *prefix* arg))))

(define (main)
  (receive (options operands) (args:parse (command-line-arguments)
                                          +command-line-options+)

    (loop for filename in (command-line-arguments)
          do (generate-atom filename))))

;; Only invoke main if this has been compiled.  That way we can load the
;; module into csi and debug it. 
(cond-expand
  ((and chicken-5 compiling)
   (main))
  ((and chicken-5 csi)))
)

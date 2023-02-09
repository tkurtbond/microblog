(module tztable2scm ()

(import (scheme))
(import (chicken base))
(import (chicken io))
(import (chicken irregex))

(import (srfi 152))
(import (schemepunk show))
(import (loop))

(define header-end-start "|----------")
(define not-right "^\\| *\\[([A-Za-z]+)\\][^\\|]*|[^\\|]*\\| *([A-Z-a-z]+]([-+]([0-9]+(:[0-9]+))))")
(define line-irx
  (sre->irregex
   '(seq bos
         #\| (* (or #\space #\tab)) #\[ ($ (+ (or alphabetic numeric)))
         (? (+ whitespace) (+ (or alphabetic whitespace))) #\] (* (~ #\|))
         #\| (* (or #\space #\tab)) ($ (* (~ #\|))) (* (or #\space #\tab))
         #\| (* (or #\space #\tab)) "UTC" (? ($ (or #\+ #\-) (+ numeric)
                                                (? (seq #\: (+ numeric)))))
         )))

(define (transform-line line)
  (define m          (irregex-search line-irx line))
  (define tz         (irregex-match-substring m 1))
  (define name       (string-trim-both (irregex-match-substring m 2)))
  (define utc-match  (irregex-match-substring m 3))
  (define utc        (if utc-match utc-match "+00"))
  (show #t "      (" (padded/right 6 (written tz)) " . " (written utc) ")" nl))

(define (main)
  (let ((header-end-seen #f))
    (define (process-line line)
      (cond (header-end-seen
             ;; Now it's just transforming the lines
             (transform-line line))
            (else
             (when (string-prefix? header-end-start line)
               (set! header-end-seen #t)))))
    (show #t "(module tzdata (abbreviation-to-offset)" nl)
    (show #t "  (import scheme)" nl)
    (show #t "  (define abbreviation-to-offset" nl)
    (show #t "    '(" nl)
    (loop for line = (read-line) then (read-line)
          until (eof-object? line)
          do (process-line line))
    (show #t "    )))" nl)
    ))

  
;; Only invoke main if this has been compiled.  That way we can load the
;; module into csi and debug it. 
(cond-expand
  ((and compiling)
   (main))
  (else))
)

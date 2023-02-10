(import (chicken irregex))

(define bare-utc "| [GMT](https://www.utctime.net/gmt-time-now \"GMT Time Now\")                                                                    | Greenwich Mean Time                                      | UTC       |")
(define est "| [EST](https://www.utctime.net/est-time-now \"EST Time Now\")                                                                    | Eastern Standard Time (North America)                    | UTC-05    |")
(define mit "| [MIT](https://www.utctime.net/mit-time-now \"MIT Time Now\")                                                                    | Marquesas Islands Time                                   | UTC-09:30 |")
(define gmt "| [GMT](https://www.utctime.net/gmt-time-now \"GMT Time Now\")                                                                    | Greenwich Mean Time                                      | UTC       |")
(define ist "| [IST Israel](https://www.utctime.net/ist-israel-time-now \"IST Israel Time Now\")                                               | Israel Standard Time                                     | UTC+02    |")
(define fkst "| [FKST Falkland Islands Summer](https://www.utctime.net/fkst-summer-time-now \"FKST Falkland Islands Summer Time Now\")          | Falkland Islands Summer Time                             | UTC-03    |")

(define (x1 tableline) (set! m (irregex-search line-irx tableline)))
(define (x2 n) (irregex-match-substring m n))

(define time-zone-translations
  '(
    ("EST" . "UTC+5")
    ("CST" . "UTC+6")
    ))

(define line "=> 2023/2023-02-10-just-a-test.gmi 2023-02-10 07:59:33-05:00 - Just a test
")

(define (x0 line) (set! m (irregex-search link-irx line)))

(import (chicken io))
(import (html-parser))
(import (sxpath))


(define filename "/Users/tkb/Repos/microblog/gmi/blog/2023/2023-02-10-updated-blog-and-atom-generator-to-use-numeric-time-zone-offsets.html")
(define file (with-input-from-file filename read-string))
(define x (with-input-from-file filename html->sxml))
(define y ((sxpath '(html body main)) x))
(define z (sxml->html y))
(define a (html-escape z))

  
(define (x1 s) (set! m (irregex-search irx s)))
(define irx (sre->irregex '(seq bos (+ alphabetic (* (or alphabetic numeric #\+ #\- #\.)))
                                #\))))


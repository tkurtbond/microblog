(import (chicken irregex))

(define bare-utc "| [GMT](https://www.utctime.net/gmt-time-now \"GMT Time Now\")                                                                    | Greenwich Mean Time                                      | UTC       |")
(define est "| [EST](https://www.utctime.net/est-time-now \"EST Time Now\")                                                                    | Eastern Standard Time (North America)                    | UTC-05    |")
(define mit "| [MIT](https://www.utctime.net/mit-time-now \"MIT Time Now\")                                                                    | Marquesas Islands Time                                   | UTC-09:30 |")
(define gmt "| [GMT](https://www.utctime.net/gmt-time-now \"GMT Time Now\")                                                                    | Greenwich Mean Time                                      | UTC       |")

(define (x1 tableline) (set! m (irregex-search line-irx tableline)))
(define (x2 n) (irregex-match-substring m n))

(define time-zone-translations
  '(
    ("EST" . "UTC+5")
    ("CST" . "UTC+6")
    ))

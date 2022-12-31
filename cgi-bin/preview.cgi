#! /usr/bin/env gforth

require ./render.fs

.( Content-Type: text/html) cr
cr

stdin stdout lichen:render

bye
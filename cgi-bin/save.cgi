#! /usr/bin/env gforth

require ./util.fs
require ./gmi.fs

\ make directory
PATH_INFO lichen:content-path 
2dup dirname mkdir-p throw
\ save the gemtext
w/o create-file throw
dup stdin pipe-file
close-file throw


\ open the gemtext
PATH_INFO lichen:content-path r/o open-file throw
( fd-src )

\ make output file
PATH_INFO lichen:html-dest-path w/o create-file throw
( fd-src fd-html )

dup s" ../template/_header.html" r/o open-file throw dup -rot pipe-file close-file throw
2dup gmi:to-html
dup s" ../template/_footer.html" r/o open-file throw dup -rot pipe-file close-file throw
close-file throw close-file throw

\ verify clean stack
depth 0 <> throw

\ respond
." Status: 204 No Content" cr cr

bye
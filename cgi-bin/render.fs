\ USAGE
\ $ cat in.gmi | gforth render.fs -e 'stdin stdout lichen:render bye' > out.html

require ./util.fs
require ./gmi.fs

: lichen:render ( fd-in fd-out -- )
	s" ../template/_header.html" print-asset
	stdin stdout gmi:to-html
	s" ../template/_footer.html" print-asset
	;
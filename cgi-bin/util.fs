require string.fs

\ ENV

: SCRIPT_NAME ( -- c-addr u )
	s" SCRIPT_NAME" getenv ;

: PATH_INFO ( -- c-addr u )
	s" PATH_INFO" getenv ;

: REQUEST_URI ( -- c-addr u )
	s" REQUEST_URI" getenv ;

\ Files

1024 constant file-buffer-size
create file-buffer file-buffer-size 2 + allot

: print-file ( file-id -- )
	begin
		dup file-buffer file-buffer-size rot ( buf bufsize fileid )
		read-file throw ( len )
	dup 0 > while
		file-buffer swap stdout write-file throw
	repeat 
	drop drop ;

: print-asset ( c-addr u -- )
	r/o open-file throw print-file ;

: pipe-file ( out-fd in-fd -- )
	begin
		dup file-buffer file-buffer-size rot ( out-fd in-fd buf bufsize in-fd )
		read-file throw ( out-fd in-fd len )
	dup 0 > while
		file-buffer swap ( out-fd in-fd fb len )
		3 pick write-file throw
	repeat
	drop drop drop ;

-529 constant ERROR:EXISTS
-514 constant ERROR:DOES-NOT-EXIST

: mkdir-p ( c-addr u -- ior )
	$1FF mkdir-parents \ add mask
	dup ERROR:EXISTS = if \ ignore ERROR:EXISTS
		drop 0
	endif ;


\ Path manipulation

variable lichen:FilePath

: lichen:content-path ( c-addr u -- c-addr u )
	lichen:FilePath $!
	s" .." lichen:FilePath 0 $ins
	lichen:FilePath $@ ;

: lichen:html-dest-path ( c-addr u -- c-addr u )
	lichen:FilePath $! ( u )
	s" .." lichen:FilePath 0 $ins
	lichen:FilePath lichen:FilePath $@len 3 - 3 $del
	s" html" lichen:FilePath lichen:FilePath $@len $ins
	lichen:FilePath $@ ;

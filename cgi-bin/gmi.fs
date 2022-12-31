\ USAGE
\ $ cat in.gmi | gforth gmi.fs -e 'stdin stdout gmi:to-html bye' > out.html

\ === Config === \

true value html:TranslateExtension:gmi>html \ replaces ".gmi" with ".html" in link URLs when enabled
true value html:Image/LazyLoad \ enables loading="lazy" attribute for <img>
true value html:Audio/LazyLoad \ enables preload="none" attribute for <audio>
true value html:Audio/Controls \ enables controls attribute for <audio>
true value html:Video/LazyLoad \ enables preload="none" attribute for <video>
true value html:Video/Controls \ enables controls attribute for <video>
true value html:LinebreakEmpty \ inserts <br> when an empty line is encountered

false value html:MultilineBlockquote \ subsequent blockquote entries (>) are combined as paragraphs when enabled (not Gemtext spec)

\ === Parsing === \

: gmi:preformatted? ( c-addr u -- f )
	s" ```" string-prefix? ;

: gmi:blockquote? ( c-addr u -- f )
	s" >" string-prefix? ;

: gmi:list-item? ( c-addr u -- f )
	s" * " string-prefix? ;

: gmi:link? ( c-addr u -- f )
	s" =>" string-prefix? ;

: gmi:heading? ( c-addr u -- u-header-level )
	0 -rot
	3 min 0 ?do
		dup i + c@ '# = if swap 1 + swap endif
	loop drop ;

: string-suffix? ( c-addr1 u1 c-addr2 u2 -- f )
	2 pick over < if \ early exit if string 2 is longer than string 1
		drop drop drop drop
		false exit
	endif

	dup 3 pick min  \ get check length on top
	4 roll 4 roll + 1 -
	3 roll 3 roll + 1 -
	rot             ( c-end1 c-end2 len )
	
	0 ?do
		2dup i - c@
		swap i - c@
		<> if
			unloop 2drop false exit
		endif
	loop 2drop true ;

\ TODO: short circuit, array of extensions?
: image-extension? ( c-addr u -- f )
	2dup s" .jpg" string-suffix? >r
	2dup s" .jpeg" string-suffix? r> or >r
	2dup s" .png" string-suffix? r> or >r
	2dup s" .gif" string-suffix? r> or >r
	2dup s" .avif" string-suffix? r> or >r
	2dup s" .bmp" string-suffix? r> or >r
	2dup s" .svg" string-suffix? r> or >r
	     s" .webp" string-suffix? r> or
	;

: video-extension? ( c-addr u -- f )
	2dup s" .mp4" string-suffix? >r
	2dup s" .m4v" string-suffix? r> or >r
	2dup s" .ogv" string-suffix? r> or >r
	2dup s" .mov" string-suffix? r> or >r
	2dup s" .webm" string-suffix? r> or >r
	     s" .mkv" string-suffix? r> or
	;

: audio-extension? ( c-addr u -- f )
	2dup s" .mp3" string-suffix? >r
	2dup s" .aac" string-suffix? r> or >r
	2dup s" .wav" string-suffix? r> or >r
	2dup s" .flac" string-suffix? r> or >r
	     s" .ogg" string-suffix? r> or
	;

: gemtext-extension? ( c-addr u -- f )
	s" .gmi" string-suffix? ;

\ === HTML Output === \

: html:escape-sequence ( char -- c-addr u )
	case
		'"' of s" &quot;" endof
		''' of s" &#39;" endof
		'&' of s" &amp;" endof
		'<' of s" &lt;" endof
		'>' of s" &gt;" endof
		0 0 rot \ no escape
	endcase ;

\ NOTE: not verified with UTF-8
: html:type-escaped ( c-addr u -- )
	0 ?do
		dup i + c@ html:escape-sequence
		dup if
			type
		else
			drop drop
			dup i + c@ emit
		endif
	loop drop ;

: html:line-break ." <br>" ;

: html:list/open ." <ul>" ;
: html:list/close ." </ul>" ;

: html:paragraph/open ." <p>" ;
: html:paragraph/close ." </p>" ;

: html:blockquote/open ." <blockquote>" ;
: html:blockquote/close ." </blockquote>" ;

: html:blockquote ( c-content u -- )
	." <blockquote>" html:paragraph/open
	html:type-escaped
	html:paragraph/close ." </blockquote>" ;

: html:preformatted/open ( c-content u -- )
	.\" <pre aria-label=\"" html:type-escaped .\" \">" cr ;

: html:preformatted/close ." </pre>" cr ;


: html:list-item ( c-content u -- )
	." <li>" html:type-escaped ." </li>" ;


: html:link ( c-content u c-url u -- )

	.\" <p><a rel=\"noreferrer\" href=\""
	
	2dup gemtext-extension? html:TranslateExtension:gmi>html and if
		3 - html:type-escaped ." html"
	else
		html:type-escaped
	endif

	.\" \">"
	html:type-escaped
	." </a></p>" ;

: html:image ( c-alt u c-url u -- )
	.\" <img "
	html:Image/LazyLoad if
		.\" loading=\"lazy\" "
	endif
	.\" src=\"" html:type-escaped .\" \" alt=\"" html:type-escaped .\" \">" ;

: html:video ( c-alt u c-url u -- )
	.\" <video "
	html:Video/LazyLoad if
		.\" preload=\"none\" "
	endif
	html:Video/Controls if
		.\" controls "
	endif
	.\" src=\"" html:type-escaped .\" \">"
	.\" <p>" html:type-escaped .\" </p>"
	.\" </video>" ;

: html:audio ( c-alt u c-url u -- )
	.\" <audio "
	html:Audio/LazyLoad if
		.\" preload=\"none\" "
	endif
	html:Audio/Controls if
		.\" controls "
	endif
	.\" src=\"" html:type-escaped .\" \">"
	.\" <p>" html:type-escaped .\" </p>"
	.\" </audio>" ;

: html:heading ( level c-content u -- )
	." <h" 2 pick 48 + emit ." >"
	html:type-escaped
	." </h" 48 + emit ." >"
	;

4096 constant gmi:LINE-BUFFER-SIZE
create   gmi:LineBuffer gmi:LINE-BUFFER-SIZE chars allot
variable gmi:LineNumber
variable gmi:LineLen

0 constant gmi:CAPTURE-NONE
1 constant gmi:CAPTURE-PREFORMATTED
2 constant gmi:CAPTURE-LIST
3 constant gmi:CAPTURE-BLOCKQUOTE
variable gmi:CaptureState

32 constant ch:SPACE
9 constant ch:TAB

: gmi:close-capture ( -- )
	gmi:CaptureState @ case
		gmi:CAPTURE-PREFORMATTED of
			html:preformatted/close
		endof
		gmi:CAPTURE-LIST of
			html:list/close
		endof
		gmi:CAPTURE-BLOCKQUOTE of
			html:blockquote/close
		endof
	endcase
	gmi:CAPTURE-NONE gmi:CaptureState ! ;

: gmi:process-line ( -- )
	\ close captures
	gmi:CaptureState @ case
		gmi:CAPTURE-PREFORMATTED of
			gmi:LineBuffer gmi:LineLen @ gmi:preformatted? if
				html:preformatted/close
				gmi:CAPTURE-NONE gmi:CaptureState !
				exit
			else
				gmi:LineBuffer gmi:LineLen @ html:type-escaped cr
				exit
			endif
		endof
		gmi:CAPTURE-LIST of
			gmi:LineBuffer gmi:LineLen @ gmi:list-item? invert if
				html:list/close
				gmi:CAPTURE-NONE gmi:CaptureState !
			endif
		endof
		gmi:CAPTURE-BLOCKQUOTE of
			gmi:LineBuffer gmi:LineLen @ gmi:blockquote? invert if
				html:blockquote/close
				gmi:CAPTURE-NONE gmi:CaptureState !
			endif
		endof
	endcase

	\ === Capturing === \

	\ preformatted block
	gmi:LineBuffer gmi:LineLen @ gmi:preformatted? if
		gmi:CAPTURE-PREFORMATTED gmi:CaptureState !
		gmi:LineBuffer gmi:LineLen @ '` skip
		html:preformatted/open
		exit
	endif

	\ open blockquote
	html:MultilineBlockquote if
		gmi:LineBuffer gmi:LineLen @ gmi:blockquote? if
			gmi:CaptureState @ gmi:CAPTURE-BLOCKQUOTE <> if
				html:blockquote/open
				gmi:CAPTURE-BLOCKQUOTE gmi:CaptureState !
			endif
			html:paragraph/open
			gmi:LineBuffer gmi:LineLen @
			'>' skip ch:SPACE skip ch:TAB skip
			html:type-escaped
			html:paragraph/close
			exit
		endif
	endif

	\ list-item
	gmi:LineBuffer gmi:LineLen @ gmi:list-item? if
		gmi:CaptureState @ gmi:CAPTURE-LIST <> if
			html:list/open
			gmi:CAPTURE-LIST gmi:CaptureState !
		endif
		gmi:LineBuffer 1 + gmi:LineLen @ 1 - html:list-item cr
		exit
	endif

	\ === Non-Capturing === \

	\ blockquote
	gmi:LineBuffer gmi:LineLen @ gmi:blockquote? if
		gmi:LineBuffer gmi:LineLen @
		'>' skip ch:SPACE skip ch:TAB skip
		html:blockquote
		exit
	endif

	\ heading
	gmi:LineBuffer gmi:LineLen @ gmi:heading? dup if
		gmi:LineBuffer gmi:LineLen @ '# skip ch:SPACE skip ch:TAB skip html:heading cr
		exit
	endif drop

	\ link
	gmi:LineBuffer gmi:LineLen @ gmi:link? if
		gmi:LineBuffer gmi:LineLen @ '= skip '> skip ch:SPACE skip ch:TAB skip ( c-addr len )

		\ find end of URL
		2dup ch:SPACE scan ( c-addr len label-addr label-len )
		>r dup >r 2 pick - swap drop ( c-addr url-len )
		r> r> ch:SPACE skip ch:TAB skip ( c-addr url-len label-addr label-len )
		dup 0 = if \ use the URL for the label if no label is provided
			2drop 2dup
		endif
		
		2swap ( c-addr label-len c-addr url-len )
		2dup image-extension? if
			html:image
		else 2dup video-extension? if
			html:video
		else 2dup audio-extension? if
			html:audio
		else
			html:link
		endif endif endif
		exit
	endif

	\ line break
	gmi:LineLen @ 0 = if
		html:LinebreakEmpty if
			html:line-break cr
		endif
	else
	\ paragraph
		html:paragraph/open
		gmi:LineBuffer gmi:LineLen @ html:type-escaped
		html:paragraph/close cr
	endif
	;

: gmi:process-input ( fd-in -- )
	0 gmi:LineNumber !
	begin
		1 gmi:LineNumber +!
		dup gmi:LineBuffer gmi:LINE-BUFFER-SIZE rot read-line ( in-fd len flag err )
		throw
		invert if drop drop exit endif  \ false flag == eof
		gmi:LineLen !
		gmi:process-line
	again
	drop ;

: gmi:to-html ( fd-in fd-out -- )
	dup >r
	['] gmi:process-input swap ( fd-in xt fd-out )
		outfile-execute ( )
	['] gmi:close-capture r> ( xt fd-out )
		outfile-execute ( )
	;

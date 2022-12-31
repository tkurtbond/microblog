#! /usr/bin/env gforth

require ./util.fs

800 value lichen:ImageMaxWidthResize \ Uploaded images larger than this will be offered to resize down to this width

: index-redirect
	REQUEST_URI 1 - + c@ '/' = if
		." Status: 301 Moved Permanently" cr
		." Location: "
		REQUEST_URI type
		s" index.gmi" type
		cr cr
		bye
	endif ;

: bare-redirect
	REQUEST_URI SCRIPT_NAME str= if
		." Status: 301 Moved Permanently" cr
		." Location: " 
		SCRIPT_NAME type
		s" /" type
		cr cr
		bye
	endif ;

bare-redirect
index-redirect



: render-editor-content
	PATH_INFO lichen:content-path r/o open-file case
		ERROR:DOES-NOT-EXIST of
			drop \ print nothing
		endof
		0 of
			print-file
		endof
		1 throw \ TODO: better handling of error code
	endcase ;

: string-suffix? ( c-addr1 u1 c-addr2 u2 -- f )
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

: skip-file? ( c-addr u-len -- f )
	2dup s" ." str= >r
	2dup s" .." str= r> or >r
	2dup s" .git" str= r> or >r
	2dup s" cgi-bin" str= r> or >r
	2dup s" template" str= r> or >r
	2dup s" ." string-prefix? r> or >r
	2dup s" .sh" string-suffix? r> or >r
	     s" .html" string-suffix? r> or ;


1024 constant filename-buf-size
create filename-buf filename-buf-size allot

: traverse-dir ( w-dir -- )
	." ["
	begin
		dup
		filename-buf filename-buf-size rot
		read-dir throw ( dir u-len flag )
	while
		filename-buf swap ( dir buf u-len )
		2dup skip-file? if
			2drop 
		else ( dir buf u-len )
			2dup set-dir if
				\ set-dir failed, it's a file
				.\" {name: \"" type .\" \"},"
			else
				\ otherwise, it's a directory
				.\" {name: \"" type .\" \", children: "
				
				s" ." open-dir throw
				dup recurse
			 	close-dir throw
			 	s" ../" set-dir throw

			 	." },"
			endif
		endif
	repeat drop drop
	." ]" cr ;

: render-files-data
	s" ../" set-dir throw \ get out of cgi-bin
	s" ." open-dir throw ( w-dir )
	dup traverse-dir
	close-dir throw ;

." Content-Type: text/html" cr
cr

.( <!DOCTYPE html> )
.( <html> )
.( <head> )
	.( <meta charset="utf-8"> )
	.( <title>)
		PATH_INFO basename type
	.(  | Lichen</title> )
	.( <style> )
		s" ./static/stylesheet.css" print-asset
	.( </style> )
	.( <script defer> )
		s" ./static/main.js" print-asset
	.( </script> )
.( </head> )
.( <body data-path-info=") PATH_INFO type .( " data-script-name=") SCRIPT_NAME type .( " data-image-max-width=" ) lichen:ImageMaxWidthResize . .( "> )
	.( <div class="container"> )
		.( <div class="panel" id="panel_editor">
			.( <textarea id="content" autocomplete="off" spellcheck="false">)
				render-editor-content
			.( </textarea> )

			.( <div id="help" class="hidden"> )
				.( <code># heading<br>## subhead<br>### sub-subhead</code> )
				.( <code>* bulleted<br>* list<br>* items</code> )
				.( <code>=> https://example.com external link<br>=> /page.gmi internal link<br>=&gt; /image.jpg description</code> )
				.( <code>```<br>preformatted<br>```</code><br> )
				.( <div> )
					.( <code>&gt; blockquote</code> )
					.( <div>&nbsp;</div> )
					.( <a href="https://gemini.circumlunar.space/docs/cheatsheet.gmi" target="_blank">cheatsheet</a> )
				.( </div> )
			.( </div> )


			.( <div class="controls"> )
				.( <button id="toggle-files">🗄️ Files</button> )
				.( <button id="toggle-help">ℹ️ Help</button> )
				.( <span style="flex-grow: 1;"></span> )
				.( <button id="save" disabled>Save</button> )
			.( </div> )
		.( </div> )

		.( <div class="panel hidden" id="panel_files"> )
			.( <script> )
				.( window.lichenFilesystem = ) render-files-data .( ; )
			.( </script> )
			.( <nav id="files" style="flex-grow: 1;"><ol></ol></nav> )

			.( <div class="controls">
				.( <button id="toggle-editor">📝 Editor</button> )
				.( <span style="flex-grow: 1;"></span> )
			.( </div> )

			.( <div class="overlay hidden" id="upload-overlay"> )
				.( <p>Uploading<span class="throb">…</span></p> )
			.( </div> )
		.( </div> )

		.( <div id="preview-container"> )
			.( <div id="nav-warning" style="display: none;"> )
				.( <span>⚠️</span> )
				.( <div style="flex-grow: 1;"> )
					.( <h4>Warning!</h4> )
					.( <p>It appears you have navigated away from the page you are currently editing.</p> )
				.( </div> )
				.( <button id="nav-return" style="white-space: nowrap;">⬅️ Return</button> )
			.( </div> )
			.( <iframe id="preview" referrerpolicy="no-referrer"></iframe> )
		.( </div> )
	.( </div> )
	.( <input type="file" id="upload" class="hidden"> )

	.( <template id="tmpl_file"> )
		.( <li class="file"> )
			.( <a href="" class="link"></a> ) \ link--editable / link--unknown + target _blank
			.( <div class="actions"> )
				.( <button class="action_insert-link" title="Insert Link">🔗</button> )
				.( <button class="action_file-delete" title="Delete">❌</button> )
			.( </div> )
		.( </li> )
	.( </template> )

	.( <template id="tmpl_dir"> )
		.( <li class="directory"><details> )
			.( <summary> )
				.( <span class="directory__title"></span> )
				.( <div class="actions"> )
					.( <button class="action_new-page" title="New Page">+ 📄</button> )
					.( <button class="action_dir-create" title="New Folder">+ 📁</button> )
					.( <button class="action_upload" title="Upload">Upload</button> )
					.( <button class="action_dir-delete" title="Delete">❌</button> )
				.( </div> )
			.( </summary> )
			.( <ol></ol> )
		.( </details></li> )
	.( </template> )
.( </body> )
.( </html> )

bye


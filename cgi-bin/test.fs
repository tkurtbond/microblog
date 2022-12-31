require ./gmi.fs

\ TODO: assert stack depth?

: test-gmi
	
	assert(
		s" <open></close>" s" </close>" string-suffix?
	)

	assert(
		s" <a><b>" s" bogus" string-suffix?
		false =
	)

	assert(
		s" end" s" begin-end" string-suffix?
		false =
	)

	assert(
		s" # one" gmi:heading?
		1 =
	)

	assert(
		s" ## two" gmi:heading?
		2 =
	)

	assert(
		s" ### three" gmi:heading?
		3 =
	)

	assert(
		s" #### four (invalid)" gmi:heading?
		3 =
	)

	assert(
		s" non-heading" gmi:heading?
		0 =
	)

	assert(
		s" *bad list item" gmi:list-item?
		false =
	)

	assert(
		s" * good list item" gmi:list-item?
	)

	assert(
		s" ```label" gmi:preformatted?
	)

	assert(
		s" >quote" gmi:blockquote?
	)

	assert(
		s" => url" gmi:link?
	)
;

test-gmi
bye
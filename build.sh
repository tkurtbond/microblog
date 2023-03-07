#!/bin/sh

set -e

cd cgi-bin # forth code assumes CWD is 'cgi-bin'

for src in $(find ../gmi -type f -name '*.gmi'); do
	target="$(dirname $src)/$(basename $src .gmi).html"
        if [[ $src -nt $target ]]; then
                echo Building $target
	        cat $src | gforth render.fs -e 'stdin stdout lichen:render bye' > $target
        fi
done

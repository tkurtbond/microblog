#!/bin/sh

if [ $PATH_INFO = '/.git' -o $PATH_INFO = '/cgi-bin' -o $PATH_INFO = '/template' ]; then
	echo 'Status: 400 Bad Request'
	echo 'Content-Type: text/plain'
	echo ''
	echo "Don't delete important directories!"
	exit 1
fi


# if it ends in .gmi, remove associated HTML file
echo "$PATH_INFO" | grep -qE '\.gmi$'
if [ $? -eq 0 -a -f "..$PATH_INFO" ]; then
	rm -rf "../$(dirname $PATH_INFO)/$(basename $PATH_INFO '.gmi').html"
fi
rm -rf "..$PATH_INFO"

echo 'Status: 204 No Content'
echo ''

#!/bin/sh

set -e

# replace spaces with underscores
sanitized=$(echo $PATH_INFO | tr -s ' ' '_')

if [ -f ..$sanitized ]; then
	cat /dev/stdin > /dev/null
	echo 'Status: 409 Conflict'
	echo 'Content-Type: text/plain'
	echo ''
	echo 'File already exists.'
	exit 0
fi

mkdir -p ..$(dirname $sanitized)
cat /dev/stdin > ..$sanitized

echo 'Status: 204 No Content'
echo "X-File-Name: $(basename $sanitized)"
echo "X-File-Path: $(dirname $sanitized)"
echo ''

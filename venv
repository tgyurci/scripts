#!/bin/sh

# Load virtualenv in a subshell

set -eu

dir="$1"
shift

if ! [ -d "$dir" ]; then
	echo "No such dir: $dir"
	exit 1
fi

activate_file="$dir/bin/activate"

if ! [ -f "$activate_file" ]; then
	echo "No such file: $activate_file"
	exit 1
fi

. "$activate_file"

if [ "$#" -gt 0 ]; then
	exec "$@"
else
	exec "$SHELL"
fi

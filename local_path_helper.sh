#!/bin/sh

# path_helper for ~/.paths and ~/.paths.d/*

set -eu

path_before=""
path_after=""

if [ "true" = "${DEBUG:-""}" ]; then
	debug() {
		echo "$@" >&2
	}
else
	debug() {
		:
	}
fi

read_paths() {
	local path_file; path_file="$1"
	local path_element
	local append_after="no"

	if [ -f "$path_file" ]; then
		debug "Reading path file: $path_file"

		while read path_element; do
			case "$path_element" in
				\#*|"") continue ;;
				--) append_after="yes"; debug "Got -- now appending"; continue ;;
				/*) ;;
				*) path_element="$HOME/$path_element"
			esac

			case ":${path_before}${PATH}${path_after}:" in
				*:"$path_element":*) debug "Skpping already present path element: $path_element"; continue ;;
			esac

			if [ "yes" = "$append_after" ]; then
				debug "Appending path element to PATH: $path_element"
				path_after="${path_after}:${path_element}"
			else
				debug "Prepending path element to PATH: $path_element"
				path_before="${path_before}${path_element}:"
			fi
		done < "$path_file"
	fi
}

: ${BASEDIR:="$HOME"}

read_paths "$BASEDIR/.paths"

for path_file in $BASEDIR/.paths.d/*; do
	read_paths "$path_file"
done

printf "PATH=\"%s\"; export PATH;\n" "${path_before}${PATH}${path_after}"

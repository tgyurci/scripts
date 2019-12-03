#!/bin/sh

# Outputs HTTP Basic auth data
# Usage: http_basic_auth.sh username password

set -eu

user="$1"
pass="$2"

printf "%s:%s" "$user" "$pass" | openssl base64 -e -A

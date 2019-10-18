#!/bin/sh

# Outputs PLAIN SASL auth data
# Usage: sasl_plain_auth.sh username password

set -eu

user="$1"
pass="$2"

printf "%s\0%s\0%s" "$user" "$user" "$pass"

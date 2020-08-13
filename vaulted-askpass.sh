#!/bin/sh

#
# vaulted-askpass.sh - askpass to use with vaulted for providing passwords and MFA secrets
# automatically.
#
# Dependenties: pass, oath-toolkit
#

set -e

err() {
	echo "$@" >&2
	exit 1
}

[ -n "$VAULTED_ENV" ] || err "\$VAULTED_ENV is empty"

: "${VAULTED_PASS_PATH:="vaulted"}"

case "$VAULTED_PASSWORD_TYPE" in
	*password*)
		pass show "$VAULTED_PASS_PATH/$VAULTED_ENV" | awk 'NR == 1 { print $0; exit }'
		;;
	mfatoken)
		oathtool --totp --base32 "$(pass show "$VAULTED_PASS_PATH/$VAULTED_ENV" | awk '/^TOTP-Secret: / { print $2 }')"
		;;
	*)
		err "Unknown password type: \"$VAULTED_PASSWORD_TYPE\""
		;;
esac

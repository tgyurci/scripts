#!/bin/sh

# Loads AWS credentials and caches them locally until it's expiration

set -eu

debug_msg() {
	if [ "${DEBUG:-}" = true ]; then
		echo "$@" >&2
	fi
}

info_msg() {
	echo "$@" >&2
}

get_pass_field() {
	local field passdata
	field="$1"
	passdata="$2"

	printf "%s\n" "$passdata" | awk "/^${field}: / { print \$2 }"
}

aws_account="$1"

cache_dir="${XDG_CACHE_DIR:-"$HOME/.cache"}/aws-session"

cache_filename="$(printf "%s" $aws_account | tr '/' '_')_creds"
cache_file="${cache_dir}/${cache_filename}"

cache_expiration_filename="${cache_filename}_expiration"
cache_expiration_file="${cache_dir}/${cache_expiration_filename}"

if [ -f "$cache_file" ]; then
	debug_msg "Cache file ($cache_file) exists, trying to load"

	if [ -f "$cache_expiration_file" ]; then
		debug_msg "Cache expiration file ($cache_expiration_file) exists, checking expiration"

		cache_expiration="$(cat "$cache_expiration_file")"
		now="$(date +%s)"

		if [ "$now" -lt "$cache_expiration" ]; then
			debug_msg "Cache will expire at: $cache_expiration now: $now"

			#aws_creds="$(gpg --quiet --decrypt "$cache_file")"
			aws_creds="$(cat "$cache_file")"
		else
			debug_msg "Cache expired at: $cache_expiration (now: $now), refreshing"
			info_msg "Refreshing cached credentials for: $aws_account"

			rm -f "$cache_file" "$cache_expiration_file"

			aws_creds=""
		fi
	else
		debug_msg "Cache expiration file ($cache_expiration_file) does not exist, now expiration checking was performed"

		#aws_creds="$(gpg --quiet --decrypt "$cache_file")"
		aws_creds="$(cat "$cache_file")"
	fi
else
	debug_msg "Cache file ($cache_file) does not exist"
	info_msg "Loading credentials for: $aws_account"

	aws_creds=""
fi

if [ -z "$aws_creds" ]; then
	debug_msg "Getting new AWS credentials for account: $aws_account"

	pass_entry="AWS/$aws_account"

	passdata="$(pass show "$pass_entry")"

	pass_aws_access_key_id="$(get_pass_field "AWS-Access-Key-Id" "$passdata")"
	pass_aws_secret_access_key="$(get_pass_field "AWS-Secret-Access-Key" "$passdata")"
	pass_mfa_serial="$(get_pass_field "AWS-MFA-Serial" "$passdata")"
	pass_mfa_token="$(PASSWORD_STORE_ENABLE_EXTENSIONS=true pass otp "$pass_entry")"

	read -r aws_session_access_key_id aws_session_secret_access_key aws_session_token aws_session_expiration <<EOI
$(
	AWS_ACCESS_KEY_ID="$pass_aws_access_key_id" \
	AWS_SECRET_ACCESS_KEY="$pass_aws_secret_access_key" \
	AWS_SECURITY_TOKEN="" AWS_SESSION_TOKEN="" \
	AWS_CREDENTIAL_EXPIRATION="" \
	aws sts get-session-token \
		--duration-seconds 900 \
		${pass_mfa_serial:+"--serial-number" "$pass_mfa_serial"} \
		${pass_mfa_token:+"--token-code" "$pass_mfa_token"} \
		--query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken,Expiration]" \
		--output text
)
EOI

	#aws_creds="AWS_ACCESS_KEY_ID="$aws_session_access_key_id"; export AWS_ACCESS_KEY_ID
#AWS_SECRET_ACCESS_KEY="$aws_session_secret_access_key"; export AWS_SECRET_ACCESS_KEY
#AWS_SECURITY_TOKEN="$aws_session_token"; export AWS_SECURITY_TOKEN
#AWS_SESSION_TOKEN="$aws_session_token"; export AWS_SESSION_TOKEN
#AWS_SESSION_EXPIRATION="$aws_session_expiration"; export AWS_SESSION_EXPIRATION"

	aws_creds="{
  \"Version\": 1,
  \"AccessKeyId\": \"$aws_session_access_key_id\",
  \"SecretAccessKey\": \"$aws_session_secret_access_key\",
  \"SessionToken\": \"$aws_session_token\", 
  \"Expiration\": \"$aws_session_expiration\"
}"

	debug_msg "Caching credentials to: $cache_file"
	mkdir -p -m 700 "$cache_dir"
	#printf "%s" "$aws_creds" | gpg --quiet --encrypt --armor > "$cache_file"
	printf "%s" "$aws_creds" > "$cache_file"

	aws_creds_expiration="$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%SZ" "$aws_session_expiration" +%s)"
	debug_msg "Credentials will expire at: $aws_creds_expiration"
	printf "%s" "$aws_creds_expiration" > "$cache_expiration_file"
fi

echo "$aws_creds"

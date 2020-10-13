#!/bin/sh

set -eu

debug_msg() {
	if [ "${DEBUG:-}" = true ]; then
		echo "$@" >&2
	fi
}

info_msg() {
	echo "$@" >&2
}

if [ "$#" -lt 1 ]; then
	echo "Usage: $0 region/cluster-name [role]" >&2
	exit 1
fi

region="${1%/*}"
cluster_name="${1#*/}"

if [ -z "$region" ] || [ -z "$cluster_name" ]; then
	echo "Usage: $0 region/cluster-name [role]" >&2
	exit 1
fi

if [ "$#" -gt 1 ]; then 
	role="$2"
fi

cache_dir="${XDG_CACHE_DIR:-"$HOME/.cache"}/aws-eks-token"

cache_filename="${region}_${cluster_name}_token"
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

			eks_token="$(cat "$cache_file")"
		else
			debug_msg "Cache expired at: $cache_expiration (now: $now), refreshing"
			info_msg "Refreshing cached credentials for: ${region}/${cluster_name}"

			rm -f "$cache_file" "$cache_expiration_file"

			eks_token=""
		fi
	else
		debug_msg "Cache expiration file ($cache_expiration_file) does not exist, now expiration checking was performed"

		eks_token="$(cat "$cache_file")"
	fi
else
	debug_msg "Cache file ($cache_file) does not exist"

	eks_token=""
fi

if [ -z "$eks_token" ]; then
	info_msg "Loading credentials for: ${region}/${cluster_name}"

	eks_token="$(aws ${region:+--region $region} eks get-token --cluster-name "$cluster_name" ${role:+--role $role})"

	debug_msg "Caching credentials to: $cache_file"
	mkdir -p -m 700 "$cache_dir"
	printf "%s" "$eks_token" > "$cache_file"

	eks_token_expiration="$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%SZ" $(echo "$eks_token" | jq -r '.status.expirationTimestamp') +%s)"
	debug_msg "Credentials will expire at: $eks_token_expiration"
	printf "%s" "$eks_token_expiration" > "$cache_expiration_file"
fi

echo "$eks_token"

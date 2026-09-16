#!/usr/bin/env bash

# avoid multiple sourcing
	[[ -n "${_HTTP_LOADED:-}" ]] && return 0		# if var is not empty, then return (close the current source of lib)
	_HTTP_LOADED=1 									# if its empty, continue sourcing, and set var to 1

required_commands timeout

# functions are derived from : Alexander Epstein https://github.com/alexanderepstein

http_get_client()   # determines http get tool
{
  unset http_client
  declare -g http_client
  if command -v curl &>/dev/null; then
		http_client="curl"
  elif command -v wget &>/dev/null; then
		http_client="wget"
  elif command -v http &>/dev/null; then
		http_client="httpie"
  elif command -v fetch &>/dev/null; then
		http_client="fetch"
  else
		log_error "no http_get tool installed - this script requires either curl, wget, httpie or fetch to be installed." >&2
		return 1
  fi
}

http_get()			   # call the users configured client
{
	local -a headers=()
	local -a request_args=()
	local header

	# Preserve the existing URL-only interface while allowing callers to send
	# headers without exposing client-specific command details.
	while (( $# > 0 )); do
		case "$1" in
			--header)
				(( $# >= 2 )) || {
					log_error "http_get - --header requires a value" >&2
					return 2
				}
				headers+=("$2")
				shift 2
				;;
			*)
				request_args+=("$1")
				shift
				;;
		esac
	done

	# Get client if empty, else just use client.
	# The client is detected once and reused for later requests.
	if [[ -z "${http_client:-}" ]]; then
		http_get_client || return 1
	fi

	case "$http_client" in
		curl)
			local -a curl_args=( -A curl -sS --max-time 10 --connect-timeout 5 )
			for header in "${headers[@]}"; do curl_args+=( -H "$header" ); done
			curl "${curl_args[@]}" "${request_args[@]}"
			;;
		wget)
			local -a wget_args=( -qO- )
			for header in "${headers[@]}"; do wget_args+=( "--header=$header" ); done
			wget "${wget_args[@]}" "${request_args[@]}"
			;;
		httpie)
			local -a httpie_args=( --body --check-status GET )
			httpie_args+=( "${request_args[@]}" )
			for header in "${headers[@]}"; do httpie_args+=( "$header" ); done
			http "${httpie_args[@]}"
			;;
		fetch)
			local -a fetch_args=( -q )
			for header in "${headers[@]}"; do fetch_args+=( -H "$header" ); done
			fetch "${fetch_args[@]}" "${request_args[@]}"
			;;
	esac
}

check_internet()
{
	# My VPN blocks ping, so this is a good way to simulate a broken internet without being broken
  # ping -c 1 -W 3 8.8.8.8 > /dev/null 2>&1 || { clearscreen; log_error "no active internet connection" >&2; return 1; }
  
	# TCP connection to Google DNS (port 53) instead of ping
	# VPNs commonly block ICMP packets, making ping unreliable
	# TCP handshake achieves the same connectivity check without ICMP and MUCH faster than a curl
  timeout 3 bash -c 'echo > /dev/tcp/8.8.8.8/53' 2>/dev/null || { clearscreen; log_error "no active internet connection" >&2; return 1; }
}

url_encode()
{
	jq -rn --arg jqvar "${1:-}" '$jqvar|@uri'
}

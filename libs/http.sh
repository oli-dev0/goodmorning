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
		exit 1
  fi
}

http_get()			   # call the users configured client
{
  # Get client if empty, else just use client
  # You don't need to get client inside a script everytime
  # just use http_get when needed
	if [[ -z "${http_client:-}" ]]; then
		http_get_client || return 1
	fi
	
  case "$http_client" in
	curl)  curl -A curl -s --max-time 10 --connect-timeout 5 "$@" ;;
	wget)  wget -qO- "$@" ;;
	httpie) http --body --check-status GET "$@" ;;
	fetch) fetch -q "$@" ;;
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

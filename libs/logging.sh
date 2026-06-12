#!/usr/bin/env bash

# avoid multiple sourcing
	[[ -n "${_LOG_LOADED:-}" ]] && return 0		# if var is not empty, then return (close the current source of lib)
	_LOG_LOADED=1 								# if its empty, continue sourcing, and set var to 1

log_start()
{
	local msg=${1:-Starting...}
	printf '%s\n\n' "${BOLD} 🟢 ${msg} ${RESET}"
}

log_success()
{
	local msg=${1:-Success!}
	printf '%s\n\n' "${SUCCESS} ✅ ${msg} ${RESET}"
}

log_warning()
{
	local msg=${1:-unknown}	
	printf '%s\n\n' "${WARNING} ⚠️ Warning: ${msg} ${RESET}"
}

log_error()
{
	local msg=${1:-unknown error}
	printf '%s\n\n' "${ERROR} ❌ Error:${RESET}${ERRORTEXT} ${msg} ${RESET}"
}
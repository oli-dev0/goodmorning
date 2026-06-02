#!/usr/bin/env bash

# AVOID MULTIPLE SOURCING
	[[ -n "${_BOOTSTRAP_LOADED:-}" ]] && return 0		# if var is not empty, then return (close the current "source" of lib)
	_BOOTSTRAP_LOADED=1 								# if its empty, continue sourcing, and set var to 1

# STRICT MODE
# -E = inherit ERR traps inside functions/subshells
# -e = exit immediately if a command fails
# -u = treat unset variables as errors
# -o pipefail = fail pipeline if any command fails
set -Eeuo pipefail

# MINIMAL ERROR HANDLING TO CATCH ISSUES IN config.sh
	minimal_trap_error()
	{
		local line="$1"
		local cmd="$2"

		printf 'Error: script failed at line %s\n' "$line" >&2
		printf 'Command: %s\n' "$cmd" >&2
		exit 1
	}

	trap 'minimal_trap_error ${LINENO} "$BASH_COMMAND"' ERR
	trap 'stty echo icanon 2>/dev/null || true' EXIT TERM
	trap 'stty echo icanon 2>/dev/null || true; clear; exit 130' INT

# LOAD CONFIG
	GM_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
	source "$GM_ROOT_DIR/config.sh"
	load_libs styles						# must load styles here for trap errors below
											# also good to load by default, need everywhere

# ERROR HANDLING
	trap 'show_keyboard; clear; exit 130' INT 			# need to show keyboard because some animations 
	trap 'show_keyboard' EXIT TERM 						# sometimes can keep hide_keyboard active
	trap 'trap_error ${LINENO} "$BASH_COMMAND"' ERR


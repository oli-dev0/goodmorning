#!/usr/bin/env bash

# AVOID MULTIPLE SOURCING
	[[ -n "${_BOOTSTRAP_LOADED:-}" ]] && return 0		# if var is not empty, then return (close the current "source" of lib)
	_BOOTSTRAP_LOADED=1 								# if its empty, continue sourcing, and set var to 1

# STRICT MODE
# -E = inherit ERR traps inside functions/subshells
# -e = exit immediately if a command fails
# -u = treat unset variables as errors
# -o pipefail = fail pipeline if any command fails

# ERROR HANDLING
	set -Eeuo pipefail
	trap 'show_keyboard; clear; exit 130' INT 			# need to show keyboard because some animations 
	trap 'show_keyboard' EXIT TERM 						# sometimes can keep hide_keyboard active
	trap 'trap_error ${LINENO} "$BASH_COMMAND"' ERR

# LOAD CONFIG
	GM_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
	source "$GM_ROOT_DIR/config.sh"
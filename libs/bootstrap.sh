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

	minimal_cleanup()
	{
		stty echo icanon 2>/dev/null || true
		tput cnorm 2>/dev/null || true
	}	

	trap 'minimal_trap_error "$LINENO" "$BASH_COMMAND"' ERR
	trap 'minimal_cleanup' EXIT 
	trap 'minimal_cleanup; exit 143' TERM
	trap 'minimal_cleanup; clear; exit 130' INT

# LOAD CONFIG AND CORE LIBS
	GM_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
	source "$GM_ROOT_DIR/config.sh"
	source "$GM_LIBS_DIR/tools.sh"
	load_libs styles						# must load styles here for trap errors below
											# also good to load by default, need everywhere

# ERROR HANDLING
	cleanup()
	{
		show_keyboard 2>/dev/null || true
		show_cursor 2>/dev/null || true
	}
	trap 'trap_error "$LINENO" "$BASH_COMMAND"' ERR
	trap 'cleanup' EXIT 
	trap 'cleanup; exit 143' TERM
	trap 'cleanup; clear; exit 130' INT


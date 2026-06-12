#!/usr/bin/env bash

# AVOID MULTIPLE SOURCING
	[[ -n "${_CORE_LOADED:-}" ]] && return 0		# if var is not empty, then return (close the current source of lib)
	_CORE_LOADED=1 															# if its empty, continue sourcing, and set var to 1

GM_CURRENT_TITLE=""				# reset title when loading tools

load_libs()
{
	local lib
	for lib in "$@"; do	source "$GM_LIBS_DIR/$lib.sh"; done
}

required_commands()
{
    local cmd

    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || {
            echo
            log_error "missing dependency: '$cmd' => please install '$cmd' to use this script."
            exit 1
        }
    done
}

trap_error()			# standard message for trap errors
{
	local line="${1:-unknown}"
	local cmd="${2:-unknown}"

	log_error "Trap error
 Script failed at line: $line and ${LINENO}
 From commands: $cmd AND/OR $BASH_COMMAND
 Script path: ${BASH_SOURCE[0]##*/} > ${BASH_SOURCE[1]##*/}"
	move_line_up 4; 					# I am doing this because I want to log the error, but not show it in that format
	printf '%s' "${ERROR}"
	printf '    ❌ Script failed at line: %s and %s\n' "$line" "${LINENO}"
	printf '    ❌ From commands: \n'
	printf '         ➡️  %s\n' "$cmd"
	printf '         ➡️  %s\n' "$BASH_COMMAND"
	printf '    📁 Script path: %s > %s\n' "${BASH_SOURCE[0]##*/}" "${BASH_SOURCE[1]##*/}"
	printf '%s\n' "${RESET}"
	exit 1
}

set_title()
{
	GM_CURRENT_TITLE="${1:?missing title}"
	printf '\033]0;%s\007' "$GM_CURRENT_TITLE"
	clearscreen
}

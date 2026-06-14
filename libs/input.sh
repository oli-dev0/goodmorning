#!/usr/bin/env bash

# avoid multiple sourcing
	[[ -n "${_INPUT_LOADED:-}" ]] && return 0		# if var is not empty, then return (close the current source of lib)
	_INPUT_LOADED=1 								# if its empty, continue sourcing, and set var to 1

ask_yes_no()
{
	local prompt=${1:-Do you want to continue? [y/n]}
	local answer

	while true; do
		read -rp " ${BOLD}${prompt}${RESET} [y/n] " answer
		answer="${answer,,}"

		case "$answer" in
			y|ye|yes|ok|k|"")
				return 0
				;;
			n|no|nop|nope)
				return 1
				;;
			*)
				clearscreen
				printf " %s\n\n" "$GM_MSG_INVALID_INPUT"
				;;
		esac
	done
}

ask_yes_no_dialog() 
{
	local question="${1:-Do you want to proceed? }"
	local height="${2:-0}"
	local width="${3:-0}"

	hide_cursor

	dialog --yesno "  $question" "$height" "$width"
	local result=$?

	clearscreen
	show_cursor
	
	return "$result"
}

ask_first()
{
	local qs="${1:-Do you want to proceed?}"
	
	if ! ask_yes_no "$qs"; then
		anim_moving_on
		clear
		exit 0
	fi
}

press_any_key()
{
	local msg=${1:-Press any key to continue...}

	hide_keyboard
	read -rn1 -p "${BLINK} $msg ${RESET}"; clearline
	show_keyboard
	anim_moving_on
	clear
}
#!/usr/bin/env bash

# avoid multiple sourcing
	[[ -n "${_TERMINAL_LOADED:-}" ]] && return 0		# if _terminal_loaded is not empty, then return (close the current source of lib)
	_TERMINAL_LOADED=1 															# if its empty, continue sourcing, and set _terminal_loaded to 1

# terminal manipulation functions
hide_cursor()
{
	tput civis
}

show_cursor()
{
	tput cnorm
}

hide_keyboard()		# disable keyboard input and display
{
  stty -echo -icanon
}

show_keyboard()		 # enable keyboard input and display
{
  stty echo icanon
}

flushread()			 # flush before reading
{
  # stty -icanon
  # while read -rt 0; do read -r -t 0.1; done
  # stty icanon
  while read -rt 0; do read -rn1; done
}

clearscreen()
{
	clear
	[[ -n "$GM_CURRENT_TITLE" ]] && printf '\n   %s %s  %s\n\n' "${TITLE}" "$GM_CURRENT_TITLE" "${RESET}"
}

move_line_up()
{
	local lines="${1:-1}"
	local i

	for ((i=0; i<lines; i++)); do
	  printf '\033[1A\033[2K\r'
	done
}

clearline()			 # goes to beginning and clears entired current line
{
  printf "\r\033[2K"
}
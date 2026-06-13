#!/usr/bin/env bash

# AVOID MULTIPLE SOURCING
	[[ -n "${_ANIM_LOADED:-}" ]] && return 0		# if var is not empty, then return (close the current "source" of lib)
	_ANIM_LOADED=1 															# if its empty, continue sourcing, and set var to 1

required_commands bc

# PRESETS
  # "Moving on" spinner
	anim_moving_on()
	{
	  animation_spinner "Moving on " 0.5
	}

  # Moving status bar
  anim_status_bar()
  {
  	local msg="${1:-Processing...}"

  	hide_keyboard
  	hide_cursor
  	echo -e " ${SUCCESS}$msg${RESET}"; echo -n " "
  	sleep 0.3
  	animation_reveal "▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪" 0.01 "${SUCCESS}"
  	printf "\n "
  }

# SPINNER - usage: animation_spinner "TEXT" 1.5 "${COLOR}"
  animation_spinner()
  {
	# ARGUMENTS
  	local msg="${1:- Processing...}"
  	local duration="${2:-1}"
  	local color="${3:-${WARNING}}"
	
	# SPIN SETTINGS
  	local spin='|/—\'
  	local spin_speed=0.035

	local iterations=$(( $(echo "$duration / $spin_speed" | bc) ))
	local i

	hide_keyboard
	hide_cursor
	printf "%s" "$color"

	for (( i=0; i<iterations; i++ )); do
	  printf "\r %s %s" "$msg" "${spin:i%4:1}   "
	  sleep "$spin_speed"
	done
	
	printf "%s" "${RESET}"  
	show_keyboard
	show_cursor
	echo
	flushread
  }

# TEXT REVEAL - usage: animation_reveal "TEXT" 0.05 "${COLOR}"
  animation_reveal() 
  {
  	local msg="${1:- Default text....}"
  	local delay="${2:-0.025}"
  	local color="${3:-${BOLD}}"
  	local i

  	hide_keyboard
  	hide_cursor
  	printf "%s" "$color"

  	for ((i=0; i<=${#msg}; i++)); do
  	  printf "%s" "${msg:i:1}"
  	  sleep "$delay"
  	done

  	printf "%s" "${RESET}"  
  	show_keyboard
  	show_cursor
  	flushread
  }

# COUNTDOWN - usage: anim_countdown "TEXT" 5 "${COLOR}"
  anim_countdown()
  {
  	local msg="${1:-Continue in}"
  	local seconds="${2:-3}"
  	local color="${3:-}"
  	local i

  	hide_keyboard
  	hide_cursor
  	printf "%s" "$color"

  	for (( i=seconds; i>=1; i-- )); do
  	  printf "\r %s %s " "$msg" "$i"
  	  sleep 0.6
  	done
  	
  	printf "%s" "${RESET}"  
  	sleep 0.1
  	flushread
  	clearline
  	show_keyboard
  	show_cursor
  }
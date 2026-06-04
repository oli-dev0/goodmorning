#!/usr/bin/env bash

# AVOID MULTIPLE SOURCING
	[[ -n "${_ANIM_LOADED:-}" ]] && return 0		# if var is not empty, then return (close the current "source" of lib)
	_ANIM_LOADED=1 															# if its empty, continue sourcing, and set var to 1

required_commands bc

# PRESETS
  # "Moving on" spinner
	anim_moving_on()
	{
	  hide_keyboard
	  animation_spinner "Moving on " 0.5 "${WARNING}"

	  show_keyboard
	  flushread
	}

  # Moving status bar
  anim_status_bar()
  {
  	local msg="${1:-Processing...}"

  	hide_keyboard
  	echo -e " ${SUCCESS}$msg${RESET}"; echo -n " "
  	sleep 0.3
  	animation_reveal "▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪" 0.015 "${SUCCESS}"
  	printf "\n "
  	show_keyboard
  	flushread
  }

# SPINNER
# USAGE: animation_spinner "TEXT" 1.5 "${COLOR}"
  animation_spinner()
  {
	# ARGUMENTS
  	local msg="${1:- Processing...}"
  	local duration="${2:-0.5}"
  	local color="${3:-${BOLD}}"
	
	# SPIN SETTINGS
  	local spin='|/—\'
  	local spin_speed=0.035

	local iterations=$(( $(echo "$duration / $spin_speed" | bc) ))
	local i=0

	hide_keyboard
	printf "%s" "$color"

	for (( i=0; i<iterations; i++ )); do
	  printf "\r %s %s" "$msg" "${spin:i%4:1}   "
	  sleep "$spin_speed"
	done
	
	printf "%s" "${RESET}"  
	show_keyboard
	echo
	flushread
  }

# TEXT REVEAL
# USAGE: animation_reveal "TEXT" 0.05 "${COLOR}"
  animation_reveal() 
  {
  	local msg="${1:- Default text....}"
  	local delay="${2:-0.025}"
  	local color="${3:-${BOLD}}"

  	hide_keyboard
  	printf "%s" "$color"

  	for ((i=1; i<=${#msg}; i++)); do
  	  printf "%s" "${msg:i-1:1}"
  	  sleep "$delay"
  	done

  	printf "%s" "${RESET}"  
  	show_keyboard
  	flushread
  }

# COUNTDOWN
# USAGE: anim_countdown "TEXT" 5 "${COLOR}"
  anim_countdown()
  {
  	local msg="${1:-Continue in}"
  	local seconds="${2:-3}"
  	local color="${3:-}"

  	hide_keyboard
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
  }
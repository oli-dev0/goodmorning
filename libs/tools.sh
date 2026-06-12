#!/usr/bin/env bash

# AVOID MULTIPLE SOURCING
	[[ -n "${_TOOLS_LOADED:-}" ]] && return 0		# if _tools_loaded is not empty, then return (close the current source of lib)
	_TOOLS_LOADED=1 														# if its empty, continue sourcing, and set _tools_loaded to 1

exit_code=0 							# need to declare here or it's undeclared from run_module tool
GM_CURRENT_TITLE=""				# reset title when loading tools

# First 2 functions are derived from : Alexander Epstein https://github.com/alexanderepstein

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

flushread()			 # flush before reading
{
  # stty -icanon
  # while read -rt 0; do read -r -t 0.1; done
  # stty icanon
  while read -rt 0; do read -rn1; done
}

hide_keyboard()		# disable keyboard input and display
{
  stty -echo -icanon
}

show_keyboard()		 # enable keyboard input and display
{
  stty echo icanon
}

move_line_up()
{
	local lines="${1:-1}"

	for ((i=0; i<lines; i++)); do
	  printf '\033[1A\033[2K\r'
	done
}

clearline()			 # goes to beginning and clears entired current line
{
  printf "\r\033[2K"
}

# Parses one GM_MODULES entry (config.sh) and sets these globals:
  # GM_PARSED_MODULE_NAME
  # GM_PARSED_MODULE_DISPLAY
  # GM_PARSED_MODULE_DESCRIPTION
  # GM_PARSED_MODULE_SHORTCUTS
parse_module() {
	local entry="$1"
	local IFS='|'																					# sets | as delimiter, to split the module info in config.sh
	local fields

	read -ra fields <<< "$entry"													# read from array $entry

	GM_PARSED_MODULE_NAME="${fields[0]}"																	  				 # weather (first) - script name
	GM_PARSED_MODULE_DISPLAY="${fields[1]:-${GM_PARSED_MODULE_NAME}.sh}"						 # 🌤️  Weather (second) - question displayed
	GM_PARSED_MODULE_DESCRIPTION="${fields[2]:-Launch: ${GM_PARSED_MODULE_NAME}.sh}" # long gui description (third) - shown on the lower end of gui
	GM_PARSED_MODULE_SHORTCUTS=("${fields[@]:3}")																		 # everything after
}

validate_shortcuts()
{
	declare -A seen_shortcuts
	local shortcut

	for entry in "${GM_MODULES[@]}"; do parse_module "$entry"

		for shortcut in "${GM_PARSED_MODULE_SHORTCUTS[@]}"; do
			if [[ -n "${seen_shortcuts[$shortcut]:-}" ]]; then
				clearscreen
				log_error "duplicate shortcut '$shortcut' used by '$GM_PARSED_MODULE_NAME' and '${seen_shortcuts[$shortcut]}'"
				return 1
			fi
			seen_shortcuts[$shortcut]="$GM_PARSED_MODULE_NAME"
		done
	done
}

validate_modules()
{
	local entry

	for entry in "${GM_MODULES[@]}"; do
		parse_module "$entry"

		if [[ ! -f "$GM_MODULES_DIR/$GM_PARSED_MODULE_NAME.sh" ]]; then
			clearscreen
			log_error "configured module '$GM_PARSED_MODULE_NAME' does not exist at '$GM_MODULES_DIR/$GM_PARSED_MODULE_NAME.sh'"
			return 1
		fi
	done
}

run_module()
{
	local module="$1"
	local module_path="$GM_MODULES_DIR/$module.sh"
	local saved_title="$GM_CURRENT_TITLE"				# get previous title before running new script
	local exit_code=0
	
	[[ ! -f "$module_path" ]] && { clearscreen; log_error "module '$module' not found at '$module_path'" >&2; return 1; }

	bash "$module_path" || exit_code=$?		# get exit code of previous command 'bash'
	set_title "$saved_title"							# set both titles back to previous title
	return "$exit_code"										# return exit code from bash command or 0
}

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
				printf " %s\n\n" "$msg_invalid_input"
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
	hide_keyboard
	read -rn1 -p "${BLINK} Press any key to continue... ${RESET}"; clearline
	show_keyboard
	anim_moving_on
	clear
}

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

trap_error()			# standard message for trap errors
{
	local line="$1"
	local cmd="$2"

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
	GM_CURRENT_TITLE="$1"
	printf '\033]0;%s\007' "$GM_CURRENT_TITLE"
	clearscreen
}

clearscreen()
{
	clear
	[[ -n "$GM_CURRENT_TITLE" ]] && printf '\n   %s %s  %s\n\n' "${TITLE}" "$GM_CURRENT_TITLE" "${RESET}"
}

url_encode()
{
	jq -rn --arg jqvar "$1" '$jqvar|@uri'
}

hide_cursor()
{
	tput civis
}

show_cursor()
{
	tput cnorm
}
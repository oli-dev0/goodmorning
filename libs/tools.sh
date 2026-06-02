#!/usr/bin/env bash

# AVOID MULTIPLE SOURCING
	[[ -n "${_TOOLS_LOADED:-}" ]] && return 0		# if _tools_loaded is not empty, then return (close the current source of lib)
	_TOOLS_LOADED=1 														# if its empty, continue sourcing, and set _tools_loaded to 1

exit_code=0 							# need to declare here or it's undeclared from run_module tool
current_title=""					# reset title when loading tools

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
		log_error "this tool requires either curl, wget, httpie or fetch to be installed." >&2
		exit 1
  fi
}

http_get()			   # call the users configured client
{
  # Get client if empty, else just use client
  # You don't need to get client inside a script everytime
  # just use http_get when needed
	[[ -z "${http_client:-}" ]] && http_get_client || { log_error "no http_get tool installed"; return 1; }
	
  case "$http_client" in
	curl)  curl -A curl -s "$@" ;;
	wget)  wget -qO- "$@" ;;
	httpie) http --body --check-status GET "$@" ;;
	fetch) fetch -q "$@" ;;
  esac
}

check_internet()
{
    # My VPN blocks ping, so this is a good way to simulate a broken internet without being broken
  # ping -c 1 -W 3 8.8.8.8 > /dev/null 2>&1 || { clearscreen; error "no active internet connection" >&2; move_line_up; anim_countdown "  ⚠️  Closing in" "3" "${WARNING}"; exit 1; }
  
	# TCP connection to Google DNS (port 53) instead of ping
	# VPNs commonly block ICMP packets, making ping unreliable
	# TCP handshake achieves the same connectivity check without ICMP and MUCH faster than a curl
  bash -c 'echo > /dev/tcp/8.8.8.8/53' 2>/dev/null || { clearscreen; log_error "no active internet connection" >&2; move_line_up; anim_countdown "  ⚠️  Closing in" "3" "${WARNING}"; exit 1; }
}

load_libs()
{
	local lib
	for lib in "$@"; do
		source "$LIBS_DIR/$lib.sh"; done
}

required_commands()
{
    local cmd

    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || {
            echo
            log_error "missing dependency: $cmd => please install \"$cmd\" to use this script."
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
  printf "\033[1A\033[2K\r"
}

clearline()			 # goes to beginning and clears entired current line
{
  printf "\r\033[2K"
}

parse_module() {
	local entry="$1"
	local IFS='|'																					# sets | as delimiter, to split the module info in config.sh
	read -ra fields <<< "$entry"													# read from array $entry

	module_name="${fields[0]}"														# weather (first)
	module_question="${fields[-1]}"												# 🌤️  Weather (last)
	module_shortcuts=("${fields[@]:1:${#fields[@]}-2}")		# everything in between
}

validate_shortcuts()
{
	declare -A seen_shortcuts
	local shortcut

	for entry in "${MODULES[@]}"; do parse_module "$entry"

		for shortcut in "${module_shortcuts[@]}"; do
			if [[ -n "${seen_shortcuts[$shortcut]:-}" ]]; then
				log_error "duplicate shortcut '$shortcut' used by '$module_name' and '${seen_shortcuts[$shortcut]}'"
				return 1
			fi
			seen_shortcuts[$shortcut]="$module_name"
		done
	done
}

validate_modules()
{
	local entry

	for entry in "${MODULES[@]}"; do
		parse_module "$entry"

		if [[ ! -f "$MODULES_DIR/$module_name.sh" ]]; then
			log_error "configured module '$module_name' does not exist at $MODULES_DIR/$module_name.sh"
			return 1
		fi
	done
}

run_module()
{
	local module="$1"
	local module_path="$MODULES_DIR/$module.sh"
	local saved_title="$current_title"				# get previous title before running new script

	[[ ! -f "$module_path" ]] && { echo -ne "\n"; log_error "module '$module' not found at $module_path" >&2; return 1; }

	bash "$module_path"
	exit_code=$?											# get exit code of previous command 'bash'
	current_title="$saved_title"			# set title back to previous title
	clearscreen												# clear but keep title
	[[ $exit_code -ne 0 ]] && exit 1	# exit 1 if 'bash' command gave an error
	return 0													# this is needed for execute_shortcut to return correctly for the flow in main.sh
}

ask_yes_no()
{
	local prompt=${1:-Do you want to continue?}
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
	printf '\n%s\n' "${ERROR} ❌ Error:${RESET}${ERRORTEXT} ${msg} ${RESET}"
}

trap_error()			# standard message for trap errors
{
	local line="$1"
	local cmd="$2"

	log_error "Trap error
 Script failed at line: $line and ${LINENO}
 From commands: $cmd AND/OR $BASH_COMMAND
 Script path: ${BASH_SOURCE[0]##*/} > ${BASH_SOURCE[1]##*/}"
	move_line_up; move_line_up; move_line_up; move_line_up;			# I am doing this because I want to log the error, but not show it in that format
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
	current_title="$1"
}

clearscreen()
{
	clear
	[[ -n "$current_title" ]] && echo -e "\n   ${TITLE} $current_title  ${RESET}\n "
}

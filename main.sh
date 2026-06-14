#!/usr/bin/env bash
# version 2.0

# BOOTSTRAP
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	source "$SCRIPT_DIR/libs/bootstrap.sh"
	set_title "   ☀️  Good Morning   "
	validate_modules					# check that configured modules have a .sh file
	validate_shortcuts					# checking for duplicate module shortcuts in config.sh

# ASK MAIN QUESTIONS
ask_module_questions()		# checks the modules array in config.sh > sends it to parser to get script, shortcuts, question > go over all of them 
{
	for entry in "${GM_MODULES[@]}"; do
		parse_module "$entry"
		ask_qs "$GM_PARSED_MODULE_DISPLAY" "$GM_PARSED_MODULE_NAME"
	done
}

# EXTRA HIDDEN SHORTCUTS 			# checks if what user entered is a shortcut > these are set in config.sh
execute_shortcut()
{
	local answer="${1:-}"

	for entry in "${GM_MODULES[@]}"; do
		parse_module "$entry"

		for shortcut in "${GM_PARSED_MODULE_SHORTCUTS[@]}"; do
			if [[ "$answer" == "$shortcut" ]]; then
				run_module "$GM_PARSED_MODULE_NAME" || exit $?
				return 0
			fi
		done
	done

	return 1
	}

main_ask_yes_no()
{
	local answer="${1:-}"
	case "$answer" in
		y|ye|yes|ok|k|"")
			clearscreen
			;;
		n|no|nop|nope)
			close_app
			;;
		*)
			clearscreen
			echo -e "${GM_MSG_INVALID_INPUT}\n"
			return 1
			;;
	esac
}

ask_begin ()	# start of module
{
	echo -e "${GM_MSG_HELLO}\n"
	
	local answer
	while true; do
		read -rp "${GM_MSG_ASK_FIRST}" answer
		answer=${answer,,}
		execute_shortcut "$answer" && { ask_more; return; }
		main_ask_yes_no "$answer" && break
	done
}

ask_qs() 	# function to ask if user wants to run module
{
	local question="${1:?question is required}"		# set question from first argument
	local module="${2:?module is required}"			# set module name from second argument

	if ask_yes_no "${question}?"; then
		run_module "$module" || exit $?
	else
		anim_moving_on
		clearscreen
	fi
}

ask_more()					# triggers once all questions are asked or after a shortcut was used
{
	local answer

	while true; do
		read -rp "${GM_MSG_ASK_MORE}" answer
		answer=${answer,,}
		execute_shortcut "$answer" && continue
		main_ask_yes_no "$answer" && break
	done
}

main()
{
	ask_begin
	while true; do
		ask_module_questions
		if ! ask_more; then
			break
		fi
	done
}

# START APP
	main

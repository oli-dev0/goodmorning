#!/usr/bin/env bash

# CONFIG
	source "$(dirname "${BASH_SOURCE[0]}")/libs/bootstrap.sh"
	load_libs animations				# add lib name here
	set_title "   ☀️  Good Morning   "
	validate_modules					# check that configured modules have a .sh file
	validate_shortcuts					# checking for duplicate module shortcuts in config.sh

# ASK MAIN QUESTIONS
	list_questions()		# checks the modules array in config.sh > sends it to parser to get script, shortcuts, question > go over all of them 
	{
	for entry in "${GM_MODULES[@]}"; do
		parse_module "$entry"
		ask_qs "$GM_PARSED_module_question" "$GM_PARSED_module_name"
	done
	}

# EXTRA HIDDEN SHORTCUTS 			# checks if what user entered is a shortcut > these are set in config.sh
	execute_shortcut()
	{
	local answer="$1"

	for entry in "${GM_MODULES[@]}"; do
		parse_module "$entry"

		for shortcut in "${GM_PARSED_module_shortcuts[@]}"; do
			[[ "$answer" == "$shortcut" ]] && { run_module "$GM_PARSED_module_name"; return 0; }
		done
	done

	return 1
	}

close_app()
{
	clearscreen
	hide_cursor
	echo -ne " ${msg_gbye} "
	sleep 1.5
	show_cursor
	clear
	exit 0
}

ask_begin ()	# start of module
{
	echo -e " ${msg_hello} \n"
	
	local answer
	while true; do
		read -rp " ${msg_ask_first} " answer
		answer=${answer,,}
		
		execute_shortcut "$answer" && { ask_more; return; }

		case "$answer" in
			y|ye|yes|ok|k|"")
				clearscreen
				break
				;;
			n|no|nop|nope)
				close_app
				;;
			*)
				clearscreen
				echo -e " ${msg_invalid_input} \n"
				;;
		esac
	done
}

ask_qs() 	# function to ask if user wants to run module
{
	local question="$1"		# set question from first argument
	local module="$2"		# set module name from second argument

	if ask_yes_no "${question}?"; then
		run_module "$module"
	else
		anim_moving_on
		clearscreen
	fi
}

ask_more()					# triggers once all questions are asked or after a shortcut was used
{
	local answer

	while true; do
		read -rp " ${msg_ask_more} " answer
		answer=${answer,,}
		execute_shortcut "$answer" && continue
		
		case "$answer" in
			y|ye|yes|ok|k|"")
				clearscreen
				return 0
				;;
			n|no|nop|nope)
				close_app
				;;
			*)
				clearscreen
				echo -e " ${msg_invalid_input} \n"
				;;
		esac	
	done
}

ask()
{
	ask_begin
	while true; do
		list_questions
		if ! ask_more; then
			break
		fi
	done
}

ask
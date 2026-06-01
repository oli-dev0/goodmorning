#!/usr/bin/env bash
# Version 0.6

# CONFIG
	source "$(dirname "${BASH_SOURCE[0]}")/libs/bootstrap.sh"
	load_libs styles animations			# add lib name here
	set_title "   ☀️  Good Morning   "

# SET MAIN QUESTIONS
	list_questions()		# checks the modules array in config.sh > sends it to parser to get script, shortcuts, question > go over all of them 
	{
	for entry in "${MODULES[@]}"; do
		parse_module "$entry"
		ask_qs "$module_question" "$module_name"
	done
	}

# EXTRA HIDDEN SHORTCUTS 			# checks if what user entered is a shortcut > these are set in config.sh
	execute_shortcut()
	{
	local answer="$1"

	for entry in "${MODULES[@]}"; do
		parse_module "$entry"

		for shortcut in "${module_shortcuts[@]}"; do
			[[ "$answer" == "$shortcut" ]] && { run_module "$module_name"; return 0; }
		done
	done

	return 1
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
				clearscreen
				echo -ne " ${msg_gbye} "
				sleep 1.5
				clear
				return 1
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
	local answer			# set answer variable only in this function
	local question="$1"		# set question from first argument
	local module="$2"		# set module name from second argument

	while true; do
		read -rp " ${BOLD}$question?${RESET} [y/n] " answer
		answer="${answer,,}"	# lowercase

		case "$answer" in
			y|ye|yes|ok|k|"")
				run_module "$module"
				break
				;;
			n|no|nop|nope)
				echo
				clearscreen
				anim_moving_on
				clearscreen
				break
				;;
			*)
				clearscreen
				echo -e " ${msg_invalid_input} \n"
				;;
		esac
	done
}

ask_more()
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
				clearscreen
				echo -ne " ${msg_gbye} "
				sleep 1.5
				clear
				return 1
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
	while true; do
		list_questions
		if ! ask_more; then
			break
		fi
	done
}

clearscreen
ask_begin || exit 0
ask
#!/bin/env bash

# A simple interactive menu using "dialog" command

# CONFIG
	source "$(dirname "${BASH_SOURCE[0]}")/libs/bootstrap.sh"
	load_libs animations				# add lib name here
	set_title "   ☀️  Good Morning   "
	validate_modules					# check that configured modules have a .sh file
	validate_shortcuts					# checking for duplicate module shortcuts in config.sh

close_gui()
{
	clear
	echo
	animation_spinner "Goodbye"
	clear
	exit 0
}

# BUILD THE MENU - you can configure the menu order and display in config.sh
	MENU_ITEMS=()
	MENU_MODULES=()

	index=1 		# using index to show a number instead of script name in GUI menu
 	
	for entry in "${GM_MODULES[@]}"; do
		parse_module "$entry"

		MENU_ITEMS+=(
			"$index"
			"$GM_PARSED_module_display"
			"$GM_PARSED_module_description"
		)

		MENU_MODULES[index]="$GM_PARSED_module_name"	# assign script name to index nr

		((index++))
	done

	# add exit option to menu
	MENU_ITEMS+=(
		"$index"
		"❌ Exit"
		"Close the menu and return to the terminal ❌"
	)
	MENU_MODULES[index]="exit"			# assign exit to last index nr

# WELCOME TEXT
	hide_cursor
	dialog --msgbox " Welcome and good morning to you 👋 " 5 41 || close_gui
	show_cursor

# SHOW THE MENU
	while true; do
		hide_cursor
		if CHOICE=$(dialog \
			--clear \
			--ok-label "Select" \
			--no-cancel \
			--title " ☀️  Good morning  " \
			--item-help \
			--menu "Select a module 👇 " 0 0 5 \
			"${MENU_ITEMS[@]}" 2>&1 >/dev/tty); then
			STATUS=0
		else
			STATUS=$?
		fi
		show_cursor
		
		# check if Escape key was pressed (status code 255)
		[[ $STATUS -eq 255 ]] && close_gui

# RUN THE MODULES
	selected_module="${MENU_MODULES[$CHOICE]}"

		case $selected_module in
			exit) 
				close_gui
				;;
			"") 
				;;
			*) 
				run_module "$selected_module"
				;;
		esac
	done
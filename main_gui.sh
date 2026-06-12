#!/bin/env bash

# A simple interactive menu using dialog

# CONFIG
	source "$(dirname "${BASH_SOURCE[0]}")/libs/bootstrap.sh"
	load_libs animations				# add lib name here
	set_title "   ☀️  Good Morning   "

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

	for entry in "${GM_MODULES[@]}"; do
		parse_module "$entry"
		MENU_ITEMS+=(
			"$GM_PARSED_module_name"
			"$GM_PARSED_module_display"
			"$GM_PARSED_module_description"
		)
	done

	# add exit
	MENU_ITEMS+=(
		"exit"
		"❌ Exit"
		"Close the menu and return to the terminal ❌"
	)

hide_cursor
dialog --msgbox " Welcome and good morning to you 👋 " 5 41 || close_gui
show_cursor

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

	case $CHOICE in
		1) run_module "weather";;
		2) run_module "crypto" ;;
		3) run_module "backup" ;;
		4) run_module "nas_backup_rsync" ;;
		5) close_gui ;;
	esac
done
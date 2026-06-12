#!/usr/bin/env bash

# A simple interactive menu using "dialog" command

# BOOTSTRAP
	source "$(dirname "${BASH_SOURCE[0]}")/libs/bootstrap.sh"
	load_libs animations				# add lib name here
	set_title "   ☀️  Good Morning   "
	required_commands dialog
	validate_modules					# check that configured modules have a .sh file
	validate_shortcuts					# checking for duplicate module shortcuts in config.sh

# MENU STATE
	declare -a MENU_ITEMS=()
	declare -A MENU_MODULES=()

gui_close()
{
	show_cursor
	clear
	echo
	animation_spinner "Goodbye"
	clear
	exit 0
}

gui_failed_module_error()
{
	local module="$1"

	hide_cursor
	dialog --msgbox "  ❌ Error: module '${module}.sh' failed" 5 40 || true
	show_cursor
}

gui_handle_dialog_exit_status()
{
	local status="$1"

	case "$status" in
		0)
			return 0
			;;
		255)
			gui_close 		# status code 255 usually means ESC key was pressed
			;;
		*)
			hide_cursor
			dialog --msgbox "❌ Error: dialog failed with status '$status'" 6 50 || true
			show_cursor
			gui_close
			;;
	esac

}

gui_build_menu()
{
	# you can configure the menu order and display in config.sh
	MENU_ITEMS=()
	MENU_MODULES=()
	local entry
	local index=1 		# using index to show a number instead of script name in GUI menu

	for entry in "${GM_MODULES[@]}"; do
		parse_module "$entry"

		MENU_ITEMS+=(
			"$index"
			"$GM_PARSED_module_display"
			"$GM_PARSED_module_description"
		)

		MENU_MODULES["$index"]="$GM_PARSED_module_name"	# assign script name to index nr

		((index++))
	done

	# add exit option to menu
	MENU_ITEMS+=(
		"$index"
		"❌ Exit"
		"Close the menu and return to the terminal ❌"
	)
	MENU_MODULES["$index"]="exit"			# assign exit to last index nr
}

gui_show_welcome()
{
	local status
	hide_cursor
	
	if dialog --msgbox " Welcome and good morning to you 👋 " 5 41; then
		status=0
	else
		status=$?
	fi
	
	show_cursor
	gui_handle_dialog_exit_status "$status"
}

gui_show_menu()
{
	local menu_height
	local status
	local choice=""
	local selected_module

	while true; do
		hide_cursor

		menu_height=$(( ${#GM_MODULES[@]} + 1 ))	# modules + exit option
		(( menu_height > 15 )) && menu_height=15

		if choice=$(dialog \
			--clear \
			--ok-label "select" \
			--no-cancel \
			--title " ☀️  Good morning  " \
			--item-help \
			--menu "Select a module 👇 " 0 0 "$menu_height" \
			"${MENU_ITEMS[@]}" 2>&1 >/dev/tty); then
			status=0
		else
			status=$?
		fi
		
		show_cursor		# need to show again here, or my modules might not have a cursor 
		gui_handle_dialog_exit_status "$status"

		# run the modules
		selected_module="${MENU_MODULES[$choice]:-}"

		case "$selected_module" in
			exit) 
				gui_close
				;;
			"") 
				dialog --msgbox "Invalid menu selection: '$choice'" 6 50 || true
				;;
			*) 
				run_module "$selected_module" || gui_failed_module_error "$selected_module"
				;;
		esac
	done
}

main()
{
	gui_build_menu
	gui_show_welcome
	gui_show_menu
}

main "$@"

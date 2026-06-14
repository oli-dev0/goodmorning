#!/usr/bin/env bash
# version 2.0

# A simple interactive menu using "dialog" command

# BOOTSTRAP
	readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	source "$SCRIPT_DIR/libs/bootstrap.sh" || { echo -e "\n ❌ Fatal: bootstrap failed \n"; exit 1; }
	set_title "   ☀️  Good Morning   "
	required_commands dialog
	validate_modules					# check that configured modules have a .sh file
	validate_shortcuts					# checking for duplicate module shortcuts in config.sh

# MENU STATE
	declare -a MENU_ITEMS=()
	declare -A MENU_MODULES=()

gui_handle_dialog_exit_status()
{
	local status="${1:?missing dialog status}"

	case "$status" in
		0)
			return 0
			;;
		255)
			close_app 		# status code 255 usually means ESC key was pressed
			;;
		*)
			hide_cursor
			dialog --msgbox "❌ Error: dialog failed with status '$status'" 6 50 || true
			show_cursor
			close_app
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
			"$GM_PARSED_MODULE_DISPLAY"
			"$GM_PARSED_MODULE_DESCRIPTION"
		)

		MENU_MODULES["$index"]="$GM_PARSED_MODULE_NAME"	# assign script name to index nr

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
	
	if dialog --msgbox "${GM_MSG_HELLO}" 5 41; then
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
			--ok-label "  RUN  " \
			--no-cancel \
			--title "  ☀️  Good Morning   " \
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
				close_app
				;;
			"") 
				dialog --msgbox "Invalid menu selection: '$choice'" 6 50 || true
				;;
			*) 
				run_module "$selected_module" || exit $?
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

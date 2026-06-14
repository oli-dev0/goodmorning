#!/usr/bin/env bash
# version 2.0

# BOOTSTRAP
	source "$(dirname "${BASH_SOURCE[0]}")/libs/bootstrap.sh"
	set_title "   ☀️  Good Morning   "
	validate_modules					# check that configured modules have a .sh file
	validate_shortcuts					# checking for duplicate module shortcuts in config.sh

# MENU STATE
	declare -a SELECT_ITEMS=()
	declare -a SELECT_MODULES=()

select_hello()
{
	clearscreen
	echo -e "${GM_MSG_HELLO}\n"
	hide_cursor
	press_any_key "           <CONTINUE>"
	show_cursor
	clearscreen
}

select_build_menu()
{
	SELECT_ITEMS=()
	SELECT_MODULES=()

	local entry

	for entry in "${GM_MODULES[@]}"; do
		parse_module "$entry"

		SELECT_ITEMS+=("$GM_PARSED_MODULE_DISPLAY")
		SELECT_MODULES+=("$GM_PARSED_MODULE_NAME")
	done

	SELECT_ITEMS+=("❌ Exit")
	SELECT_MODULES+=("exit")
}

select_show_menu()
{
	local choice
	local selected_module
	local COLUMNS=40
	local PS3=$'\n Select a module: '

	select choice in "${SELECT_ITEMS[@]}"; do
		if [[ -z "${choice:-}" ]] || ! [[ "$REPLY" =~ ^[0-9]+$ ]] || (( REPLY < 1 || REPLY > ${#SELECT_MODULES[@]} )); then
			clearscreen
			log_error "invalid input, please try again."
			return 0
		fi

		selected_module="${SELECT_MODULES[$((REPLY - 1))]}"

		case "$selected_module" in
			exit)
				close_app
				;;
			*)
				run_module "$selected_module" || exit $?
				return 0
				;;
		esac
	done

	close_app
}

main()
{
	select_hello
	select_build_menu

	while true; do
		select_show_menu
	done
}

main "$@"

#!/usr/bin/env bash
# version 2.0

# A searchable interactive menu using 'fzf'

# BOOTSTRAP
	readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	source "$SCRIPT_DIR/libs/bootstrap.sh" || { echo -e "\n ❌ Fatal: bootstrap failed \n"; exit 1; }
	set_title "   ☀️  Good Morning   "
	required_commands fzf
	validate_modules					# check that configured modules have a .sh file
	validate_shortcuts					# checking for duplicate module shortcuts in config.sh

# MENU STATE
	declare -a FZF_ITEMS=()

fzf_build_menu()
{
	# store module name first, but only show display name in fzf
	FZF_ITEMS=()

	local entry
	local module_display_name

	for entry in "${GM_MODULES[@]}"; do
		parse_module "$entry"
		module_display_name=$(printf "%-25s" "${GM_PARSED_MODULE_DISPLAY}")
		FZF_ITEMS+=("${GM_PARSED_MODULE_NAME}"$'\t'"$module_display_name"$'\t'"$GM_PARSED_MODULE_DESCRIPTION")
	done

	FZF_ITEMS+=("exit"$'\t'"$(printf "%-20s" "❌ Exit")"$'\t'"Close the app")
}

fzf_show_menu()
{
	local choice
	local selected_module
	local fzf_exit_code
	
	local -a fzf_menu_options=(
		--ansi
		--info=right
		--color=dark
		--separator="▬"
		--scrollbar="█"
		--ellipsis=...
		--delimiter=$'\t'
		--with-nth=2..
		--nth=2..
		--prompt="Search: "
		--height=75%
		--padding=1,0,1,1
		--margin=0,10%,0,3
		--border
		--border-label=" SELECT A MODULE "
		--border-label-pos=3
		--no-multi
		--no-sort
		--cycle
		--scroll-off=10
		--layout=reverse-list
	)

	while true; do
		fzf_exit_code=0
		clearscreen
		
		choice=$(printf '%s\n' "${FZF_ITEMS[@]}" | fzf "${fzf_menu_options[@]}") || fzf_exit_code=$?
		case "$fzf_exit_code" in
			0) ;;
			1) log_warning "no match found."; press_any_key "Continue..."; continue ;;
			130) close_app ;;
			*) clearscreen; log_error "command 'fzf' failed with exit code: '$fzf_exit_code'"; break ;;
		esac

		selected_module="${choice%%$'\t'*}"
		case "$selected_module" in
			exit)
				close_app
				;;
			"")
				log_error "invalid selection, please try again."; press_any_key "Continue..."
				;;
			*)
				run_module "$selected_module" || exit $?
				;;
		esac
	done
}

main()
{
	fzf_build_menu
	fzf_show_menu
}

main "$@"

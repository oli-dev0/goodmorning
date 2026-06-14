#!/usr/bin/env bash

# avoid multiple sourcing
	[[ -n "${_MOD_LOADED:-}" ]] && return 0		# if var is not empty, then return (close the current source of lib)
	_MOD_LOADED=1 								# if its empty, continue sourcing, and set var to 1

# Parses one GM_MODULES entry (config.sh) and sets these globals:
  # GM_PARSED_MODULE_NAME
  # GM_PARSED_MODULE_DISPLAY
  # GM_PARSED_MODULE_DESCRIPTION
  # GM_PARSED_MODULE_SHORTCUTS
parse_module() {
	local entry="${1:?missing module entry}"
	local IFS='|'																					# sets | as delimiter, to split the module info in config.sh
	local fields

	read -ra fields <<< "$entry"													# read from array $entry

	GM_PARSED_MODULE_NAME="${fields[0]}"																	  				 # weather (first) - script name
	GM_PARSED_MODULE_DISPLAY="${fields[1]:-${GM_PARSED_MODULE_NAME}.sh}"						 # 🌤️  Weather (second) - question displayed
	GM_PARSED_MODULE_DESCRIPTION="${fields[2]:-Launch: ${GM_PARSED_MODULE_NAME}.sh}" # long gui description (third) - shown on the lower end of gui
	GM_PARSED_MODULE_SHORTCUTS=("${fields[@]:3}")																		 # everything after
}

validate_shortcuts()
{
	declare -A seen_shortcuts
	local shortcut

	for entry in "${GM_MODULES[@]}"; do parse_module "$entry"

		for shortcut in "${GM_PARSED_MODULE_SHORTCUTS[@]}"; do
			if [[ -n "${seen_shortcuts[$shortcut]:-}" ]]; then
				clearscreen
				log_error "duplicate shortcut '$shortcut' used by '$GM_PARSED_MODULE_NAME' and '${seen_shortcuts[$shortcut]}'"
				return 1
			fi
			seen_shortcuts[$shortcut]="$GM_PARSED_MODULE_NAME"
		done
	done
}

validate_modules()
{
	local entry

	for entry in "${GM_MODULES[@]}"; do
		parse_module "$entry"

		if [[ ! -f "$GM_MODULES_DIR/$GM_PARSED_MODULE_NAME.sh" ]]; then
			clearscreen
			log_error "configured module '$GM_PARSED_MODULE_NAME' does not exist at '$GM_MODULES_DIR/$GM_PARSED_MODULE_NAME.sh'"
			return 1
		fi
	done
}

run_module()
{
	local module="${1:?missing module}"
	local module_path="$GM_MODULES_DIR/$module.sh"
	local saved_title="$GM_CURRENT_TITLE"				# get previous title before running new script
	local exit_code=0
	
	[[ ! -f "$module_path" ]] && { clearscreen; log_error "module '$module' not found at '$module_path'" >&2; return 1; }

	bash "$module_path" || exit_code=$?		# get exit code of previous command 'bash'
	if (( exit_code == 0 )); then
		set_title "$saved_title"						# set both titles back to previous title
	fi
	return "$exit_code"										# return exit code from bash command or 0
}

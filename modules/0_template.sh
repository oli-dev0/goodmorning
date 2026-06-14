#!/usr/bin/env bash

# BOOTSTRAP
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	source "$SCRIPT_DIR/../libs/bootstrap.sh"
	set_title "🌤️ MODULE TITLE 🌤️"	# Adjust title
	required_commands jq			# checks for required commands

main()
{
    :
}

main "$@"

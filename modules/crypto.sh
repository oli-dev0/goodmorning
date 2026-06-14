#!/usr/bin/env bash

# BOOTSTRAP
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	source "$SCRIPT_DIR/../libs/bootstrap.sh"
	set_title "🪙  CRYPTO 🪙"
	required_commands

echo -e " this is a work in progress\n"
press_any_key


clearscreen
log_error "no active internet connection" >&2
exit 1
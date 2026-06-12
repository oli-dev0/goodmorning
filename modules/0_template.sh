#!/usr/bin/env bash

# BOOTSTRAP
	source "$(dirname "${BASH_SOURCE[0]}")/../libs/bootstrap.sh"
	set_title "🌤️ MODULE TITLE 🌤️"	# Adjust title
	required_commands jq bc 		# checks for required commands

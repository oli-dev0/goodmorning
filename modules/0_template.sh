#!/usr/bin/env bash

# CONFIG
	source "$(dirname "${BASH_SOURCE[0]}")/../libs/bootstrap.sh"
	load_libs  			# add lib names here
	set_title "🌤️ MODULE TITLE 🌤️"	# Adjust title
	required_commands jq bc 	# checks for required commands
	
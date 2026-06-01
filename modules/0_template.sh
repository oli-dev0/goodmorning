#!/usr/bin/env bash

# CONFIG
	source "$(dirname "${BASH_SOURCE[0]}")/../libs/bootstrap.sh"
	load_libs styles 			# add lib names here
	set_title "🌤️  TITLE 🌤️"	# Adjust title
	required_commands jq bc 	# checks for required commands
#!/usr/bin/env bash

# CONFIG
	source "$(dirname "${BASH_SOURCE[0]}")/../libs/bootstrap.sh"
	load_libs						# add lib names here
	set_title "🌤️  CRYPTO 🌤️"		# Adjust title
	required_commands jq bc 		# checks for required commands

clearscreen
echo -e " this is a work in progress"
echo " closing in 2 sec..."
sleep 3

#!/usr/bin/env bash

# CONFIG
	source "$(dirname "${BASH_SOURCE[0]}")/libs/bootstrap.sh"
	load_libs styles animations			# add lib name here
	set_title "   ☀️  TEST    "

clearscreen

# http_get "wttr.in/?format=%c"


	echo -e "${GREEN}   ━━━━━━━━━━━━━━━━━━━━${RESET}"
	echo -e "${GREEN}${BOLD}   ✅ Backup completed${RESET}"
	echo -e "${GREEN}   ━━━━━━━━━━━━━━━━━━━━${RESET}"

echo
echo 

	echo -e "${SUCCESS}   ━━━━━━━━━━━━━━━━━━━━${RESET}"
	log_success "Backup completed"
	echo -e "${SUCCESS}   ━━━━━━━━━━━━━━━━━━━━${RESET}"
	echo "okay"

# echo "green"
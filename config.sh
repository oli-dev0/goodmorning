#!/usr/bin/env bash

# PATHS
	GM_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	GM_LIBS_DIR="$GM_ROOT_DIR/libs"
	GM_MODULES_DIR="$GM_ROOT_DIR/modules"

# LOAD TOOLS
	source "$GM_LIBS_DIR/tools.sh"				# makes load_libs available in other scripts

# SET MESSAGES
	# MAIN
		# HELLO
			msg_hello="Hello sir, good morning 👋"
		# FIRST QS ASK
			msg_ask_first="Can I do something for you?"
		# ASK MORE
			msg_ask_more="Anything else?"
		# GOODBYE
			msg_gbye="Okay, goodbye 👋"

	# GLOBAL
		# INVALID INPUT
		msg_invalid_input="Invalid input, please use [y/n]"

# SET MODULES - every new module needs to be setup here
	# script name | shortcuts | question to ask?
	GM_MODULES=(
		"weather|weather|w|🌤️  Weather"
		"crypto|crypto|cryp|c|🪙  Crypto"
		"backup|backup|back|bak|b|💾 Backup"
	)

# WEATHER
	# nothing to configure for weather module

# BACKUP - THESE FOLDERS MAY NOT BE THE SAME
	GM_BACKUP_SOURCE="$HOME/Coding"				# what to backup
	GM_BACKUP_DEST="$HOME/Coding/backups"		# where to backup (this folder is excluded from being backed up)

# CRYPTO
	# API TO CALL
		crypto_api=""				# currently empty because crypto script is WIP, not sure which API I will use
	# SET BASE CURRENCY (EUR, AUD, USD etc)
		crypto_base_currency="EUR"
	# SET FAVORITES
		crypto_favorites=("BTC" "ETH" "ADA" "SUI" "WPAY" "WXT" "ALPHA")


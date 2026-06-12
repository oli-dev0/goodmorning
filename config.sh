#!/usr/bin/env bash

# PATHS
	GM_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	GM_LIBS_DIR="$GM_ROOT_DIR/libs"
	GM_MODULES_DIR="$GM_ROOT_DIR/modules"

# SET MESSAGES
	# MAIN
		# HELLO
			msg_hello=" Welcome and good morning to you 👋 "
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
	# module name must equal the script.sh name in modules folder
	# only module name is required, rest is optional
	# module name | display label | GUI description | shortcuts
	GM_MODULES=(
		"weather|🌤️  Weather|Check the weather for your current location or anywhere in the world 🌍|weather|w"
		"crypto|🪙 Crypto|Check current crypto prices and market movement 📈|crypto|cryp|c"
		"backup|💾 Backup|Create a local backup of your important files 🗂️|backup|back|bak|b"
		"nas_backup_rsync|☁️  Sync backups to NAS|Sync your backup safely to the NAS over the network 🔁|rbak|rs|r"
	)

# WEATHER
	GM_WEATHER_API_URL="https://wttr.in/"
	GM_WEATHER_FORMAT="?format=j2"


# LOCAL BACKUP - THESE FOLDERS MAY NOT BE THE SAME
	GM_BACKUP_SOURCE="$HOME/Coding"				# what to backup
	GM_BACKUP_DEST="$HOME/Coding/backups"		# where to backup (this folder is excluded from being backed up)

# NAS BACKUP RSYNC
	GM_NAS_HOST="nas"
	GM_LOCAL_BACKUP_DIR="$GM_BACKUP_DEST/"						# what folder to sync with your NAS
	GM_NAS_TARGET="$GM_NAS_HOST:/volume1/Data/Backups/Coding/"	# where to sync on your NAS
	GM_NAS_PATH="${GM_NAS_TARGET#"$GM_NAS_HOST":}"				# need path for script

# CRYPTO
	# API TO CALL
		GM_CRYPTO_API=""				# currently empty because crypto script is WIP, not sure which API I will use
	# SET BASE CURRENCY (EUR, AUD, USD etc)
		GM_CRYPTO_BASE_CURRENCY="EUR"
	# SET FAVORITES
		GM_CRYPTO_FAVORITES=("BTC" "ETH" "ADA" "SUI" "WPAY" "WXT" "ALPHA")


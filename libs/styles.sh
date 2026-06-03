#!/usr/bin/env bash

# AVOID MULTIPLE SOURCING
	[[ -n "${_STYLES_LOADED:-}" ]] && return 0		# if var is not empty, then return (close the current "source" of lib)
	_STYLES_LOADED=1 								# if its empty, continue sourcing, and set var to 1

# PRESETS
	#GLOBAL
		INFO=$'\e[1;34m'
		SUCCESS=$'\e[1;92m'
		WARNING=$'\e[1;33m'
		ERROR=$'\e[1;91m'
		ERRORTEXT=$'\e[1;2;3m'
		TITLE=$'\e[1;33;100m'


	#WEATHER
		RAIN=$'\e[1;5;96m'
		SNOW=$'\e[1;5;97m'
		STORM=$'\e[1;5;33m'
		THUNDER=$'\e[1;5;93m'

# TEXT
	BLACK=$'\e[30m'
	RED=$'\e[31m'
	GREEN=$'\e[32m'
	YELLOW=$'\e[33m'
	BLUE=$'\e[34m'
	MAGENTA=$'\e[35m'
	CYAN=$'\e[36m'
	WHITE=$'\e[37m'

# TEXT BRIGHT
	BLACKB=$'\e[90m'
	REDB=$'\e[91m'
	GREENB=$'\e[92m'
	YELLOWB=$'\e[93m'
	BLUEB=$'\e[94m'
	MAGENTAB=$'\e[95m'
	CYANB=$'\e[96m'
	WHITEB=$'\e[97m'

# BACKGROUND
	BLACKBG=$'\e[40m'
	REDBG=$'\e[41m'
	GREENBG=$'\e[42m'
	YELLOWBG=$'\e[43m'
	BLUEBG=$'\e[44m'
	MAGENTABG=$'\e[45m'
	CYANBG=$'\e[46m'
	WHITEBG=$'\e[47m'

# BACKGROUND BRIGHT
	BLACKBGB=$'\e[100m'
	REDBGB=$'\e[101m'
	GREENBGB=$'\e[102m'
	YELLOWBGB=$'\e[103m'
	BLUEBGB=$'\e[104m'
	MAGENTABGB=$'\e[105m'
	CYANBGB=$'\e[106m'
	WHITEBGB=$'\e[107m'

# STYLES
	BOLD=$'\e[1m'
	DIM=$'\e[2m'
	ITALIC=$'\e[3m'
	UNDERLINE=$'\e[4m'
	BLINK=$'\e[5m'
	REVERSE=$'\e[7m'
	HIDDEN=$'\e[8m'

# RESET
	RESET=$'\e[0m'
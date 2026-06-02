#!/usr/bin/env bash
# Version 1.0

#	= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =	#
#																					#
#	WEATHER SCRIPT																	#
#	--------------																	#
#	Purpose:																		#
#	- Fetches and displays current weather for any location using wttr.in			#
#																					#
#	Usage:																			#
#	 ./weather.sh <location>														#
#																					#
#	Example:																		#
#	 ./weather.sh Tokyo																#
#	 ./weather.sh "New York"														#
#																					#
#	- Location can be passed as argument, or entered when prompted					#
#	- Leaving location empty uses your current location								#
#	- After each result, you can search another location or exit					#
#	- Specific landmarks such as "Eiffel Tower" are also supported by wttr.in		#
#																					#
#	Output:																			#
#	- Temperature, feels like, avg, high											#
#	- Humidity, wind speed															#
#	- Sunrise and sunset times														#
#	- Warnings for rain, snow, storm or thunder (only shown when relevant)			#
#																					#
#	Validation:																		#
#	- Validates API response, JSON structure, and location before parsing			#
#	- Handles unknown locations and empty responses with clear error messages		#
#	- ERR trap catches any failure and reports the line and command that failed		#
#																					#
#	= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =	#


# CONFIG
	source "$(dirname "${BASH_SOURCE[0]}")/../libs/bootstrap.sh"
	load_libs animations math
	set_title "🌤️  WEATHER 🌤️"
	required_commands jq bc

weather_jsoncheck()
{
	local json="$1"

	# CHECK IF API RETURNED SOMETHING
		[[ -z "$json" ]] && { clearscreen; log_error "weather - json check // empty response from weather API"; return 1; }

	# CHECK IF LOCATION IS CORRECT
		[[ "$json" == *"location not found"* ]] && { clearscreen; log_error "weather // location not found"; return 1; }
	
	# VALIDATE JSON STRUCTURE
		jq empty <<< "$json" 2>/dev/null || { clearscreen; log_error "weather - json check // invalid JSON file"; return 1; }
	
	# CHECK IF KNOWN FIELD EXISTS INSIDE JSON
		jq -e '.current_condition[0]' <<< "$json" >/dev/null 2>&1 || { clearscreen; log_error "weather - json check // missing weather data"; return 1; }

	return 0
}

weather_getinfo()
{
	local location
	local weatherJson

# GET LOCATION, USE ARGUMENT IF GIVEN
# 	if arg is not empty > use arg		else read location
	[[ -n "$1" ]] && location="$1" || read -r -p " Enter location: " location
	location="${location// /%20}"		# replace spaces with %20 for http request

# FETCH ANIMATION
	log_start "weather - starting fetch"; clearscreen
	anim_status_bar "Fetching weather data..."; clearscreen

# FETCH JSON
	check_internet || return 1											# check if online
	# real curl > show error if no http_get client installed
	weatherJson="$(http_get "https://wttr.in/${location}?format=j2")" || { log_error "weather - http_get"; move_line_up; move_line_up; exit 1; }
	# weatherJson=$(cat "$GM_LIBS_DIR/wttr.json")							# local file for testing
	# format here: https://github.com/chubin/wttr.in#one-line-output

# CHECK JSON STRUCTURE
	log_start "weather - starting json check"; clearscreen
	weather_jsoncheck "$weatherJson" || { printf ' %sWeather fetch failed %s\n\n' "${ERROR}" "${RESET}"; return 1; }

# DECLARE WEATHER VARIABLES FROM JSON
	unset weather					# reset weather variable
	declare -gA weather
	weather[temp]="$(jq -r '.current_condition[0].temp_C' <<< "$weatherJson")"
	weather[feels]="$(jq -r '.current_condition[0].FeelsLikeC' <<< "$weatherJson")"
	weather[humidity]="$(jq -r '.current_condition[0].humidity' <<< "$weatherJson")"
	weather[time]="$(jq -r '.current_condition[0].observation_time' <<< "$weatherJson")"
	weather[desc]="$(jq -r '.current_condition[0].weatherDesc[0].value | sub("\\s+$"; "")' <<< "$weatherJson")"
	weather[wind]="$(jq -r '.current_condition[0].windspeedKmph' <<< "$weatherJson")"
	weather[rain]="$(jq -r '.current_condition[0].precipMM' <<< "$weatherJson")"
	weather[city]="$(jq -r '.nearest_area[0].areaName[0].value' <<< "$weatherJson")"
	weather[sunrise]="$(jq -r '.weather[0].astronomy[0].sunrise' <<< "$weatherJson")"
	weather[sunset]="$(jq -r '.weather[0].astronomy[0].sunset' <<< "$weatherJson")"
	weather[avgtemp]="$(jq -r '.weather[0].avgtempC' <<< "$weatherJson")"
	weather[maxtemp]="$(jq -r '.weather[0].maxtempC' <<< "$weatherJson")"
	weather[sunhr]="$(jq -r '.weather[0].sunHour' <<< "$weatherJson")"
	weather[snow]="$(jq -r '.weather[0].totalSnow_cm' <<< "$weatherJson")"
	weather[emoji]="$(http_get "https://wttr.in/${location// /%20}?format=%c")"
}

weather_warnings()
{
	local desc="${weather[desc],,}"

# RAIN
	(is_positive "${weather[rain]}" || [[ "$desc" == *rain* ]]) &&
	printf '\n 🌧️  %sWARNING - RAIN EXPECTED - %smm%s 🌧️\n' "${RAIN}" "${weather[rain]}" "${RESET}"

# SNOW
	(is_positive "${weather[snow]}" || [[ "$desc" == *snow* ]]) &&
	printf '\n 🌨️  %sWARNING - SNOW EXPECTED - %scm%s 🌨️\n' "${SNOW}" "${weather[snow]}" "${RESET}"

# STORM
	[[ "$desc" == *storm* ]] && 
	printf '\n ⛈️  %sWARNING - STORM EXPECTED%s ⛈️\n' "${STORM}" "${RESET}"

# THUNDER
	[[ "$desc" == *thunder* ]] && 
	printf '\n ⚡ %sWARNING - THUNDER EXPECTED%s ⚡\n' "${THUNDER}" "${RESET}"

# HAIL
	[[ "$desc" == *hail* ]] && 
	printf '\n 🌨  %sWARNING - HAIL EXPECTED%s 🌨\n' "${SNOW}" "${RESET}"
}

weather_showinfo()
{
	clearscreen
	printf '%s\n' " ${weather[emoji]} ${BOLD}${weather[desc]} ${RESET}in ${BOLD}${weather[city]}${RESET}"
	printf '%s\n' " ${BOLD}- - - - - - - - - - - - - - - - ${RESET}"
	printf '%s\n' " 🌡️ ${BOLD}Current: ${RESET}${weather[temp]}°C (feels ${weather[feels]}°C)"
	printf '%s\n' " 📊 ${BOLD}Avg:${RESET} ${weather[avgtemp]}°C | 📈 ${BOLD}High:${RESET} ${weather[maxtemp]}°C"
	printf '%s\n' " 💧 ${BOLD}Humidity:${RESET} ${weather[humidity]}% | 💨 ${BOLD}Wind:${RESET} ${weather[wind]}kmh"
	printf '%s\n' " 🌄 ${BOLD}Sunrise:${RESET} ${weather[sunrise]} | 🌇 ${BOLD}Sunset:${RESET} ${weather[sunset]}"
	weather_warnings					# show weather warnings
	printf '%s\n' " ${BOLD}- - - - - - - - - - - - - - - - - - - - - -${RESET}"
	printf '%s\n\n' " ℹ️  ${ITALIC}${DIM}Snapshot from ${weather[time]}${RESET}"
}

get_weather()
{
	weather_getinfo "$1" || return
	weather_showinfo
}

get_weather_ask()
{
	local answer
	local running=true
	
	while $running; do
		clearscreen
		get_weather "${1:-}" || true
		set --										# clears all arguments from ./weather.sh "arg"
													# so that new loop can ask for location
		if ! ask_yes_no "Another location?"; then 	# if answer no, move on and close loop by setting running to false
			anim_moving_on
			clear
			running=false
		fi
	done
}

clearscreen
get_weather_ask "${1:-}"

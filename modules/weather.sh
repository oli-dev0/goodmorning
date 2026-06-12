#!/usr/bin/env bash
# Version 1.0

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =	#
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
#	 ./weather.sh "Eiffel Tower"													#
#	 ./weather.sh "amsterdam, the netherlands"										#
#	 ./weather.sh "São Paulo"														#
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
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =	#


# BOOTSTRAP
	source "$(dirname "${BASH_SOURCE[0]}")/../libs/bootstrap.sh"
	set_title "🌤️  WEATHER 🌤️"
	required_commands jq

weather_verify_json()
{
	local json="${1:-}"

	# CHECK IF API RETURNED SOMETHING
		[[ -z "$json" ]] && { clearscreen; log_error "empty JSON file"; return 1; }

	# CHECK IF LOCATION IS CORRECT
		[[ "$json" == *"location not found"* ]] && { clearscreen; log_error "location not found"; return 1; }
	
	# VALIDATE JSON STRUCTURE
		jq empty <<< "$json" 2>/dev/null || { clearscreen; log_error "invalid JSON file"; return 1; }
	
	# CHECK IF REQUIRED FIELDS EXIST INSIDE JSON
	jq -e '
	[
		.current_condition[0].temp_C,
		.current_condition[0].FeelsLikeC,
		.current_condition[0].humidity,
		.current_condition[0].observation_time,
		.current_condition[0].weatherDesc[0].value,
		.current_condition[0].windspeedKmph,
		.current_condition[0].precipMM,
		.nearest_area[0].areaName[0].value,
		.nearest_area[0].country[0].value,
		.weather[0].astronomy[0].sunrise,
		.weather[0].astronomy[0].sunset,
		.weather[0].avgtempC,
		.weather[0].maxtempC,
		.weather[0].sunHour,
		.weather[0].totalSnow_cm
	] | all(. != null)
	' <<< "$json" >/dev/null 2>&1 || { clearscreen; log_error "missing weather data in json"; return 1; }

	return 0
}

weather_parse_json()
{
	local json="${1:-}"
	local location="${2:-}"

	# check if json argument was provided
	[[ -z "$json" ]] && { clearscreen; log_error "missing JSON argument"; return 1; }

	unset weather					# reset weather variable
	declare -gA weather
	local weather_data
	local temp feels humidity time desc wind rain city country sunrise sunset avgtemp maxtemp sunhr snow

	weather_data="$(jq -r '
		[	
			.current_condition[0].temp_C // "",
			.current_condition[0].FeelsLikeC // "",
			.current_condition[0].humidity // "",
			.current_condition[0].observation_time // "",
			(.current_condition[0].weatherDesc[0].value // "" | sub("\\s+$"; "")),
			.current_condition[0].windspeedKmph // "",
			.current_condition[0].precipMM // "",
			.nearest_area[0].areaName[0].value // "",
			.nearest_area[0].country[0].value // "",
			.weather[0].astronomy[0].sunrise // "",
			.weather[0].astronomy[0].sunset // "",
			.weather[0].avgtempC // "",
			.weather[0].maxtempC // "",
			.weather[0].sunHour // "",
			.weather[0].totalSnow_cm // ""
		] | join("|")
		' <<< "$json"
		)" || { log_error "weather - failed to parse JSON"; return 1; }

	IFS='|' read -r temp feels humidity time desc wind rain city country sunrise sunset avgtemp maxtemp sunhr snow <<< "$weather_data"

	weather[temp]="$temp"
	weather[feels]="$feels"
	weather[humidity]="$humidity"
	weather[time]="$time"
	weather[desc]="${desc// nearby/}"
	weather[wind]="$wind"
	weather[rain]="$rain"
	weather[city]="$city"
	weather[country]="$country"
	weather[sunrise]="$sunrise"
	weather[sunset]="$sunset"
	weather[avgtemp]="$avgtemp"
	weather[maxtemp]="$maxtemp"
	weather[sunhr]="$sunhr"
	weather[snow]="$snow"
	weather[emoji]="$(http_get "${GM_WEATHER_API_URL}${location}?format=%c" 2>/dev/null || printf '🌍')"
}

weather_fetch()
{
	local location="${1:-}"
	local weather_json

	# ask for location when no argument is given
	[[ -z "$location" ]] && read -r -p " Enter location: " location
	location="$(url_encode "$location")"

# CHECK IF ONLINE
	log_start "weather - starting fetch"; move_line_up 2
	check_internet || exit 1
	clearscreen

# FETCH ANIMATION
	anim_status_bar "Fetching weather data..."; clearscreen

# FETCH JSON
	# real curl > show error if no http_get client installed
	weather_json="$(http_get "${GM_WEATHER_API_URL}${location}${GM_WEATHER_FORMAT}")" || { log_error "weather - http_get"; move_line_up 3; exit 1; }
	# weather_json=$(cat "$GM_LIBS_DIR/wttr.json")							# local file for testing
	# format here: https://github.com/chubin/wttr.in#one-line-output

# CHECK JSON STRUCTURE
	log_start "weather - starting json check"; move_line_up 2
	weather_verify_json "$weather_json" || { move_line_up; printf ' %sWeather fetch failed %s\n\n' "${ERROR}" "${RESET}"; return 1; }

#  PARSE WEATHER VARIABLES FROM JSON
	weather_parse_json "$weather_json" "$location"
}

weather_warnings()
{
	local desc="${weather[desc],,}"

# RAIN
	(is_positive "${weather[rain]}" || [[ "$desc" == *rain* ]]) &&
	printf '    🌧️  %sWARNING - RAIN EXPECTED - %smm%s 🌧️|\n\n' "${RAIN}" "${weather[rain]}" "${RESET}"

# SNOW
	(is_positive "${weather[snow]}" || [[ "$desc" == *snow* ]]) &&
	printf '    🌨️  %sWARNING - SNOW EXPECTED - %scm%s 🌨️\n\n' "${SNOW}" "${weather[snow]}" "${RESET}"

# STORM
	[[ "$desc" == *storm* ]] && 
	printf '    ⛈️  %sWARNING - STORM EXPECTED%s ⛈️\n\n' "${STORM}" "${RESET}"

# THUNDER
	[[ "$desc" == *thunder* ]] && 
	printf '    ⚡ %sWARNING - THUNDER EXPECTED%s ⚡\n\n' "${THUNDER}" "${RESET}"

# HAIL
	[[ "$desc" == *hail* ]] && 
	printf '    🌨  %sWARNING - HAIL EXPECTED%s 🌨\n\n' "${SNOW}" "${RESET}"
}

weather_display()
{
	clearscreen
	printf '%s\n' " ${weather[emoji]} ${BOLD}${weather[desc]} ${RESET}in ${BOLD}${weather[city]}, ${weather[country]}${RESET}"
	printf '%s \n' "${BOLD} - - - - - - - - - - - - - - - - - - - - - -${RESET}"
	printf '%s  \n' "      🌡️ ${BOLD}Current: ${RESET}${weather[temp]}°C | 🥵 Feels like: ${weather[feels]}°C"
	printf '%s        \n' "         📊 ${BOLD}Avg:${RESET} ${weather[avgtemp]}°C | 📈 ${BOLD}High:${RESET} ${weather[maxtemp]}°C"
	printf '%s       \n' "     💧 ${BOLD}Humidity:${RESET} ${weather[humidity]}% | 💨 ${BOLD}Wind:${RESET} ${weather[wind]}kmh"
	printf '%s  \n' " 🌄 ${BOLD}Sunrise:${RESET} ${weather[sunrise]} | 🌇 ${BOLD}Sunset:${RESET} ${weather[sunset]}"
	printf '%s \n' "${BOLD} - - - - - - - - - - - - - - - - - - - - - -${RESET}"
	printf '%s\n\n' " ℹ️  ${ITALIC}${DIM}Snapshot from ${weather[time]}${RESET}"
	weather_warnings					# show weather warnings

}

weather_run()
{
	weather_fetch "${1:-}" || return
	weather_display
}

weather_loop()
{
	local running=true
	
	while $running; do
		clearscreen
		weather_run "${1:-}" || true
		set --										# clears all arguments from ./weather.sh "arg"
													# so that new loop can ask for location
		if ! ask_yes_no "Another location?"; then 	# if answer no, move on and close loop by setting running to false
			anim_moving_on
			clear
			running=false
		fi
	done
}

weather_loop "${1:-}"

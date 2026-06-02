#!/usr/bin/env bash

#	= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =	#
#																					#
#	BACKUP SCRIPT																	#
#	-------------																	#
#	Purpose:																		#
#	- Creates a compressed .tar.gz backup of the source directory				 	#
#																					#
#	Usage:																			#
#	 ./backup.sh																	#
#																					#
#	- Configure the directories in config.sh										#
#	- The backup folder itself is excluded from the archive						 	#
#																					#
#	Output:																		 	#
#	- Timestamp, file count, archive size, and hidden file count					#
#																					#
#	Notes:																			#
#	- Uses gzip compression, well suited for text and code files					#
#	- Includes hidden files (dotfiles)												#
#	- ERR trap catches any failure and reports the line and command that failed	 	#
#																					#
#	= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =	#

# CONFIG
	source "$(dirname "${BASH_SOURCE[0]}")/../libs/bootstrap.sh"
	load_libs styles animations
	set_title "💾 BACKUP 💾"
	required_commands tar stat numfmt

# CHECK IF SOURCE FOLDER EXISTS
	[[ -d "$GM_BACKUP_SOURCE" ]] || { log_error "source directory does not exist: $GM_BACKUP_SOURCE" >&2; exit 1; }

# CREATE BACKUP FOLDER
	mkdir -p "$GM_BACKUP_DEST" || { log_error "cannot create backup folder: $GM_BACKUP_DEST" >&2; exit 1; }

# CHECK IF BACKUP FOLDER EXISTS
	[[ -d "$GM_BACKUP_DEST" ]] || { log_error "destination directory does not exist: $GM_BACKUP_DEST" >&2; exit 1; }

# GET TRUE PATH
	backup_source="$(cd "$GM_BACKUP_SOURCE" && pwd -P)"
	backup_dest="$(cd "$GM_BACKUP_DEST" && pwd -P)"

# CHECK IF SOURCE AND BACKUP FOLDER ARE THE SAME
	[[ "$backup_source" == "$backup_dest" ]] && { log_error "backup source and destination cannot be the same directory" >&2; exit 1; }
	
# VARIABLES
	timestamp="$(date '+%Y-%m-%d_%H-%M')"
	tar_file="$backup_dest/$timestamp.tar.gz"

# EXCLUSIONS
	# fixed excludes, can be added with +=
	tar_excludes=(
		--exclude="./tmp"
		--exclude="./cache"
	)

	# exclude backup folder from being backed up
		if [[ "$backup_dest" == "$backup_source"/* ]]; then				# if backup dest is inside source
			backup_relative_path="${backup_dest#"$backup_source"/}"		# then get relative path (this is needed because tar -C)
			tar_excludes+=(--exclude="./$backup_relative_path")			# add exclusion to array
		fi
	
	# exclude current archive if created inside source (edge case)
		if [[ "$tar_file" == "$backup_source"/* ]]; then				# if created tar sits inside source
			tar_excludes+=(--exclude="./${tar_file#"$backup_source"/}")	# exclude it
		fi

# ASK
	clearscreen
	if ! ask_yes_no "Do you want to make a backup?"; then
		anim_moving_on
		clear
		exit 0
	fi

# PROGRESS ANIMATION
	clearscreen
	log_start "Backup started..."; sleep 0.3
	clearscreen
	anim_status_bar "Backup in progress...  "; sleep 0.5

# MAKE BACKUP
	tar "${tar_excludes[@]}" --transform='s|^\./||' -czf "$tar_file" -C "$backup_source" .

# GET FILE INFO
	file_count=$(tar -tvzf "$tar_file" | awk '$1 ~ /^-/ { count++ } END { print count+0 }')
	file_size=$(stat -c "%s" "$tar_file" | numfmt --to=iec)		# get size in bytes, convert to readable format
	file_hidden=$(tar -tvzf "$tar_file" | awk '$1 ~ /^-/ && $0 ~ /(^|\/)\.[^\/]/ { count++ } END { print count+0 }')

# SUCCESS TEXT
	clearscreen
	log_success "backup - success"
	clearscreen
	printf '%s\n' "${GREEN}   ━━━━━━━━━━━━━━━━━━━━${RESET}"
	printf '%s\n' "${GREEN}${BOLD}   ✅ Backup completed${RESET}"
	printf '%s\n' "${GREEN}   ━━━━━━━━━━━━━━━━━━━━${RESET}"

	printf '%s\n' "${BOLD}${BLUE}   📦 Archive:${RESET}  $tar_file"
	printf '%s\n' "${BOLD}${BLUE}   🕒 Time:${RESET}	${timestamp//_/ at } "
	printf '%s' "${BOLD}${BLUE}   📄 Files:${RESET}	$file_count (${file_hidden} hidden) "
	printf '\n%s\t%s\n\n' "${BOLD}${BLUE}   💾 Size:${RESET}" "$file_size"
	
	hide_keyboard
	read -rn1 -p "${BLINK} Press any key to continue... ${RESET}"; clearline
	show_keyboard
	anim_moving_on
	clear

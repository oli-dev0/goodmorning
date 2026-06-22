#!/usr/bin/env bash

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = #
#																					#
#	BACKUP SCRIPT																	#
#	-------------																	#
#	Purpose:																		#
#	- Creates a compressed .tar.gz backup of the source directory					#
#																					#
#	Usage:																			#
#	 ./backup.sh																	#
#																					#
#	- Configure the directories in config.sh										#
#	- The backup folder itself is excluded from the archive							#
#																					#
#	Output:																			#
#	- Timestamp, file count, archive size, and hidden file count					#
#																					#
#	Notes:																			#
#	- Uses gzip compression, well suited for text and code files					#
#	- Includes hidden files (dotfiles)												#
#	- ERR trap catches any failure and reports the line and command that failed	 	#
#																					#
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = #

# BOOTSTRAP
	readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	source "$SCRIPT_DIR/../libs/bootstrap.sh" || { echo -e "\n ❌ Fatal: bootstrap failed \n"; exit 1; }
	set_title "💾 BACKUP 💾"
	required_commands tar stat numfmt pv gzip
# ps: backup directories are set in config.sh

# ASK
	ask_first "Do you want to make a backup?"
	log_start "backup - folders check started"; clearscreen

# CHECK IF SOURCE FOLDER EXISTS
	animation_spinner "Checking source folder... "
	if [[ ! -d "$GM_BACKUP_SOURCE" ]]; then
		log_error "source directory does not exist" >&2; move_line_up
		printf '  📂 %sPath:%s %s\n\n' "${WARNING}" "${RESET}" "$GM_BACKUP_SOURCE"
		exit 1
	else
		move_line_up
		log_success "Source folder exists"; move_line_up
	fi

# CREATE BACKUP FOLDER
	mkdir -p "$GM_BACKUP_DEST" 2>/dev/null || { clearscreen; log_error "cannot create backup folder '$GM_BACKUP_DEST' - check path or permission" >&2; exit 1; }

# CHECK IF BACKUP FOLDER EXISTS
	animation_spinner "Checking backup folder... "
	if [[ ! -d "$GM_BACKUP_DEST" ]]; then
		log_error "destination directory does not exist" >&2; move_line_up
		printf '  📂 %sPath:%s %s\n\n' "${WARNING}" "${RESET}" "$GM_BACKUP_DEST"
		exit 1
	else
		move_line_up
		log_success "Backup folder exists"; move_line_up
	fi

# GET TRUE PATH
	backup_source="$(cd "$GM_BACKUP_SOURCE" && pwd -P)"
	backup_dest="$(cd "$GM_BACKUP_DEST" && pwd -P)"

# CHECK IF SOURCE AND BACKUP FOLDER ARE THE SAME
	animation_spinner "Checking if folders are the same... "
	if [[ "$backup_source" == "$backup_dest" ]]; then
		log_error "backup source and destination cannot be the same directory" >&2; move_line_up
		printf '        📂 %sSource:%s %s\n' "${BOLD}" "${RESET}" "'$backup_source'"
		printf '   📂 %sDestination:%s %s\n\n' "${BOLD}" "${RESET}" "'$backup_dest'"
		exit 1
	else
		move_line_up
		log_success "All folders valid"; move_line_up
	fi

# CHECK IF ENOUGH DISK SPACE IS AVAILABLE
	animation_spinner "Checking available disk space... "

	available_kb=$(df --output=avail "$backup_dest" | tail -n1)
	source_kb=$(du -sk "$backup_source" | cut -f1)
	required_kb=$(( source_kb * 120 / 100 ))

	if (( available_kb < required_kb )); then
		echo
		log_error "not enough disk space available for backup"; move_line_up
		echo -e "${BOLD} 📂 You have ${WARNING}$(( available_kb / 1024 ))MB${RESET}${BOLD} left, but you need ${WARNING}$(( required_kb / 1024 ))MB ${RESET}\n"
		exit 1
	else
		move_line_up
		log_success "Enough disk space available";
	fi

# VARIABLES
	timestamp="$(date '+%Y-%m-%d_%H-%M')"
	readonly timestamp
	tar_file="$backup_dest/$timestamp.tar.gz"
	readonly tar_file

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

# PROGRESS SIZE
	exclude_paths=(
		-path "$backup_source/tmp"
		-o -path "$backup_source/cache"
	)

	if [[ "$backup_dest" == "$backup_source"/* ]]; then
		exclude_paths+=(
			-o -path "$backup_dest"
		)
	fi

	progress_total_bytes=$(
		find "$backup_source" \
			\( "${exclude_paths[@]}" \) -prune -o \
			-type f -printf '%s\n' |
			awk '{ sum += $1 } END { print sum + 0 }'
	)

	progress_pv_args=(-pterb)
	if (( progress_total_bytes > 0 )); then
		progress_pv_args=(-s "$progress_total_bytes" -pterb)
	fi

# PROGRESS ANIMATION
	hide_cursor
	log_start "Backup in progress..."; move_line_up

# MAKE BACKUP
	tar "${tar_excludes[@]}" --transform='s|^\./||' -cf - -C "$backup_source" . \
		| pv "${progress_pv_args[@]}" \
		| gzip > "$tar_file"
		
# GET FILE INFO
	file_count=$(tar -tvzf "$tar_file" | awk '$1 ~ /^-/ { count++ } END { print count+0 }')
	file_size=$(stat -c "%s" "$tar_file" | numfmt --to=iec)		# get size in bytes, convert to readable format
	file_hidden=$(tar -tzf "$tar_file" | awk '!/\/$/ && /(^|\/)\.[^\/]+/ { count++ } END { print count+0 }')
	show_cursor

# SUCCESS TEXT
	log_success "backup - success"
	move_line_up 4
	
	printf '%s\n' "${GREEN}   ━━━━━━━━━━━━━━━━━━━━${RESET}"
	printf '%s\n' "${GREEN}${BOLD}   ✅ Backup completed${RESET}"
	printf '%s\n' "${GREEN}   ━━━━━━━━━━━━━━━━━━━━${RESET}"

	printf '%s\n' "${INFO}   📦 Archive:${RESET}  '$tar_file'"
	printf '%s\n' "${INFO}   🕒 Time:${RESET}	${timestamp//_/ at } "
	printf '%s' "${INFO}   📄 Files:${RESET}	$file_count (${file_hidden} hidden) "
	printf '\n%s\t%s\n\n' "${INFO}   💾 Size:${RESET}" "$file_size"
	
	press_any_key

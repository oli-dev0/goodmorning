#!/usr/bin/env bash

#	= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =	#
#																					#
#	BACKUP SCRIPT																	#
#	-------------																	#
#	Purpose:																		#
#	- Creates a compressed .tar.gz backup of the script's own directory			 	#
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
	load_libs styles animations math
	set_title "💾 BACKUP 💾"
	required_commands tar stat numfmt

# ASK
	clearscreen
	while true; do
		read -rp " ${BOLD}Do you want to make a backup?${RESET} [y/n] " backup_answer

		case "$backup_answer" in
			y|ye|yes|ok|k|"")
				break
				;;
			n|no|nop|nope)
				clear
				exit 0
				;;
			*)
				clearscreen
				printf ' %s\n\n' "$msg_invalid_input"
				;;
		esac
	done

# VARIABLES
	timestamp="$(date '+%Y-%m-%d_%H-%M')"
	tar_file="$BACKUP_DIR/$timestamp.tar.gz"

# PROGRESS ANIMATION
	clearscreen
	log_start "Backup started..."
	sleep 0.3
	clearscreen
	anim_status_bar "Backup in progress...  "; sleep 0.5
	printf " "

# MAKE BACKUP
	mkdir -p "$BACKUP_DIR"
	tar --exclude="./${BACKUP_DIR##*/}" --transform='s|^\./||' -czf "$tar_file" -C "$DIR_TO_BACKUP" .

# GET FILE INFO
	file_count=$(tar -tzf "$tar_file" | wc -l)
	file_size=$(stat -c "%s" "$tar_file" | numfmt --to=iec)							# get size in bytes, convert to readable format
	file_hidden=$(tar -tzf "$tar_file" | grep -c '/\.[^/]*$\|^\.[^/]*$' || true)	# need || true, or else grep will exit with 1 and trap ERR will trigger

# SUCCESS TEXT
	clearscreen
	log_success "backup - success"
	clearscreen
	printf '%s\n' "${GREEN}   ━━━━━━━━━━━━━━━━━━━━${RESET}"
	printf '%s\n' "${GREEN}${BOLD}   ✅ Backup completed${RESET}"
	printf '%s\n' "${GREEN}   ━━━━━━━━━━━━━━━━━━━━${RESET}"

	# printf '%s\n' "${BOLD}${BLUE}   📦 Folder:${RESET} $(basename "$BACKUP_DIR")"
	printf '%s\n' "${BOLD}${BLUE}   🕒 Time:${RESET}	${timestamp//_/ at } "
	printf '%s' "${BOLD}${BLUE}   📄 Files:${RESET}	$file_count - ${file_hidden} hidden "
	# [[ "$file_hidden" -eq 1 ]] && printf "file" || printf "files"
	printf '\n%s\t%s\n\n' "${BOLD}${BLUE}   💾 Size:${RESET}" "$file_size"
	
	hide_keyboard
	read -rn1 -p "${BLINK} Press any key to continue... ${RESET}"; clearline
	show_keyboard
	anim_moving_on
	clear

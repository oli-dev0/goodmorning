#!/usr/bin/env bash

# CONFIG
	source "$(dirname "${BASH_SOURCE[0]}")/../libs/bootstrap.sh"
	load_libs animations					# add lib names here
	set_title "☁️  NAS BACKUP SYNC ☁️"		# Adjust title
	required_commands 		 				# checks for required commands
	clearscreen 							# this is to show the title on startup
# ps: backup directories are set in config.sh

log_start "nas rsync - start folder checks"; clearscreen

# CHECK IF LOCAL BACKUP FOLDER EXISTS
	animation_spinner "Checking local backup folder... " 0.5 "${BOLD}"
	if [[ ! -d "$GM_LOCAL_BACKUP_DIR" ]]; then
		printf ' '
		log_error "local backup folder not found"; move_line_up
		printf '  📂 %sPath:%s %s\n\n' "${WARNING}" "${RESET}" "$GM_LOCAL_BACKUP_DIR"
		exit 1
	else
		move_line_up
		printf ' '
		log_success "Local folder exists"; move_line_up
	fi

# CHECK IF TARGET FOLDER EXISTS ON NAS
	animation_spinner "Checking NAS connection... " 0.5 "${BOLD}"
	if ! ssh nas 'test -d $NAS_PATH'; then
		printf ' '
		log_error "NAS backup folder not found or NAS is unreachable"; move_line_up
		printf '  📂 %sPath:%s %s\n\n' "${WARNING}" "${RESET}" "$GM_NAS_PATH"
		exit 1
	else
		move_line_up
		printf ' '
		log_success "Target folder exists"; move_line_up
	fi

# START RSYNC BACKUP
	log_start "nas rsync - backup started"; move_line_up 2
	animation_spinner "Syncing backups to NAS... " 1.5 "${BOLD}"

	# putting output in a variable to format later
	rsync_output="$(
	rsync -avh --ignore-existing --stats \
	"$GM_LOCAL_BACKUP_DIR" \
	"$GM_NAS_TARGET")"

	move_line_up
	printf ' '
	log_success "Backup sync complete"

# GET INFO
	# rsync stats
	while IFS= read -r line; do
		case "$line" in
			"Number of files:"*)
				total_files="${line#Number of files: }"
				;;
			"Number of created files:"*)
				created_files="${line#Number of created files: }"
				;;
			"Number of deleted files:"*)
				deleted_files="${line#Number of deleted files: }"
				;;
			"Number of regular files transferred:"*)
				transferred_files_count="${line#Number of regular files transferred: }"
				;;
			"Total file size:"*)
				total_size="${line#Total file size: }"
				;;
			"Total transferred file size:"*)
				transferred_size="${line#Total transferred file size: }"
				;;
		esac
	done <<< "$rsync_output"

	# rsync actual sent files
	transferred_files="$(echo "$rsync_output" | awk '
		/^sent / { exit }
		/^Number of files:/ { exit }
		NF && !/\/$/ && !/^sending incremental file list$/ {
		print "     " $0
		}
	')"
	[[ -z "$transferred_files" ]] && transferred_files="     --NONE--"

# SHOW INFO
	printf '%6sℹ️  Backup sync summary: %s\n'    "${BOLD}" "${RESET}"
	printf '%11s📁 Total files:%s     %s\n'      "${INFO}" "${RESET}" "$total_files"
	printf '%11s🆕 Created files:%s   %s\n'      "${INFO}" "${RESET}" "$created_files"
	printf '%11s🗑️  Deleted files:%s   %s\n'     "${INFO}" "${RESET}" "$deleted_files"
	printf '%11s📤 Sent files:%s      %s\n'      "${INFO}" "${RESET}" "$transferred_files_count"
	printf '%11s💿 Total size:%s      %s\n'      "${INFO}" "${RESET}" "$total_size"
	printf '%11s🛜 Sent size:%s       %s\n\n'    "${INFO}" "${RESET}" "$transferred_size"
	printf '%11s📄 Transferred files:%s\n%s\n\n' "${INFO}" "${RESET}" "$transferred_files"

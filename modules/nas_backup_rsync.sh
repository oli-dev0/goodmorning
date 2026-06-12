#!/usr/bin/env bash

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = #
#																					#
#	NAS BACKUP SYNC																	#
#	---------------																	#
#	Purpose:																		#
#	- Synchronizes local backup archives to a NAS using rsync over SSH				#
#	- Transfers only files that do not already exist on the NAS					 	#
# 																					#
#	Usage:																			#
#	./nas_backup_rsync.sh															#
#																					#
#	Configuration:																	#
#	- Backup and NAS settings are configured in config.sh							#
#	- Required settings include:													#
#	  GM_LOCAL_BACKUP_DIR	Local backup directory									#
#	  		  GM_NAS_HOST 	SSH host or alias										#
#			  GM_NAS_PATH	Destination directory on NAS							#
#	  		GM_NAS_TARGET 	Full rsync target										#
#																					#
#	Validation:																		#
#	- Verifies the local backup directory exists									#
#	- Verifies the NAS is reachable over SSH										#
#	- Verifies the target directory exists on the NAS								#
#	- Aborts immediately if any validation fails									#
#																					#
#	Synchronization:																#
#	- Uses rsync with archive mode (-a) and human-readable output (-h)				#
#	- Uses --ignore-existing to prevent overwriting existing backups				#
#	- Uses --stats to collect synchronization statistics							#
#	- Captures and formats rsync output for a clean summary							#
#																					#
#	Notes:																			#
#	- Existing backup archives on the NAS are preserved								#
#	- Temporary rsync logs are removed after execution								#
#	- Intended as the second stage of the backup workflow:							#
#		Local Backup  ->  NAS Synchronization										#
#																					#
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = #

# BOOTSTRAP
	source "$(dirname "${BASH_SOURCE[0]}")/../libs/bootstrap.sh"
	load_libs animations					# add lib names here
	set_title "☁️  NAS BACKUP SYNC ☁️"		# Adjust title
	required_commands ssh rsync 			# checks for required commands
# ps: backup directories are set in config.sh

# ASK
	ask_first "Do you want to rsync your backups to your NAS?"

log_start "nas rsync - start folder checks"; clearscreen

# CHECK IF LOCAL BACKUP FOLDER EXISTS
	animation_spinner "Checking local backup folder... "
	if [[ ! -d "$GM_LOCAL_BACKUP_DIR" ]]; then
		log_error "local backup folder not found"; move_line_up
		printf '  📂 %sPath:%s %s\n\n' "${WARNING}" "${RESET}" "$GM_LOCAL_BACKUP_DIR"
		exit 1
	else
		move_line_up
		log_success "Local folder exists"; move_line_up
	fi

# CHECK IF TARGET FOLDER EXISTS ON NAS
	animation_spinner "Checking NAS connection... "
	if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$GM_NAS_HOST" test -d "$GM_NAS_PATH"; then
		log_error "NAS backup folder not found or NAS is unreachable"; move_line_up
		printf '  📂 %sPath:%s %s\n\n' "${WARNING}" "${RESET}" "$GM_NAS_PATH"
		exit 1
	else
		move_line_up
		log_success "Target folder exists"; move_line_up
	fi

# START RSYNC BACKUP
	log_start "nas rsync - backup started"; move_line_up 2
	animation_spinner "Syncing backups to NAS... " 1

	# putting output in a variable to format later
	rsync_log="$(mktemp)" || { log_error "cannot create temporary rsync log"; exit 1; }

	if ! rsync -avh --ignore-existing --stats \
	"$GM_LOCAL_BACKUP_DIR" \
	"$GM_NAS_TARGET" \
	> "$rsync_log"; then
		rm -f "$rsync_log"
		log_error "rsync failed"
		exit 1
	fi

	rsync_output="$(< "$rsync_log")"
	rm -f "$rsync_log"

	move_line_up
	printf '\n '
	log_success "Backup sync complete"

# GET INFO
	# defaults in case rsync stats output changes
	total_files="--"
	created_files="--"
	transferred_files_count="--"
	total_size="--"
	transferred_size="--"

	# rsync stats
	while IFS= read -r line; do
		case "$line" in
			"Number of files:"*) total_files="${line#Number of files: }" ;;
			"Number of created files:"*) created_files="${line#Number of created files: }" ;;
			"Number of regular files transferred:"*) transferred_files_count="${line#Number of regular files transferred: }" ;;
			"Total file size:"*) total_size="${line#Total file size: }" ;;
			"Total transferred file size:"*) transferred_size="${line#Total transferred file size: }" ;;
		esac
	done <<< "$rsync_output"

	# rsync sent filenames
	transferred_files_list="$(awk '
		/^sent / { exit }
		/^Number of files:/ { exit }
		NF && !/\/$/ && !/^sending incremental file list$/ {
		print "       " $0
		}
		' <<< "$rsync_output")"

	[[ -z "$transferred_files_list" ]] && transferred_files_list="       --NONE--"

# SHOW INFO
	printf '%6sℹ️  Backup sync summary: %s\n'    "${BOLD}" "${RESET}"
	printf '%11s📁 Total files:%s     %s\n'      "${INFO}" "${RESET}" "$total_files"
	printf '%11s🆕 Created files:%s   %s\n'      "${INFO}" "${RESET}" "$created_files"
	printf '%11s📤 Sent files:%s      %s\n'      "${INFO}" "${RESET}" "$transferred_files_count"
	printf '%11s💿 Total size:%s      %s\n'      "${INFO}" "${RESET}" "$total_size"
	printf '%11s🛜 Sent size:%s       %s\n\n'    "${INFO}" "${RESET}" "$transferred_size"
	printf '%11s📄 Transferred files:%s\n%s\n\n' "${INFO}" "${RESET}" "$transferred_files_list"

	press_any_key

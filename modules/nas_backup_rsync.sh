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
#	- Polls NAS directory growth for a live overall transfer progress bar			#
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
	readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	source "$SCRIPT_DIR/../libs/bootstrap.sh" || { echo -e "\n ❌ Fatal: bootstrap failed \n"; exit 1; }
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
		press_any_key; exit 1
	else
		move_line_up
		log_success "Local folder exists"; move_line_up
	fi

# CHECK IF TARGET FOLDER EXISTS ON NAS
	animation_spinner "Checking NAS connection... "
	if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$GM_NAS_HOST" test -d "$GM_NAS_PATH"; then
		echo
		log_error "NAS backup folder not found or NAS is unreachable"; move_line_up
		printf '  📂 %sPath:%s %s\n\n' "${WARNING}" "${RESET}" "$GM_NAS_PATH"
		press_any_key; exit 1
	else
		move_line_up
		log_success "Target folder exists"; move_line_up
	fi

# START RSYNC BACKUP
	log_start "nas rsync - backup started"; move_line_up 2; echo

	render_rsync_progress()
	{
		local percent="${1:-0}"
		local width=30
		local filled empty bar fill_space empty_space

		(( percent < 0 )) && percent=0
		(( percent > 100 )) && percent=100

		filled=$(( percent * width / 100 ))
		empty=$(( width - filled ))

		printf -v fill_space '%*s' "$filled" ''
		printf -v empty_space '%*s' "$empty" ''
		bar="${fill_space// /#}${empty_space// /-}"

		clearline
		printf ' %sSyncing backups to NAS...%s [%s] %3d%%\r' "${INFO}" "${RESET}" "$bar" "$percent"
	}

	# putting output in a variable to format later
	rsync_log="$(mktemp)" || { log_error "cannot create temporary rsync log"; exit 1; }
	trap 'rm -f "$rsync_log"; cleanup' EXIT

	hide_cursor

	remote_path_quoted="$(printf '%q' "$GM_NAS_PATH")"
	remote_start_kb="$(ssh "$GM_NAS_HOST" "du -sk $remote_path_quoted 2>/dev/null | awk '{ print \$1 }'")"
	[[ "$remote_start_kb" =~ ^[0-9]+$ ]] || remote_start_kb=0

	transfer_total_bytes="$(
		rsync -an --ignore-existing --stats \
			"$GM_LOCAL_BACKUP_DIR" \
			"$GM_NAS_TARGET" |
			awk -F': ' '
				/^Total transferred file size:/ {
					gsub(/[^0-9]/, "", $2)
					print $2 + 0
				}
			'
	)"

	transfer_total_bytes="${transfer_total_bytes:-0}"
	render_rsync_progress 0

	rsync -avh --ignore-existing --stats \
		"$GM_LOCAL_BACKUP_DIR" \
		"$GM_NAS_TARGET" \
		> "$rsync_log" 2>&1 &
	rsync_pid=$!

	while kill -0 "$rsync_pid" 2>/dev/null; do
		if (( transfer_total_bytes > 0 )); then
			remote_current_kb="$(ssh "$GM_NAS_HOST" "du -sk $remote_path_quoted 2>/dev/null | awk '{ print \$1 }'")"
			[[ "$remote_current_kb" =~ ^[0-9]+$ ]] || { sleep 0.5; continue; }

			transfer_done_bytes=$(( (remote_current_kb - remote_start_kb) * 1024 ))
			transfer_percent=$(( transfer_done_bytes * 100 / transfer_total_bytes ))
			render_rsync_progress "$transfer_percent"
		fi
		sleep 0.5
	done

	if ! wait "$rsync_pid"; then
		log_error "rsync failed"
		exit 1
	fi

	render_rsync_progress 100

	rsync_output="$(< "$rsync_log")"

	clearline
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
	show_cursor

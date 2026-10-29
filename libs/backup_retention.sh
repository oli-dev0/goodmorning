#!/usr/bin/env bash
# Keep only the newest dated archives of one kind: Coding archives (no prefix) or a helper backup
# such as omp_<timestamp>.tar.gz (prefix "omp"). Other files are untouched.
# Also executed on the NAS via bash -s, so this script must remain self-contained.
set -euo pipefail
export LC_ALL=C

backup_dir=${1:?backup directory required}
keep=${2:?retention count required}
[[ "$keep" =~ ^[1-9][0-9]*$ ]] || { echo 'Invalid backup retention count' >&2; exit 1; }
prefix=${3:-}
[[ -z "$prefix" || "$prefix" =~ ^[a-z]+$ ]] || { echo 'Invalid backup prefix' >&2; exit 1; }
stamp='[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}(-[0-9]{2})?\.tar\.gz$'
if [[ -n "$prefix" ]]; then pattern="^${prefix}_${stamp}"; else pattern="^${stamp}"; fi
cd -- "$backup_dir"
shopt -s nullglob

archives=()
# Bash glob order sorts these timestamped names from oldest to newest.
for archive in *.tar.gz; do
    if [[ -f "$archive" && ! -L "$archive" && "$archive" =~ $pattern ]]; then
        archives+=("$archive")
    fi
done

remove_count=$(( ${#archives[@]} - keep ))
for (( index=0; index<remove_count; index++ )); do
    rm -- "${archives[index]}"
done

#!/usr/bin/env bash

# AVOID MULTIPLE SOURCING
	[[ -n "${_MATH_LOADED:-}" ]] && return 0		# if var is not empty, then return (close the current "source" of lib)
	_MATH_LOADED=1 									# if its empty, continue sourcing, and set var to 1

# IS THIS NUMBER POSITIVE
	is_positive() {
		awk "BEGIN { exit !($1 > 0) }"
	}
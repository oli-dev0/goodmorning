#!/usr/bin/env bash

# BOOTSTRAP
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	readonly SCRIPT_DIR
	source "$SCRIPT_DIR/../libs/bootstrap.sh" || { echo -e "\n ❌ Fatal: bootstrap failed \n"; exit 1; }
	set_title "🪙  CRYPTO 🪙"
	required_commands jq

crypto_validate_config()
{
	[[ -n "${GM_CRYPTO_API:-}" ]] || {
		clearscreen
		log_error "crypto - CoinGecko API key is not configured"
		return 1
	}

	if [[ -z "${GM_CRYPTO_FAVORITES+x}" ]] || (( ${#GM_CRYPTO_FAVORITES[@]} == 0 )); then
		clearscreen
		log_error "crypto - no CoinGecko IDs are configured"
		return 1
	fi
}

crypto_verify_json()
{
	local json="${1:-}"

	[[ -n "$json" ]] || {
		clearscreen
		log_error "crypto - CoinGecko returned an empty response"
		return 1
	}

	jq -e 'type == "array"' <<< "$json" >/dev/null 2>&1 || {
		clearscreen
		log_error "crypto - CoinGecko returned an invalid response"
		return 1
	}
}

crypto_fetch()
{
	local ids
	local url
	declare -g crypto_json

	local IFS=,
	ids="${GM_CRYPTO_FAVORITES[*]}"
	url="https://api.coingecko.com/api/v3/coins/markets?vs_currency=$(url_encode "$GM_CRYPTO_BASE_CURRENCY")&ids=$(url_encode "$ids")&price_change_percentage=24h%2C7d%2C30d&precision=full"

	check_internet || return 1
	anim_status_bar "Fetching crypto data..."
	clearscreen

	crypto_json="$(http_get --header "x-cg-demo-api-key: ${GM_CRYPTO_API}" "$url")" || {
		local http_status=$?
		log_error "crypto - CoinGecko request failed (exit status: ${http_status})"
		return 1
	}

	crypto_verify_json "$crypto_json" || return 1
}

crypto_print_change()
{
	local value="${1:-N/A}"
	local color=""

	case "$value" in
		+*) color="$GREEN" ;;
		-*) color="$RED" ;;
	esac

	if [[ -n "$color" ]]; then
		printf ' %s%12s%s' "$color" "$value" "$RESET"
	else
		printf ' %12s' "$value"
	fi
}

crypto_display()
{
	local currency="${GM_CRYPTO_BASE_CURRENCY^^}"
	local coin_id
	local row
	local name price day week month

	clearscreen
	printf ' %s\n' "${BOLD}Tracked crypto${RESET}"
	printf ' %s\n' "${DIM}Prices in ${currency}${RESET}"
	printf '\n'
	printf ' %s%-32s%s %s%18s%s %s%12s%s %s%12s%s %s%12s%s\n' \
		"$BOLD" "Coin" "$RESET" \
		"$BOLD" "Price" "$RESET" \
		"$BOLD" "1D" "$RESET" \
		"$BOLD" "7D" "$RESET" \
		"$BOLD" "1M" "$RESET"
	printf ' %s\n' "${DIM}────────────────────────────────────────────────────────────────────────────────────────────${RESET}"

	for coin_id in "${GM_CRYPTO_FAVORITES[@]}"; do
		row="$(jq -r --arg id "$coin_id" '
			([.[] | select(.id == $id)] | first) as $coin |
			if $coin == null then
				[$id, "N/A", "N/A", "N/A", "N/A"]
			else
				def change($value):
					if $value == null then "N/A"
					else ($value | round) as $rounded |
						if $rounded > 0 then "+" + ($rounded | tostring) + "%"
						elif $rounded < 0 then ($rounded | tostring) + "%"
						else "0%"
						end
					end;
				[
					(($coin.name // $id) + (if $coin.symbol then " (" + ($coin.symbol | ascii_upcase) + ")" else "" end)),
					($coin.current_price // "N/A" | tostring),
					change($coin.price_change_percentage_24h_in_currency),
					change($coin.price_change_percentage_7d_in_currency),
					change($coin.price_change_percentage_30d_in_currency)
				]
			end | @tsv
		' <<< "$crypto_json")"

		IFS=$'\t' read -r name price day week month <<< "$row"
		if [[ "$price" != "N/A" ]]; then
			LC_NUMERIC=C printf -v price '%.2f' "$price"
		fi

		printf ' %-32s %18s' "$name" "$price"
		crypto_print_change "$day"
		crypto_print_change "$week"
		crypto_print_change "$month"
		printf '\n'
	done
	printf '\n'
}

crypto_main()
{
	crypto_validate_config || {
		press_any_key
		return 0
	}

	crypto_fetch || {
		press_any_key
		return 0
	}

	crypto_display
	press_any_key
}

crypto_main

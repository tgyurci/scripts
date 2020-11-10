#!/usr/bin/env zsh

typeset -i dice_count roll_times

if [[ "$#" -eq 0 ]]; then
	dice_count="1"
	roll_times="1"
elif [[ "$#" -eq 1 ]]; then
	dice_count="1"
	roll_times="$1"
elif [[ "$#" -eq 2 ]]; then
	dice_count="$1"
	roll_times="$2"
else 
	echo "Usage: $0 [dice_count] [roll_times]"
	exit 1
fi

if [[ "$roll_times" -le 0 ]]; then
	echo "Roll times must be greather than 0!" >&2
	exit 1
fi

if [[ "$dice_count" -le 0 ]]; then
	echo "Dice count count must be greather than 0!" >&2
	exit 1
fi

roll_dices() {
	local dice_count="$1"

	while [[ "$dice_count" -gt 0 ]]; do
		printf "%s" "$(((RANDOM % 6) + 1))"
		dice_count="$((dice_count - 1))"
	done
}

typeset -a rolls
while [[ "$roll_times" -gt 0 ]]; do
	RANDOM="$RANDOM"

	rolls+=($(roll_dices "$dice_count"))
	roll_times="$((roll_times - 1))"
done

printf "%s\n" "$rolls"

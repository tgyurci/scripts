#!/bin/sh

# Prefixes size of each input line
# Input is output of grep -rn:
# 
# grep -rn '^' file ... | line_size.sh

while read -r line; do
	printf "%s %s\n" "$(printf "%s\n" "$line" | cut -d ":" -f 3 | wc -c)" "$line"
done

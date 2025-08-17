#!/usr/bin/env bash
#
#  ________    _       
# |_   __  |  / \        Fredrik Andersson 
#   | |_ \_| / _ \       https://github.com/fanderssondev
#   |  _|   / ___ \      2025-08-18
#  _| |_  _/ /   \ \_  
# |_____||____| |____| 
#

set -euo pipefail

# Get a list of items as "id<TAB>title"
items=$(op item list --format=json | jq -r '.[] | "\(.id)\t\(.title)"')

# Use fzf to select, with preview showing the item details
item_line=$(echo "$items" | fzf \
  --with-nth=2.. \
  --preview 'op item get $(echo {} | cut -f1) --format=json | jq .')

# Exit if user cancelled
[ -z "$item_line" ] && exit 1

# Extract the ID (first field)
item_id=$(echo "$item_line" | cut -f1)

# Handle --copy and --copy=<field>
if [[ "${1:-}" =~ ^--copy ]]; then
  # Default field = password
  field="password"
  if [[ "$1" == *=* ]]; then
    field="${1#*=}"
  fi

  value=$(op item get "$item_id" --reveal --format=json \
    | jq -r --arg field "$field" '.fields[] | select(.id==$field) | .value')

  if [[ -n "$value" && "$value" != "null" ]]; then
    echo -n "$value" | xclip -selection clipboard
    echo "$field copied to clipboard ✅"
  else
    echo "Field '$field' not found ❌"
    exit 1
  fi

  exit 0
fi

# Otherwise, run normal get with all passed flags
op item get "$item_id" "$@"


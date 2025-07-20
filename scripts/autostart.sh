#!/bin/bash
# 
#  ________    _       
# |_   __  |  / \        Fredrik Andersson 
#   | |_ \_| / _ \       https://github.com/fanderssondev
#   |  _|   / ___ \      2025-07-20
#  _| |_  _/ /   \ \_  
# |_____||____| |____| 
#
# Script name: fzauto
# Description: Add and remove programs to autostart directory.
# Dependencies: fzf
#
# This script is based on: 
# GitLab: https://www.gitlab.com/dwt1/fzscripts
# License: https://www.gitlab.com/dwt1/fzscripts
# Contributors: Derek Taylor

# Set with the flags "-e", "-u","-o pipefail" cause the script to fail
# if certain things happen, which is a good thing.  Otherwise, we can
# get hidden bugs that are hard to discover.
set -euo pipefail

# The FMENU variable contains the 'fzf' command with our settings.
# Note that the last setting is 'prompt' which is left empty.
# You add the prompt when you invoke $FMENU. For example: $FMENU "my prompt"
FMENU="fzf --header=$(basename "$0") \
          --layout=reverse \
          --exact \
          --border=bold \
          --border=rounded \
          --margin=5% \
          --multi \
          --color=dark \
          --height=95% \
          --info=hidden \
          --header-first \
          --bind change:top \
          --prompt"

autostart_files=()
if [ -d "$HOME/.config/autostart" ]; then
  autostart_files+=($(find "$HOME/.config/autostart" -type f -printf "%f\n" 2>/dev/null))
fi

desktop_files=()
IFS=':' read -ra DIRS <<< "$XDG_DATA_DIRS"
for dir in "${DIRS[@]}"; do
  app_dir="$dir/applications"
  if [ -d "$app_dir" ]; then
    while IFS= read -r file; do
      desktop_files+=("$file")
    done < <(find "$app_dir" -type f -name '*.desktop' 2>/dev/null)
  fi
done

listauto() {
  tput setaf 6 bold
  echo "Programs currently in autostart directory:"
  tput sgr0
  tree ~/.config/autostart 2>/dev/null | grep -e '├' -e '└' --color=never || echo "(empty)"
}

addauto() {
  mkdir -p "$HOME/.config/autostart"

  selected_file=$($FMENU "Add program to autostart: " < <(printf "%s\n" "${desktop_files[@]}"))
  if [[ -n "$selected_file" ]]; then
    for i in $selected_file; do
      tput setaf 5 bold
      echo -n "✓ $(basename "$i")"
      cp "$i" "$HOME/.config/autostart/"
      tput sgr0
      echo " added to autostart."
    done
  else
    echo "No selection made."
  fi
}

rmauto() {
  selected_file=$($FMENU "Remove program from autostart: " < <(printf "%s\n" "${autostart_files[@]}"))
  if [[ -n "$selected_file" ]]; then
    for i in $selected_file; do
      tput setaf 1 bold
      echo -n "✗ $i"
      rm -f "$HOME/.config/autostart/$i"
      tput sgr0
      echo " removed from autostart."
    done
  else
    echo "No selection made."
  fi
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTION]

Manage autostart programs via fzf.

Options:
  -a    Add programs to autostart
  -r    Remove programs from autostart
  -l    List autostart contents
  -h    Show this help message

If run without arguments, an interactive menu appears.
EOF
}

while getopts "alrh" arg; do
  case "$arg" in
    a) addauto; listauto; exit 0 ;;
    l) listauto; exit 0 ;;
    r) rmauto; listauto; exit 0 ;;
    h) show_help; exit 0 ;;
    *) echo "Invalid option: -$OPTARG"; show_help; exit 1 ;;
  esac
done

if [ $# -eq 0 ]; then
  options=(
    "Add a program to autostart"
    "Remove a program from autostart"
    "List contents of autostart directory"
    "Show help"
    "Quit"
  )
  menu=$($FMENU "What do you want to do? " < <(printf "%s\n" "${options[@]}"))
  case "$menu" in
    "Add a program to autostart") exec "$0" -a ;;
    "Remove a program from autostart") exec "$0" -r ;;
    "List contents of autostart directory") exec "$0" -l ;;
    "Show help") exec "$0" -h ;;
    "Quit") exit 0 ;;
  esac
fi


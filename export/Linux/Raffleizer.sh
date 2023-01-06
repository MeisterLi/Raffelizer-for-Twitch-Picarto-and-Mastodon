#!/bin/sh
echo -ne '\033c\033]0;Raffelizer\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Raffleizer.x86_64" "$@"

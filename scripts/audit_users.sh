#!/bin/bash

# Author:        Atharv Sharma
# Date Created:  13/09/2025
# Date Modified: 13/09/2025
#
# Description: 
# Produces user_audit.csv with username, uid, groups, last log, passwd_state, lastchg_days

set -euo pipefail

OUT="users_audit.csv"

# Print header in CSV
printf "%-15s %-7s %-7s %-20s %-20s %-15s %-20s %-25s %-12s %-15s\n" \
"username" "uid" "gid" "gecos" "home" "shell" "groups" "lastlog" "passwd_state" "lastchg_days" >"$OUT"

get_lastlog() {
  local u=$1
  lastlog -u "$u" | awk 'NR==2 { $1=""; sub(/^ +/,""); print $0 }' 2>/dev/null || echo "no-lastlog"
}

for u in $(awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd); do
  IFS=: read -r name passwd uid gid gecos home shell <<<"$(getent passwd "$u")"
  groups=$(id -nG "$u" 2>/dev/null | tr ' ' ';')
  lastlog=$(get_lastlog "$u")
  passwd_state=$(passwd -S "$u" 2>/dev/null | awk '{print $2" "$3}' || echo "N/A")
  lastchg_raw=$(chage -l "$u" 2>/dev/null | awk -F: '/Last password change/{print $2}' | xargs -I{} echo "{}" 2>/dev/null || echo "never")

  if [[ "$lastchg_raw" == "never" ]]; then
    lastchg_days="never"
  else
    if date -d "$lastchg_raw" >/dev/null 2>&1; then
      lastchg_ts=$(date -d "$lastchg_raw" +%s)
      lastchg_days=$(( ( $(date +%s) - lastchg_ts ) / 86400 ))
    else
      lastchg_days="unknown"
    fi
  fi

  # Append formatted row to CSV
  printf "%-15s %-7s %-7s %-20s %-20s %-15s %-20s %-25s %-12s %-15s\n" \
  "$name" "$uid" "$gid" "$gecos" "$home" "$shell" "$groups" "$lastlog" "$passwd_state" "$lastchg_days" >>"$OUT"
done

echo "Wrote $OUT"

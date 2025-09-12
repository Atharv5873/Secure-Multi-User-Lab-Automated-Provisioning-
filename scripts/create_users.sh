#!/bin/bash

# Author:        Atharv Sharma
# Date Created:  13/09/2025
# Date Modified: 13/09/2025

# Description: 
# Creates Users from CSV or YAML mainnnfest.
# Defualt iS DRY-RUN. Use --apply to make changes.

# CSV Format (colon-separated):
# username:role:shell:extra_group1,extra_group2

# YAML Format (requires yq):
# users:
# - username: atharv
#	role: admin
#	shell: /bin/bash
#	extras: [git,build]

# SECURITY: This script has a temporary password for demo only. Do not use in production.

set -euo pipefail

MANIFEST=""
APPLY=false
DRY_RUN=true
SUDOERS_TEMPLATE=""

usage() {
	cat <<EOF
Usage: sudo $0 --manifest <file> [--apply] [--sudoers <file>]
Options:
  --manifest <file>     CSV or YAML manifest (required)
  --apply               Actually apply changes (default is dry-run)
  --sudoers <file>      Optional sudoers snippet template to install in /etc/sudoers.d/
  -h|--help             Show help
EOF
	exit 1
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--manifest) MANIFEST="$2";shift 2;;
		--apply) APPLY=true; DRY_RUN=false; shift;;
		--sudoers) SUDOERS_TEMPLATE="$2"; shift 2;;
		-h|--help) usage;;
		*) echo "Unknown arg: $1";usage;;
	esac
done

if [ -z "$MANIFEST" ]; then usage; fi

require_root() {
	if [ "$(id -u)" -ne 0 ]; then
		echo "ERROR: must be run as root (use sudo)"; exit 2
	fi
}

require_root

saftey_check() {
	if [ -f /.dockerenv ]; then
		echo "INFO: running in container"
		return
	fi
	if grep -qE 'container|lxc|docker' /proc/1/cgroup 2>/dev/null; then
		echo "INFO: running in container-ish environment"
		return
	fi
	if [ -f /sys/class/dmi/id/product_name ]; then
		product=$(cat /sys/class/dmi/id/product_name)
		if echo "$product" | grep -qiE 'vbox|virtualbox|vmware|kvm|qemu'; then
			echo "INFO: VM product detected: $product"
			return
		fi
	fi
	echo "WARNING: No VM detected. This script is for disposable test VMs. Proceed only if intentional."
}

saftey_check

run(){
	if $DRY_RUN; then
		echo "[DRY-RUN] $*"
	else
		echo "[RUN] $*"
		eval "$@"
	fi
}

add_group_if_missing() {
	local g=$1
	if ! getent group "$g" > /dev/null; then
		run "groupadd --system $g"
	fi
}		

create_user() {
  local user=$1
  local primary_group=$2
  local shell=$3
  local extras=$4
  local tmp_pass=$5

  
  add_group_if_missing "$primary_group"

  local sup_groups=""
  if [ -n "$extras" ]; then
    sup_groups="$extras"
    
    IFS=',' read -ra extra_array <<< "$extras"
    for g in "${extra_array[@]}"; do
      add_group_if_missing "$g"
    done
  fi

  if id "$user" &>/dev/null; then
    echo "User $user exists — updating attributes"
    if [ -n "$sup_groups" ]; then run "usermod -aG $sup_groups $user"; fi
    run "usermod -s $shell $user"
  else
    if [ -n "$sup_groups" ]; then
      run "useradd -m -s $shell -g $primary_group -G $sup_groups $user"
    else
      run "useradd -m -s $shell -g $primary_group $user"
    fi
  fi

  if [ -n "$tmp_pass" ]; then
    run "echo \"$user:$tmp_pass\" | chpasswd"
    echo "Note: temporary password set for $user (lab-only)."
  fi
}


install_sudoers_snippet() {
  local snippet_content="$1"
  local dest="/etc/sudoers.d/99-lab-admins"
  local tmpfile
  tmpfile=$(mktemp)
  echo "$snippet_content" >"$tmpfile"
  if visudo -cf "$tmpfile"; then
    run "install -m 0440 $tmpfile $dest"
    echo "Installed sudoers snippet to $dest"
  else
    echo "ERROR: sudoers snippet validation failed; not installed."
    rm -f "$tmpfile"
    exit 3
  fi
  rm -f "$tmpfile"
}



entries=()
if [[ "$MANIFEST" =~ \.ya?ml$ ]]; then
  if ! command -v yq >/dev/null 2>&1; then
    echo "ERROR: YAML manifest requires 'yq' (https://github.com/mikefarah/yq)." >&2
    exit 4
  fi
  while IFS= read -r line; do entries+=("$line"); done < <(yq -r '.users[] | "\(.username):\(.role):\(.shell):\(.extras | join(","))"' "$MANIFEST")
else
  while IFS= read -r line; do
    [[ "$line" =~ ^\s*# ]] && continue
    [[ -z "$line" ]] && continue
    entries+=("$line")
  done < "$MANIFEST"
fi

if [ "${#entries[@]}" -eq 0 ]; then
  echo "No entries found in manifest."
  exit 0
fi



if [ -z "$SUDOERS_TEMPLATE" ]; then
  read -r -d '' sudoers_snip <<'EOF' || true
%admins ALL=(ALL) NOPASSWD: /usr/bin/systemctl
EOF
else
  sudoers_snip=$(cat "$SUDOERS_TEMPLATE")
fi

TMP_PASSWORD="temporarypassword" 

echo "Found ${#entries[@]} manifest entries."

for entry in "${entries[@]}"; do
  IFS=':' read -r username role shell extras <<<"$entry"
  username=${username:-}
  role=${role:-users}
  shell=${shell:-/bin/bash}
  extras=${extras:-}

  if [ -z "$username" ]; then
    echo "Skipping empty username entry."
    continue
  fi

  primary_group="$role"
  echo "Processing: $username (role=$role) shell=$shell extras=$extras"

  create_user "$username" "$primary_group" "$shell" "$extras" "$TMP_PASSWORD"

  if [ "$role" = "admins" ]; then
    run "usermod -aG admins $username"
  fi
done

install_sudoers_snippet "$sudoers_snip"

echo "Finished. If dry-run, no changes were applied. Re-run with --apply to enact changes."

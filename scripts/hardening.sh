#!/bin/bash

# Author:        Atharv Sharma
# Date Created:  13/09/2025
# Date Modified: 13/09/2025

# Description:
# This Script sets global umask, suggests/applies login.defs changes and shows pwquality suggestions.
# Default: dry-run. Use --apply to write files.

APPLY=false
DRY_RUN=true
for arg in "$@"; do
	case "$arg" in
		--apply) APPLY=true; DRY_RUN=false;;
		-h|--help) echo "Usage: $0 [--apply]"; exit 0;;
	esac
done

run() {
	if $DRY_RUN; then
		echo "[DRY-RUN] $*"
	else
		echo "[RUN] $*"
		eval "$@"
	fi
}

UMASK_FILE="/etc/profile.d/99-umask.sh"
UMASK_VALUE="027"

echo "Will set global umask to $UMASK_VALUE in $UMASK_FILE"
run "cat >$UMASK_FILE <<EOF
# Global umask for interactive shells (set conservatively for lab)
umask $UMASK_VALUE
EOF
"

run "chmod 644 $UMASK_FILE"

LOGIN_DEFS="/etc/login.defs"

echo "Suggested login.defs changes (PASS_MAX_DAYS, PASS_MIN_DAYS, PASS_WARN_AGE)."
cat <<'EOF'
PASS_MAX_DAYS   90
PASS_MIN_DAYS   1
PASS_WARN_AGE   7
UID_MIN         1000
EOF

if ! $DRY_RUN; then
  cp -a "$LOGIN_DEFS" "${LOGIN_DEFS}.bak.$(date +%s)"
  sed -i -E 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' "$LOGIN_DEFS" || echo "PASS_MAX_DAYS 90" >> "$LOGIN_DEFS"
  sed -i -E 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' "$LOGIN_DEFS" || echo "PASS_MIN_DAYS 1" >> "$LOGIN_DEFS"
  sed -i -E 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' "$LOGIN_DEFS" || echo "PASS_WARN_AGE 7" >> "$LOGIN_DEFS"
  echo "Applied changes to $LOGIN_DEFS (backup created)."
fi

echo "pwquality suggestions (see /etc/security/pwquality.conf):"
cat <<'EOF'
minlen = 12
dcredit = -1
ucredit = -1
ocredit = -1
lcredit = -1
EOF

echo "PAM changes are not auto-applied by this script. See docs/pam-pwquality.md to carefully apply."
echo "To force password expiry for a user (example):"
echo "  sudo chage -M 90 -m 1 -W 7 username"
echo "To expire password now:"
echo "  sudo passwd --expire username"

echo "hardening.sh finished (dry-run mode if no --apply)."

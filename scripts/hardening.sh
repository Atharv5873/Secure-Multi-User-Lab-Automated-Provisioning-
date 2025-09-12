#!/bin/bash

# Author:        Atharv Sharma
# Date Created:  13/09/2025
# Date Modified: 13/09/2025
#
# Description:
# This Script sets global umask, suggests/applies login.defs changes 
# and shows pwquality suggestions.
# Default: dry-run. Use --apply to write files.

APPLY=false
DRY_RUN=true
for arg in "$@"; do
	case "$arg" in
		--apply) APPLY=true; DRY_RUN=false;;
		-h|--help) echo "Usage: $0 [--apply]"; exit 0;;
	esac
done

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

section() {
  echo -e "\n${BOLD}${CYAN}==> $1${RESET}"
}

run() {
	if $DRY_RUN; then
		echo -e "[${YELLOW}DRY-RUN${RESET}] $*"
	else
		echo -e "[${GREEN}RUN${RESET}] $*"
		eval "$@"
	fi
}

UMASK_FILE="/etc/profile.d/99-umask.sh"
UMASK_VALUE="027"

section "Global umask"
echo -e "Will set global umask to ${BOLD}$UMASK_VALUE${RESET} in ${BOLD}$UMASK_FILE${RESET}"
run "cat >$UMASK_FILE <<EOF
# Global umask for interactive shells (set conservatively for lab)
umask $UMASK_VALUE
EOF
"
run "chmod 644 $UMASK_FILE"

LOGIN_DEFS="/etc/login.defs"

section "Suggested login.defs changes"
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
  echo -e "${GREEN}✔ Applied changes to $LOGIN_DEFS (backup created).${RESET}"
fi

section "pwquality suggestions"
cat <<'EOF'
minlen = 12
dcredit = -1
ucredit = -1
ocredit = -1
lcredit = -1
EOF

section "PAM & password expiry notes"
echo -e "${YELLOW}⚠ PAM changes are not auto-applied by this script.${RESET}"
echo "See docs/pam-pwquality.md to carefully apply."
echo
echo "Examples:"
echo "  ${BOLD}sudo chage -M 90 -m 1 -W 7 username${RESET}   # Set expiry rules for user"
echo "  ${BOLD}sudo passwd --expire username${RESET}        # Expire password immediately"

section "Script finished"
if $DRY_RUN; then
  echo -e "${YELLOW}Dry-run mode: no files were modified.${RESET}"
else
  echo -e "${GREEN}All changes applied successfully.${RESET}"
fi

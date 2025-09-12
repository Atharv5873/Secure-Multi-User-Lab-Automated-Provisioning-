# Password policy guidance

Recommended conservative defaults for labs:
- PASS_MAX_DAYS   90
- PASS_MIN_DAYS   1
- PASS_WARN_AGE   7

Set in `/etc/login.defs`. For stronger policies, use `pam_pwquality` (`/etc/security/pwquality.conf`) and PAM stack updates.

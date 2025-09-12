# PAM / pwquality suggestions (careful)

1. Install required package (Debian/Ubuntu):
   sudo apt-get install libpam-pwquality

2. Edit `/etc/security/pwquality.conf`:
   minlen = 12
   dcredit = -1
   ucredit = -1
   ocredit = -1
   lcredit = -1

3. Ensure PAM includes pam_pwquality.so in `/etc/pam.d/common-password` like:
   password requisite pam_pwquality.so retry=3

**WARNING**: Mistakes here can lock out users. Always test in a VM.

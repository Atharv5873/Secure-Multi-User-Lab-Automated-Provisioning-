# sudoers examples

# admins can run systemctl without password
%admins ALL=(ALL) NOPASSWD: /usr/bin/systemctl

# ops group can run apt and journalctl (with password)
%ops ALL=(ALL) /usr/bin/apt,/usr/bin/journalctl

# Place a file in /etc/sudoers.d/ and set perms:
sudo install -m 0440 myfile /etc/sudoers.d/99-myfile
# Validate:
visudo -cf /etc/sudoers.d/99-myfile

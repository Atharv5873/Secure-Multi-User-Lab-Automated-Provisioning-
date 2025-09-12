# Cheatsheet 2 — User Account Management & File Permissions

## Users
- Add: `useradd -m -s /bin/bash -g group -G extra1,extra2 username`
- Set password: `passwd username` or `echo 'user:pass' | chpasswd`
- Modify: `usermod -aG group user`
- Delete: `userdel -r username` (removes home)

## Groups
- Create: `groupadd name`
- List: `getent group`
- Primary vs supplementary: `-g` sets primary, `-G` sets supplementary.

## Sudoers
- Put snippets in `/etc/sudoers.d/` with 0440 perms.
- Validate: `visudo -cf /etc/sudoers.d/99-file`
- Example: `%admins ALL=(ALL) NOPASSWD: /usr/bin/systemctl`

## File perms
- Numeric: `chmod 640 file` -> owner rw, group r, others none
- View: `ls -l file` or `stat file`

## umask
- `umask 027` -> files 640, dirs 750
- Set globally: `/etc/profile.d/99-umask.sh` containing `umask 027`

## SUID/SGID/Sticky
- SUID: `chmod u+s /bin/someprog` (runs with owner privileges)
- SGID on dir: `chmod g+s /shared` -> new files inherit dir's group
- Sticky: `chmod +t /tmp` -> users can only remove their own files

## Audit
- Password state: `passwd -S username`
- Last login: `lastlog -u username`
- Password aging: `chage -l username`

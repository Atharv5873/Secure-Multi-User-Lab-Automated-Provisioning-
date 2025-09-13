# Secure Multi-User Lab: Automated Provisioning
Automates secure multi-user provisioning, sudo policy enforcement, hardening, and auditing in a disposable Linux lab environment.

## Project Overview

This project demonstrates:

- **Automated user creation** from CSV/YAML manifests with role-based primary and secondary groups.  
- **Sudoers snippet deployment** for admin users.  
- **System hardening** via global umask and password policy suggestions.  
- **User auditing** generating detailed `users_audit.csv` including last login, group membership, password state, and days since last password change.  
- **Lab-friendly setup**: Safe to run in disposable VMs or containers.

This repo also includes a **cheatsheet** for key Linux concepts:  
User Account Management, File Permissions, SUID/SGID, Sticky Bit, PAM, and password quality.

---

## Repo Structure
```
├── docs
│   ├── cheatsheet.md
│   ├── pam-pwquality.md
│   ├── password-policy.md
│   └── sudoers-examples.md
├── examples
│   ├── users.csv
│   └── users.yaml
├── README.md
├── scripts
│   ├── audit_users.sh
│   ├── create_users.sh
│   └── hardening.sh
└── users_audit.csv (generated)
```

---


---

## Scripts Description

### 1. `create_users.sh`
- Reads CSV/YAML manifest (`examples/users.csv` or `.yaml`).  
- Creates users with primary/secondary groups, shell, and temporary password.  
- Optionally applies sudoers snippet (`/etc/sudoers.d/99-lab-admins`).  
- Default **dry-run** mode; use `--apply` to make changes.

**Usage:**
```bash
sudo ./scripts/create_users.sh --manifest examples/users.csv --apply
```

### 2. `hardening.sh`
- Sets global umask in `/etc/profile.d/99-umask.sh`.
- Suggests/apply **password policies** in `/etc/login.defs`.
- Provides **pwquality & PAM recommendations**.
- Dry-run by default; use `--apply` to apply changes.

### 3. `audit_users.sh`
- Generates `users_audit.csv` with: username, uid, gid, home, shell, groups, last login, password state, last password change in days.
- Useful for **auditing lab users**.

---

## Example Manifests
### - `examples/users.csv` (CSV format)
  
  ```bash
  # username,role,shell
  alice,admins,/bin/bash  
  bob,devs,/bin/bash
  carol,guests,/bin/sh
  ```
### - `examples/users.yaml` (YAML format)

  ```bash
  users:
  - username: alice
    role: admins
    shell: /bin/bash
    extras: sudo,devs
  - username: bob
    role: devs
    shell: /bin/bash
  ```
---

## Recommended Environment
- Disposable VM (Vagrant, VirtualBox, or cloud instance)
- Ubuntu 22.04 LTS (jammy64)
- Ensure `sudo`, `whois`, `python3`, and `python3-yaml` are installed.

**Optional Vagrantfile** (for lab setup):
```bash
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "userprov-lab"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update -y
    apt-get install -y sudo whois less python3 python3-yaml
  SHELL
  config.vm.synced_folder ".", "/home/vagrant/user-provisioning"
end
```

---

## Safety Notes
- Scripts are intended for lab/disposable VMs only.
- Dry-run mode is default to prevent accidental changes.
- Temporary passwords are set for testing only.
- Backup `/etc/login.defs` before applying hardening changes.

## References / Docs
- `docs/cheatsheet.md` → Linux user/group & permissions cheatsheet
- `docs/password-policy.md` → Recommended login.defs settings
- `docs/pam-pwquality.md` → PAM password quality suggestions
- `docs/sudoers-examples.md` → Sample sudoers snippets

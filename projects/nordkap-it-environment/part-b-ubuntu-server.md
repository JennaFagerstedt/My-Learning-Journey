# Part B: Ubuntu Server (nkwebb01)

## Static IP with netplan
`/etc/netplan/00-installer-config.yaml`:
```yaml
network:
  version: 2
  ethernets:
    ens33:
      dhcp4: false
      addresses: [192.168.113.20/24]
      routes:
        - to: default
          via: 192.168.113.2
      nameservers:
        addresses: [192.168.113.10]
        search: [nordkap.internal]
```
```bash
sudo netplan apply
ip a
```
**What I learned:** YAML is sensitive to indentation. The server first got a DHCP address (.136), but a server that others need to reach needs a fixed address.

## B1: The web server
```bash
sudo apt install nginx
systemctl status nginx
grep root /etc/nginx/sites-available/default   # → root /var/www/html;
sudo vim /var/www/html/index.html
curl http://localhost
```
**What I learned:** Look up the web root in the config instead of guessing, because different installations can use different paths. HTTP is unencrypted ("Not secure"). In production I would use HTTPS.

## B2: Group, ownership and permissions
```bash
sudo groupadd webbredaktor
sudo adduser redaktor
sudo usermod -aG webbredaktor redaktor
sudo chown -R root:webbredaktor /var/www/html
sudo chmod 2775 /var/www/html
sudo chmod 664 /var/www/html/*.html
```
| Object | Owner:group | Permissions |
|---|---|---|
| Directory | root:webbredaktor | `2775` → `rwxrwsr-x` |
| Files | root:webbredaktor | `664` → `rw-rw-r--` |

**What I learned:**
- Octal notation: r=4, w=2, x=1. `664` = owner rw, group rw, others r.
- **setgid** (the leading `2` in `2775`, shown as `s` in `rwxrwsr-x`) makes new files in the directory automatically get the group `webbredaktor`.
- The number after the permissions in `ls -l` (e.g. `drwxrwsr-x 2`) is the **hard link count**, not setgid!
- `usermod -aG`: without `-a`, all of the user's groups are *replaced* instead of appended.
- **www-data** (nginx's service account) falls under *others* and can only read. If the service is compromised, the attacker can't modify the website.

## B3: A non-editor is denied
Created the user `vanlig` ("regular"), who is not in the group. `cat` works, while `echo "x" >> index.html` and `touch new.html` both give **Permission denied**.

## B4: Firewall with default deny
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.113.10 to any port 80 proto tcp comment 'HTTP fran nkdc01'
sudo ufw enable
sudo ufw status verbose
```
**What I learned:**
- Default deny: everything is closed, and you open only what is needed.
- I did **not** open port 22 (SSH) because I administer the server through the VMware console, and every open port is a target. In production SSH is needed, but restricted to the admin network and with key-based login.
- Comments on rules make them understandable for the next admin.

## B5: Reachable from Windows, not from the host
nkdc01 can load the page and the host machine gets a timeout. It is a **timeout** (not "connection refused") because ufw silently drops the packets.

## B6: smbclient against the Windows share
```bash
smbclient //192.168.113.10/Nordkap -U 'NORDKAP\anna.berg'
```
- **Never put the password on the command line.** It would end up in `history` and be visible in the process list.
- I connect by IP instead of name to test SMB and permissions in isolation, without DNS getting mixed into the troubleshooting.
- The test: `anna.berg` (Finance) should be able to `cd Ekonomi`, while `erik.ahl` (Consultant) should get `NT_STATUS_ACCESS_DENIED`. The NTFS permissions from Part A apply from Linux too.

## Useful Linux commands I learned
| Command | What it does |
|---|---|
| `id user` | Show uid, gid and groups |
| `ls -l` / `ls -ld dir` | Permissions on files / on the directory itself |
| `su - user` | Switch user (with login environment) |
| `sudo deluser --remove-home name` | Remove a user and their home directory |
| `history` | Command history. Check that no passwords leaked. |
| `nc -zv ip port` | Test whether a port is open |
| `cat /etc/os-release` | Which Ubuntu version is running |
| vim: `i`, `Esc`, `:wq`, `$`, `x` | Insert, leave insert mode, save and quit, end of line, delete character |

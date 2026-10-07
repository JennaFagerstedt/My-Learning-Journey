# Part C: Scripting and regular expressions

## C1: script.sh, finding 404 requests in the nginx log

**Goal:** print `IP,path` for every request that returned 404.

Generated test traffic from nkdc01 (PowerShell):
```powershell
'admin','wp-login.php','.env','backup.zip','phpmyadmin','config.php' |
  ForEach-Object { curl.exe -s "http://192.168.113.20/$_" | Out-Null }
```

Finished script (see [scripts/script.sh](scripts/script.sh)):
```bash
#!/usr/bin/env bash
LOGGPATH="/var/log/nginx/access.log"
IP_RE='[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
SOKVAG_RE='/[^ ]*'

grep " 404 " "$LOGGPATH" | sed -nE "s|^($IP_RE).+\"[A-Z]+ ($SOKVAG_RE) HTTP.+|\1,\2|p"
```
```bash
chmod +x script.sh
./script.sh
```
Output:
```
192.168.113.10,/admin
192.168.113.10,/wp-login.php
192.168.113.10,/.env
192.168.113.10,/backup.zip
192.168.113.10,/phpmyadmin
192.168.113.10,/config.php
```

### What I learned about regex
| Part | Meaning |
|---|---|
| `[0-9]{1,3}` | One to three digits |
| `\.` | A literal dot. A bare `.` means *any character* |
| `/[^ ]*` | A slash followed by anything that is **not** a space (`^` inside `[ ]` = "not") |
| `^` (outside `[ ]`) | Start of the line |
| `( )` + `\1,\2` | Capture parts of the match and print them |
| `-E` | Extended regex: `{1,3}`, `+` and `( )` without backslashes |

- **Limitation:** the IP regex also accepts `999.999.999.999`. That's fine here because nginx writes the log itself, so an invalid address can never end up in it. For user input it wouldn't be enough.
- **Context matters:** `/[^ ]*` on its own also matches `/Oct/2026` and `/1.1`, so the path is anchored between `"GET ` and ` HTTP`.
- **sed delimiter:** `SOKVAG_RE` contains `/`, which clashes with `s/…/…/`. The fix is to use `|` as the delimiter.
- `chmod +x` plus a **shebang** (`#!/usr/bin/env bash`) lets the script run as `./script.sh`. The `./` is needed because the current directory isn't in `$PATH`.

### Why this matters for security
404 requests for `/wp-login.php`, `/.env`, `/phpmyadmin` and `/backup.zip` are typical of **automated vulnerability scanning**: someone looking for login pages, config files containing passwords or forgotten backups. Many 404s from one IP in a short time make that IP a candidate for blocking in ufw. The limitation is that 404s only show *failed* attempts. (In my lab, all requests came from my own test on nkdc01.)

## C2: svcmon.ps1, monitoring and restarting services

Finished script (see [scripts/svcmon.ps1](scripts/svcmon.ps1)):
```powershell
$monitoredsvc = 'DNS', 'LanmanServer'
$Log     = 'C:\Scripts\svcmon.log'

foreach ($name in $monitoredsvc) {
    $status = (Get-Service -Name $name).Status
    if ($status -ne 'Running') { Start-Service -Name $name }
    "{0:yyyy-MM-dd HH:mm}  {1}  {2}" -f (Get-Date), $name, $status | Add-Content $Log
}
```

**Choice of services**
| Name | Display name | Why |
|---|---|---|
| `DNS` | DNS Server | Without DNS, nobody can find the domain controller |
| `LanmanServer` | Server | Serves `\\nkdc01\Nordkap`, and on a DC also **SYSVOL** and **NETLOGON** (GPOs and logon scripts) |

**Scheduling (Task Scheduler → Create Task)**
- Runs as **SYSTEM** with *Run with highest privileges*
- Trigger: daily, repeat **every 15 minutes** indefinitely
- Action: `powershell.exe -NoProfile -NonInteractive -File "C:\Scripts\svcmon.ps1"`

**Test:** stopped DNS, ran the script, and the log showed `DNS Stopped` while `Get-Service DNS` showed Running again. Scheduled runs then appeared in the log at 10:07, 10:22 and so on.

### What I learned
- **Name vs DisplayName:** `Get-Service -Name` needs the service name (`LanmanServer`), not the display name (`Server`). services.msc sorts by display name.
- **DNS Server** (`DNS`) answers queries, while **DNS Client** (`Dnscache`) asks them.
- **Execution policy** was already `RemoteSigned`, so locally created scripts can run. There was no reason to lower it to `Unrestricted`.
- **The script lives on C:**, not on the data volume E:. Admin tools should be kept apart from user data. The folder should only be writable by Administrators and SYSTEM, because the script runs as SYSTEM.
- **Why SYSTEM:** it has permission to start services without storing any password.
- **Hidden file extensions:** my file was actually called `svcmon.ps1.txt`. The *Type* column ("Text Document") gave it away. Turn on *File name extensions* in File Explorer.
- A script only checks at the moment it runs, which is why it has to be scheduled.

### Weaknesses I see in the script
- The log shows the status *before* the restart, so `DNS Stopped` remains even though the service is running. The log should say "restarted" and check that the restart succeeded.
- There can be up to 15 minutes of downtime before the service is restarted.
- Dependent services are not restarted.
- There is no alerting. Someone has to read the log.

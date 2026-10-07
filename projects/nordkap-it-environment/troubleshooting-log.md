# Troubleshooting log

Problems I ran into, what caused them and how I fixed them.

## Windows Server

| Symptom | Cause | Fix |
|---|---|---|
| The DC had IP 192.168.100.10 and nothing worked against the rest of the network | I set an address in the wrong subnet without checking which one VMware used | Checked VMnet8 with `ipconfig` and used the right subnet, 192.168.113.0/24 |
| Changes in ncpa.cpl were not saved | I clicked Cancel/close on the outer dialog | Removed an unneeded Host-only adapter and set the IP via PowerShell (`New-NetIPAddress`, `Set-DnsClientServerAddress`). Lesson: always verify with `ipconfig /all` |
| PowerShell error: parameter not found | Typos (`-IPAddressFamily`, `-ServerAdresses`) and two commands merged on one line | Read the error message, which points to the parameter |
| `nslookup` didn't work after changing the IP | DNS records pointed to the old address | `ipconfig /registerdns`, `Restart-Service Netlogon`, `Restart-Service DNS` |
| DC promotion failed | The local Administrator account had no password | `net user Administrator *` |
| A user was named `merie.lund` | Typo | Renamed to `marie.lund` |
| No 4624/4625 in the Security log | I enabled *Audit **account** logon events* instead of *Audit logon events* | Checked with `auditpol /get /category:*` and changed the policy |
| New events didn't show up | Event Viewer doesn't refresh automatically | F5 |
| erik got 4625 "not granted the requested logon type" | Regular users may not log on interactively to a DC | Tested over the network (smbclient) instead, which gives Logon Type 3 |
| `C:\Scripts\svcmon.ps1` "is not recognized" | The file was named `svcmon.ps1.txt` (hidden extensions) | View → File name extensions → rename |
| The script didn't start DNS | The script had run *before* I stopped the service | Run the script again after stopping, since it only checks when it runs |

## Linux

| Symptom | Cause | Fix |
|---|---|---|
| The server got IP .136 | DHCP | Static IP via netplan |
| `apt` hung ("Ign:") | DNS pointed to the DC, which couldn't resolve external names | DNS forwarder 192.168.113.2 on nkdc01 |
| The group couldn't write to the files | `chmod 644` instead of `664` | `chmod 664` |
| User called `reakor` | Typo | `deluser --remove-home reakor`, then created `redaktor` |
| `./script.sh` printed nothing | `{1-3}` instead of `{1,3}`, `.\[` instead of `\.[`, missing `$` before `SOKVAG_RE` | Read the script line by line with `cat script.sh` |
| The sed expression didn't match (a mistake in the original suggestion) | `/` in the path regex clashed with the sed delimiter `s/…/…/` | Switched the delimiter to `\|` |
| `unexpected EOF while looking for matching '` | An extra `'` at the end of the line | Deleted it in vim (`$`, `x`, `:wq`) |
| Wrong path in my documentation | I wrote `//192.168.113.20/...`, the Linux server's own IP | Correct: `//192.168.113.10/Nordkap`, because the share lives on the Windows server |

## The pattern in my mistakes
Most problems were **small typos** or something that **looked right but wasn't**. My takeaway is to verify instead of assuming (`ipconfig /all`, `auditpol`, `cat`, `ls -l`, the *Type* column), and to assume I missed something before I suspect the system.

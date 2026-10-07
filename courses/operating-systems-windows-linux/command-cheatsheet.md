# Command cheat sheet: DNS and network checks

| What | Windows | Linux / macOS |
|---|---|---|
| Look up a name (A) | `nslookup name` | `dig name` |
| Other record type | `nslookup -type=MX domain` | `dig MX domain` |
| Reverse lookup (PTR) | `nslookup 8.8.8.8` | `dig -x 8.8.8.8` |
| Ask a specific DNS server | `nslookup name 1.1.1.1` | `dig @1.1.1.1 name` |
| Flush the client DNS cache | `ipconfig /flushdns` | `resolvectl flush-caches` (Linux) / `sudo dscacheutil -flushcache` (macOS) |
| Show the client DNS cache | `ipconfig /displaydns` | - |
| Show IP and DNS configuration | `ipconfig /all` | `ip a` / `resolvectl status` |
| Test connectivity to an IP | `ping 8.8.8.8` | `ping 8.8.8.8` |
| List listening ports | `netstat -an` | `ss -tuln` |
| Filter output | `findstr "text"` | `grep "text"` |

## Record types in one line each
| Record | Answers the question |
|---|---|
| **A** | Which IP address does this name have? |
| **PTR** | Which name belongs to this IP address? (reverse, optional) |
| **MX** | Which servers receive mail for this domain? (lower number = tried first) |
| **NS** | Which name servers are authoritative for this domain? |
| **CNAME** | Is this name an alias for another name? |
| **TXT** | Free text: SPF mail rules, domain verification tokens |

## Reading error messages
| Message | Meaning |
|---|---|
| `Non-existent domain` | The domain does not exist |
| Answer without records of the requested type | The domain exists but has no record of that type |
| `No response from server` / `timed out` | The DNS server is not answering |
| `Non-authoritative answer` | The answer came from a cache, not the zone's own name server |

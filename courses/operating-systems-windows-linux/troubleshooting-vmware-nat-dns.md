# Troubleshooting: VM has internet but cannot resolve names

## Symptom
In my Windows 11 VM (VMware Workstation, NAT mode, Windows 11 host), `nslookup www.google.com` returned:

```
UnKnown can't find www.google.com: No response from server
```

## Setup
- VM network adapter: **NAT** (VMnet8). The VM got a valid IP address.
- DNS server given to the VM: `192.168.79.2`, the virtual NAT gateway that VMware also uses as a DNS proxy.

## Narrowing it down

| Test | Result | What it told me |
|---|---|---|
| `ipconfig` in the VM | Valid IP address (not `169.254.x.x`) | The VM got an address, so DHCP works |
| `ping 8.8.8.8` | Replies | Internet connectivity works |
| `nslookup www.google.com 8.8.8.8` | Works | DNS works if I ask a different server |
| `ping 192.168.79.2` | Replies | The gateway is reachable |
| `nslookup www.google.com` (default server) | No response | **Only the default DNS server fails** |

Conclusion: not a connectivity problem, and not a general DNS problem. The VM's **default DNS server (the VMware NAT DNS proxy)** was not answering DNS queries, even though it answered ping. Layered reasoning (IP first, then name resolution) is what separated the two.

## What I ruled out

| Check | Result |
|---|---|
| `VMware NAT Service` and `VMware DHCP Service` in `services.msc` on the host | Both Running |
| DNS on the host itself (`nslookup www.google.com`) | Works |
| `ipconfig /flushdns` in the VM | No change |
| Windows Defender Firewall on the host: VMware inbound rules | Enabled |
| Windows Defender Firewall turned off completely (temporarily) | No change |
| No third-party security software installed | Not a factor |
| Restoring the virtual network defaults (VMware **Virtual Network Editor**) | No change |
| Restarting VMware | No change |

## A note on `netstat`
I ran `netstat -an | findstr :53` on the host to see whether anything listened on port 53. The matches were `5353` (mDNS) and `5355` (LLMNR), plus lots of high ports that contain "53", such as `53522`. **`findstr :53` matches the text anywhere in the line, not the exact port.** Adding a trailing space (`findstr ":53 "`) gave a cleaner list.

I first read the missing `:53` listener as proof that the DNS proxy was dead. That conclusion was too strong: in VMware NAT, the `.2` address is handled inside `vmnat.exe` and may not show up as an ordinary listening socket in `netstat`. So the output was a hint, not a diagnosis.

## Workaround
Pass the DNS server explicitly on every command:

```
nslookup www.google.com 8.8.8.8
```

This also made the `Server:` line show `dns.google` instead of `UnKnown`.

## Not solved yet
The root cause is still open. Next things I could try:
- Change the VM adapter's DNS manually to `8.8.8.8` (Windows network adapter settings in the VM).
- Switch the VM to **Bridged** mode, which bypasses the NAT DNS proxy.
- Repair or reinstall VMware's network components.

## What I learned
- **Test in layers:** ping an IP (network) → resolve a name against a known server (DNS) → resolve with the default server (my configuration). Each step removes a whole group of causes.
- `nslookup <name> <server>` lets me test a specific DNS server, which is exactly what separated "DNS is broken" from "*my* DNS server is broken".
- **Read what a tool actually matched.** My `findstr` pattern produced false positives, and a negative result from a tool is not always proof of what I think it is.
- Know when to stop: after the main causes were ruled out, a workaround let me finish the exercise, and the deeper VMware problem became a separate task.

# Exploring DNS with nslookup

> Week 1 exercise from the course *Network fundamentals* (done in a Windows 11 VM).
> DNS is the foundation for almost everything that follows: firewalls, SSH, exposed services.

Because of a problem with my VM's default DNS server (see [troubleshooting-vmware-nat-dns.md](troubleshooting-vmware-nat-dns.md)), I ran every lookup against Google's public DNS by adding `8.8.8.8` at the end:

```
nslookup <name> 8.8.8.8
```

## How to read an nslookup answer
- The first two lines show **which DNS server answered** (`Server:` / `Address:`). `UnKnown` only means my computer could not find a reverse name for that server. It is not an error.
- **`Non-authoritative answer`** does not mean the answer is unreliable. It means the server I asked does not own the zone and answered from its cache. Almost every answer is non-authoritative. I only get an **authoritative** answer by asking the domain's own name server directly (part 7).

## Part 1: A records (name → IP address)
`nslookup www.google.com 8.8.8.8`

- I got **8 IP addresses** back.
- The order **changed between runs**. My first guess was that the servers answered at different speeds. That was wrong. The DNS server **rotates the order on purpose (round-robin DNS)** so that clients do not all pick the first address, which spreads the load across many servers.
- `iths.se` and my own domain returned **one address**. Small organizations usually have one server. Large services like Google have many.

## Part 2: PTR records (IP address → name)
- `nslookup 8.8.8.8 8.8.8.8` returned **`dns.google`**. That is reasonable: Google wants this address to be recognizable.
- The IP addresses I got for `www.google.com` returned **Non-existent domain** on every try.
- The IP of `iths.se` returned **`tama.oderland.com`**: the name of the hosting company (Oderland) that owns the address, not `iths.se`.

**What I learned:**
- **A and PTR are independent records.** The A record is set by whoever owns the *domain*. The PTR record is set by whoever owns the *IP address*, often a different party. Nothing requires them to match, or a PTR to exist at all.
- A PTR record costs maintenance, so it only exists where there is a reason: public services people should recognize (`8.8.8.8`) and **mail servers**, where a matching PTR is practically required to avoid being classified as spam.
- A missing reverse name is normal. It is not an error.

## Part 3: MX records (mail servers)
`nslookup -type=MX gmail.com 8.8.8.8` and the same for `iths.se`.

- The number in front of each server is **priority, not size**. My first guess (server size) was wrong. **Lower number = tried first**, higher numbers are fallbacks if the first server is down. It is a redundancy mechanism.
- `iths.se` and `volvo.com` both point to **Microsoft's mail infrastructure** (`*.mail.protection.outlook.com`), which means Microsoft 365 / Exchange Online, a cloud service. If an organization ran its own mail server, the MX would point to a host in its own domain.

## Part 4: NS records (name servers)
NS records say which servers are **authoritative** for a domain: the ones that own the DNS data. These are the servers to ask for an authoritative answer (part 7). The name server names also hint at who runs the DNS (the organization itself, or a hosting provider).

## Part 5: CNAME records (aliases)
`nslookup -type=CNAME www.microsoft.com 8.8.8.8`

- `www.microsoft.com` is an **alias** that points to a CDN provider instead of a server of Microsoft's own.
- **Why:** a CDN (content delivery network) has servers spread across the world. Visitors are sent to the server **closest to them**, which gives lower latency, spreads the load and keeps the site up if one location fails. Microsoft does not have to build that infrastructure itself.
- Most domains have **no CNAME** on their `www` name. An empty answer there is not an error.

## Part 6: TXT records and SPF
`nslookup -type=TXT iths.se 8.8.8.8` returned two records:

```
v=spf1 include:spf.protection.outlook.com include:all._spf.plma.se include:_spf.m101.websupport.se include:<id>.spf04.hubspotemail.net -all
MS=ms<number>
```

| Part | Meaning |
|---|---|
| `v=spf1` | This is an SPF record, version 1 |
| `include:spf.protection.outlook.com` | Microsoft 365 may send mail for the domain |
| `include:all._spf.plma.se`, `include:_spf.m101.websupport.se` | Two other third-party services that send mail for the domain |
| `include:...hubspotemail.net` | HubSpot (marketing / newsletter mail) |
| `-all` | **Hard fail:** mail from any server not on the list should be rejected |
| `MS=...` | A Microsoft **domain verification token**: proof the organization owns the domain |

- 4 services are listed.
- **Why `+all` is a problem:** it means *anyone* may send mail as the domain, so SPF protects nothing and phishing mail that spoofs the domain gets through.
- **Why a long list is a problem:** SPF has a hard limit of **10 DNS lookups** per check. Too many `include:` entries and the check fails with a `PermError`, which can make legitimate mail look like spam.
- **Verification tokens** (like `MS=`) are TXT records a service asks you to publish to prove you own the domain. They reveal which cloud services the organization uses.

> **Takeaway from parts 3, 4 and 6:** without touching the organization's systems, I could see which mail provider they use, who runs their DNS and which cloud services are connected to the domain. DNS is public by necessity, which is why it is the first stop when someone maps a target.

## Part 7: Asking a different DNS server
- `nslookup www.google.com 1.1.1.1` (Cloudflare) gave me **different addresses** (4 this time) than Google's `8.8.8.8` did. Large services answer differently depending on **where the question comes from**, so that users are sent to a nearby, suitable server (the same idea as the CDN in part 5). There is no single correct answer to "what are Google's IP addresses".
- `nslookup www.skolverket.se ns03.skolverket.se`: when I ask the domain's **own name server**, the **`Non-authoritative answer` line disappears**. That server owns the zone, so its answer is authoritative.
- If port 53 to other servers is blocked on a network, the queries time out. That is a deliberate firewall rule on many networks, to stop clients from bypassing the organization's DNS filter.

## Part 8: Three different errors
| Command | What it tells me |
|---|---|
| `nslookup finnsintedennadoman12345.se 8.8.8.8` | **Non-existent domain**: the domain does not exist (misspelling?) |
| `nslookup -type=MX www.google.com 8.8.8.8` | The domain exists but has **no record of that type**. A valid, empty answer rather than an error |
| `nslookup www.google.com 192.0.2.1` | **Timeout / no response**: the DNS server is not answering. `192.0.2.1` is a documentation address, so nothing answers. Run this one **without** adding `8.8.8.8` |

Troubleshooting logic: *Non-existent domain* makes me suspect a typo. A *timeout* makes me suspect the DNS server or the network path. This is exactly the difference I experienced myself in the VM problem.

## Reflection questions

**TTL: what to do before moving a service to a new server**
TTL says how long an answer may be cached. My first answer was to "zero" the TTL. That was imprecise. The right approach is to **lower the TTL (for example from 3600 to 300 seconds) well in advance**, so that caches have already picked up the short value when the IP address actually changes. If I lower it at the same time as the change, everyone who cached the old record with the long TTL still gets the old address for just as long. After the move I can raise it again.

**What stops working if DNS goes down, and what keeps working**
Name lookups stop: I cannot reach `www.google.com` by name. Connections made straight to an IP address keep working, since they need no lookup. I saw this myself: `ping 8.8.8.8` worked while `nslookup www.google.com` failed.

**Why DNS is a common target**
- **Reconnaissance:** a lot of information about an organization is public in DNS without breaking in (my own answer).
- **Availability:** knocking out an organization's DNS servers (for example with a DDoS attack) makes everything unreachable even though the other systems are fine.
- **Cache poisoning / spoofing:** tricking a DNS server into caching a wrong answer sends users to a fake site.
- **Weak original design:** DNS was built without strong authentication, especially over UDP. DNSSEC adds protection.

## Still to do
- Part 9: the client DNS cache (`ipconfig /displaydns`, `ipconfig /flushdns`) and why `nslookup` bypasses it.
- Reflection questions 1-3 (record types, authoritative answers, what an outsider can learn from DNS).

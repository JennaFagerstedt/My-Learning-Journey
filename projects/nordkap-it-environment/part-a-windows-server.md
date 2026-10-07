# Part A: Windows Server (nkdc01)

## A1: Domain controller in a new forest
**What I did:** Set a static IP (192.168.113.10, with DNS pointing to itself), installed the AD DS role through Server Manager and promoted the server to a domain controller in a **new forest**, `nordkap.internal`. DNS and Global Catalog were installed at the same time. Set a DSRM password.

**What I learned:**
- A DC needs a **static IP**. Clients find the domain through DNS, and DNS points at the DC's address.
- Promotion registers **SRV records** in DNS (e.g. `_ldap._tcp`, `_kerberos._tcp`). That is how clients locate the domain controller. No working DNS means no domain.
- **The forest is the security boundary** in AD.
- `.internal` is reserved for private networks and can never collide with a real domain on the internet.
- **DSRM** (Directory Services Restore Mode) boots the DC without AD running. It is used to restore or repair the AD database.
- To resolve external names (e.g. for `apt` on Linux), the DNS server needs a **forwarder** (here 192.168.113.2).

## A2: Organizational structure
```
nordkap.internal
└── Nordkap
    ├── Anvandare        (Users)
    │   ├── Ekonomi      (Finance)
    │   ├── Konsult      (Consultants)
    │   └── Ledning      (Management)
    └── Grupper          (Groups)
```
**What I learned:** GPOs can be linked to **OUs but not to containers** (like the default `Users`). A dedicated top-level OU separates the company's objects from Windows' default objects, and GPOs linked at the top are inherited downward. OUs also make it possible to **delegate** administration, e.g. password resets for one department.

## A3: User accounts and naming standard
- Naming standard: `firstname.lastname`, Swedish å/ä → a, ö → o, on collision `anna.berg2`.
- 12 users: Management (2), Finance (3), Consultants (7).
- Verified with `Get-ADUser -Filter * -SearchBase "OU=Anvandare,OU=Nordkap,DC=nordkap,DC=internal"`.

**What I learned:** Non-ASCII characters in usernames cause trouble in older systems, on Linux and in email addresses. In production: tick *User must change password at next logon*.

## A4: Security groups
- `G_Ledning`, `G_Ekonomi`, `G_Konsult`: Global, Security
- `G_Alla` ("everyone") contains the three department groups (**nested groups**)

**What I learned:**
- Permissions go on **groups, never on individual accounts**. A new finance hire just gets added to `G_Ekonomi`, and someone who leaves gets removed.
- **Security** groups have a SID and can be used in ACLs. **Distribution** groups are only for email lists.
- **Global** scope groups users from the same domain by role.

## A5: The file share
- Shrank C: and created a new NTFS volume **E:** for data.
- `E:\Shares\Nordkap` with subfolders `Ekonomi`, `Ledning` and `Gemensam` (shared), shared as `\\nkdc01\Nordkap`.
- **Share permissions:** `G_Alla` Change, Administrators Full. Removed *Everyone*.

**What I learned:**
- **Separate system and data.** A full data volume must not be able to take down Windows, AD and DNS.
- **Share + NTFS:** the *most restrictive* of the two applies. A common pattern is to open the share level to the group and control the details with NTFS.

## A6–A8: NTFS permissions
| Folder | Permissions |
|---|---|
| Ekonomi (Finance) | SYSTEM + Administrators Full, `G_Ekonomi` Modify |
| Ledning (Management) | SYSTEM + Administrators Full, `G_Ledning` Modify, `G_Alla` Read & execute |
| Gemensam (Shared) | SYSTEM + Administrators Full, `G_Alla` Modify |

How: Properties → Security → Advanced → **Disable inheritance → Convert** → removed `Users` (×2), `CREATOR OWNER` and my personal account → added the right group → changed the owner to the **Administrators** group.

**What I learned:**
- **Inheritance** gives all users read access via `Users` from E:\, so it has to be broken.
- Choose **Convert**, not Remove. Otherwise SYSTEM and Administrators disappear too and you can lock yourself out.
- **Modify vs Full control:** Full control also allows changing permissions and taking ownership, which regular users don't need (**least privilege**).
- **CREATOR OWNER** gives whoever creates a file full control over it. That is unwanted here.
- The owner should be a **group** (Administrators), not a personal account that might disappear.
- Always test **both outcomes**: the right person gets in *and* the wrong person is denied.

## A9–A10: Hardened firewall rule for SMB
- Disabled all 11 built-in inbound rules for port 445.
- Created my own rule, **"Nordkap SMB – endast nkwebb01"**: TCP 445, Allow, **Domain** profile, Remote IP **192.168.113.20**.
- Tested: `nc -zv 192.168.113.10 445` from nkwebb01 succeeds, while the host machine gets "cannot access".

**What I learned:**
- An **allow-list** beats a block-list. If I only block the host's IP, everything else still gets in.
- **One** active allow rule is enough to let traffic through, so every port-445 rule has to be closed.
- **Profiles:** the rule only applies in the Domain profile, so it won't open 445 if the server ends up on a public network.
- **Side effect in production:** domain-joined clients need 445 to fetch GPOs from **SYSVOL** and **NETLOGON**. Closing it for everyone but one machine works in a lab, not in a real company.
- What the rule does **not** protect against: someone taking over the .20 address, stolen or weak passwords, threats from inside the server. NTFS is the next layer (**defense in depth**).

## A11: Logon auditing
- `secpol.msc` → Local Policies → Audit Policy → **Audit logon events**: Success + Failure.
- Verified with `auditpol /get /category:*`.
- Generated logons with `smbclient` from nkwebb01 as `erik.ahl` (wrong password, then the right one).

| Event ID | Meaning |
|---|---|
| 4624 | Successful logon |
| 4625 | Failed logon |

Logon Type **3** = network logon (via SMB).

**What I learned:**
- **Audit logon events** (logons *to this computer*) is not the same as **Audit account logon events** (the DC *validating* credentials via Kerberos/NTLM). I picked the wrong one first and learned the difference the hard way.
- Many 4625s in a short time point to a possible **brute-force attack**. Successful logons at odd hours are interesting too.
- Event Viewer doesn't refresh on its own. Press **F5**.

## A12: Microsoft Defender
Enabled real-time and cloud-delivered protection, updated the definitions, ran a Quick scan and checked that there were no exclusions.

**What I learned:** A file server is an attractive target: many users and lots of data in one place, perfect for **ransomware** and spreading malware.

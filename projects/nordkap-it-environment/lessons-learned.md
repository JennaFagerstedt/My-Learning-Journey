# Lessons learned

## Security principles I applied in practice
- **Least privilege:** Modify instead of Full control, www-data as "others", SMB for a single IP only, no SSH.
- **Default deny / allow-listing:** close everything and open what's needed (ufw, Windows Firewall).
- **Defense in depth:** firewall → share permissions → NTFS. If one layer fails, the next one takes over.
- **Permissions through groups:** never on individual accounts.
- **Separate system and data:** a dedicated data volume E:, with scripts on C:.
- **Log and review:** 4624/4625, the nginx access.log and my own service log.
- **Keep secrets where they belong:** no passwords on the command line or in the report.

## How I work
- **Verify, don't assume.** A lot of my troubleshooting came from things that looked right but weren't.
- **Test both outcomes.** The right person getting in doesn't prove the wrong person is denied.
- **Read the error message.** It almost always tells you what's wrong (`unexpected EOF`, `is not recognized`, `Permission denied`).
- **Troubleshoot in layers.** Connect by IP instead of name to rule out DNS.
- **Document while working.** Take screenshots and save commands right away, not afterward.

## What I would do differently in production
- Use a licensed Windows Server instead of the 180-day evaluation.
- Use a personal admin account and elevate when needed, instead of the built-in Administrator account.
- Require *User must change password at next logon* and enforce a password policy.
- Configure auditing through GPO (Default Domain Controllers Policy), with both *logon* and *account logon events*.
- Serve the website over HTTPS.
- Keep SSH open but restricted to the admin network, with key-based login.
- Keep port 445 open for domain clients (SYSVOL/NETLOGON).
- Use monitoring with alerting instead of a script that only writes a log.

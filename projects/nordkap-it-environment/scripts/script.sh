#!/usr/bin/env bash
# script.sh - lists IP address and path for every request that returned 404 in the nginx log
# Output: IP,path  (e.g. 192.168.113.10,/admin)

LOGGPATH="/var/log/nginx/access.log"
IP_RE='[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
SOKVAG_RE='/[^ ]*'

# | is used as the sed delimiter because SOKVAG_RE contains /
grep " 404 " "$LOGGPATH" | sed -nE "s|^($IP_RE).+\"[A-Z]+ ($SOKVAG_RE) HTTP.+|\1,\2|p"

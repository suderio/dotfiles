#!/bin/bash
# Stop on error
set -e

# Stop on unitialized variables
set -u

# Stop on failed pipes
set -o pipefail

# Trap exit to allow error handling
trap 'catch $? $LINENO' EXIT

catch() {
  if [ "$1" != "0" ]; then
    echo "Error $1 occurred on $2"
    logger "curltime failed. Error: $1"
  else
    logger "curltime finished"
  fi
}

# Log everything in system log
logger "curltime is starting"

curl -w @- -o /dev/null -s "$@" <<'EOF'
    time_namelookup:  %{time_namelookup}\n
       time_connect:  %{time_connect}\n
    time_appconnect:  %{time_appconnect}\n
   time_pretransfer:  %{time_pretransfer}\n
      time_redirect:  %{time_redirect}\n
 time_starttransfer:  %{time_starttransfer}\n
                    ----------\n
         time_total:  %{time_total}\n
-------------------------------------------\n
EOF


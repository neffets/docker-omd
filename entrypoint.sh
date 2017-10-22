#!/usr/bin/env bash

SLEEP_TIME=60
MAX_TRIES=5
SITE=${SITENAME:=monitor}

#######################################################################
# Check if SITE is initialized
omd sites -b | egrep -e "^${SITE}$"
if [ "$?" -eq 1 ]; then

    # Set up a default site
    omd create "${SITE}"

    # We don't want TMPFS as it requires higher privileges ?
    # Accept connections on any IP address, since we get a random one ?
    for varname in ${!OMD_*}
    do
        declare -n configval=$varname
        if [ ! -z "$configval" ]; then
            configkey=${varname/OMD_/}
            omd config "${SITE}" set "${configkey}" "${configval}"
        fi
    done
else
    ln -sf /etc/alternatives/omd /opt/omd/sites/${SITE}/version
fi

#######################################################################
# watching for startup
tries=0
echo "** Starting OMD **"
omd start "${SITE}"
while /bin/true; do
  sleep $SLEEP_TIME
  omd status "${SITE}" | grep -q "stopped" && {
    if [ $tries -gt $MAX_TRIES ]; then
      echo "** ERROR: Stopped service found; aborting (after $tries tries) **"
      exit 1
    fi
    tries=$(( tries + 1 ))
    echo "** ERROR: Stopped service found; trying to start again **"
    omd start "${SITE}"
  }
done


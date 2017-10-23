#!/usr/bin/env bash

SLEEP_TIME=60
MAX_TRIES=5
SITE=${SITENAME:=monitor}

#######################################################################
groupadd -g 1001 "${SITE}" || echo "* group $SITE already exists"
useradd -s /bin/bash -m -d /opt/omd/sites/${SITE} -u 1001 -g "${SITE}" "${SITE}" || echo "* User $SITE already exists"
# Fix some permission issues (not sure why it happens)
[ -d "/opt/omd/sites/${SITE}" ] && chown -R ${SITE}.${SITE} "/opt/omd/sites/${SITE}"
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
    adduser "${SITE}" "${SITE}" || true
    omd update --conflict install "${SITE}"
    ln -sfn "../../versions/`omd versions -b|head -1`" /opt/omd/sites/${SITE}/version
fi
# Add the new user to crontab, to avoid error merging crontabs
adduser "${SITE}" crontab || true
omd enable "${SITE}"

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


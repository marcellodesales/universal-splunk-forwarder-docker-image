#!/bin/sh

# Figure out for logging
if [ "$1" = 'splunk' ]; then
  shift
  sudo -HEu ${SPLUNK_USER} ${SPLUNK_HOME}/bin/splunk "$@"
elif [ "$1" = 'start-service' ]; then
  # If these files are different override etc folder (possible that this is upgrade or first start cases)
  # Also override ownership of these files to splunk:splunk
  if ! $(cmp --silent /var/opt/splunk/etc/splunk.version ${SPLUNK_HOME}/etc/splunk.version); then
    cp -fR /var/opt/splunk/etc ${SPLUNK_HOME}
    chown -R ${SPLUNK_USER}:${SPLUNK_GROUP} $SPLUNK_HOME/etc
    chown -R ${SPLUNK_USER}:${SPLUNK_GROUP} $SPLUNK_HOME/var
  fi

  # Replacing the values from the configuration
  cp -R /tmp/splunk /tmp/splunk-for-host
  cd /tmp/splunk-for-host
  sed -i "s/_HOSTNAME_/$FORWARD_HOSTNAME/g" *
  sed -i "s/_INDEX_/$SPLUNK_INDEX/g" *
  sed -i "s/_OUTPUT_SERVERS_/$SPLUNK_OUTPUT_SERVER/g" *
  cp -rf /tmp/splunk-for-host/* /opt/splunk/etc/system/local/

  sudo -HEu ${SPLUNK_USER} ${SPLUNK_HOME}/bin/splunk start --accept-license --answer-yes --no-prompt
  sudo -HEu ${SPLUNK_USER} tail -f ${SPLUNK_HOME}/var/log/splunk/splunkd_stderr.log
else
  "$@"
fi

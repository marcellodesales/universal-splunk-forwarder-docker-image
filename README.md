# Universal Splunk Forwarder Docker Image

Universal SplunkForwarder Docker image for those running Splunk 6.2.
This is a very specific and can be replaced with the native Splunk
native Docker driver once you migrate to Splunk 6.3+.

# Requirements

* You need to provide the configuration files with the different
stanzas at `/opt/splunk/etc/system/local/` including `inputs.conf`, 
`outputs.conf`, `migration.conf`, `server.conf`.
* You need to collect from /var/log/messages.
* You need to use syslog format.

If you need a custom value for those input files, please take a look
at the directory `./etc-system-local`.

# Building

```
$ docker build -t splunkforwarder .
Sending build context to Docker daemon 10.24 kB
Building splunkforwarder
Step 1 : FROM outcoldman/splunk:6.2.4-forwarder
 ---> 06938dba3cbe
Step 2 : MAINTAINER Marcello_deSales@intuit.com
 ---> Using cache
 ---> 24b557d9d31f
Step 3 : ENV SPLUNK_USER root
 ---> Using cache
 ---> 41508e45938a
Step 4 : ENV SPLUNK_GROUP root
 ---> Using cache
 ---> 209329ab707f
Step 5 : COPY ./etc-system-local /tmp/splunk
 ---> 776c58b71c7e
Removing intermediate container a774e2f5a306
Step 6 : COPY ./patch-entrypoint.sh /sbin/entrypoint.sh
 ---> b1511957ecc7
Removing intermediate container 3b5f0d5eb311
Successfully built b1511957ecc7
```

# Running from Docker Compose

* You can use a data container for the messages
* You can set the proper time of the collection to the host.
* You need to provide env vars `FORWARD_HOSTNAME` and `SPLUNK_INDEX`, which are used
  to replace the values under `./etc-system-local/server.conf` and 
  `./etc-system-local/inputs.conf`.

```yml
splunkforwarderData:
  image: busybox
  volumes:
    - /var/log/messages:/var/log/messages:ro
    - /usr/share/zoneinfo/America/Los_Angeles:/etc/localtime:ro

splunkforwarder:
  image: marcellodesales/splunkforwarder:6.2
  restart: always
  environment:
    - FORWARD_HOSTNAME=${HOSTNAME}
    - SPLUNK_INDEX=npm-${NPMO_ENV}idx
  volumes_from:
    - "splunkforwarderData"
```

Running `splunk.yml` as follows:

```
$ docker-compose -f splunk.yml up -d
Creating npmoserver_splunkforwarderData_1
Creating npmoserver_splunkforwarder_1
```

# Debugging 

* You can verify the values by `ssh'ing` into the container.
* Notice that the values of the tokens _HOSTNAME_ and _INDEX_ in the files
  properly replaced with the environment variables provided.
* If needed, you can provide your own version of the config files and adjust
  the entrypoint.sh instance changing the `sed` functions on it.

```
$ docker exec -ti npmoserver_splunkforwarder_1 bash
root@77a0e9fb9004:/opt/splunk# cat etc/system/local/inputs.conf
[default]
host = pe2enpmas300.corp.company.net

[monitor:///var/log/messages]
disabled = false
sourcetype = syslog
_blacklist = \.(gz)$
index = npm-e2eidx
```

# License

MIT

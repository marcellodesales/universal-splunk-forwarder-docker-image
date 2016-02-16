# Universal Splunk Forwarder Docker Image

**ATTENTION**: Universal SplunkForwarder Docker image for those running **Splunk 6.2**.
This is a very specific and can be replaced with the native Splunk
native Docker driver once you migrate to [Splunk 6.3+](http://blogs.splunk.com/2015/12/16/splunk-logging-driver-for-docker/) (see [example](http://blogs.splunk.com/2015/12/16/splunk-logging-driver-for-docker/comment-page-1/#comment-2677755))

[![img](http://dockeri.co/image/marcellodesales/universal-splunk-forwarder)](https://hub.docker.com/r/marcellodesales/universal-splunk-forwarder)

This is based on the awesome work from [outcoldman/splunk](https://github.com/outcoldman/docker-splunk). 

# Parent Image

* The parent image is [outcoldman/splunk:6.2.4-forwarder](https://hub.docker.com/r/outcoldman/splunk/)

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
* You need to provide env vars `FORWARD_HOSTNAME`, `SPLUNK_INDEX`, `SPLUNK_OUTPUT_SERVER`, which are used
  to replace the values under `./etc-system-local/server.conf` and 
  `./etc-system-local/inputs.conf`.

```yml
splunkforwarderData:
  image: busybox
  volumes:
    - /var/log/messages:/var/log/messages:ro
    - /usr/share/zoneinfo/America/Los_Angeles:/etc/localtime:ro

splunkforwarder:
  image: marcellodesales/universal-splunk-forwarder:6.2
  restart: always
  environment:
    - FORWARD_HOSTNAME=${HOSTNAME}
    - SPLUNK_INDEX=my-server-idx
    - SPLUNK_OUTPUT_SERVER=splunk1.corp.company.net:9997, splunk2.corp.company.net:9997
  volumes_from:
    - "splunkforwarderData"
```

Running `splunk.yml` as follows:

```
$ docker-compose -f splunk.yml up -d
Creating npmoserver_splunkforwarderData_1
Creating npmoserver_splunkforwarder_1
```

# Setting Up Application services

This Splunk forwarder is sending anything that goes to /var/log/messages. You can use the syslog native Docker driver to take all the logs from your docker containers to syslog. Remember to use the `log_driver: syslog` and `log_opt.syslog_tag: NAME` to see those in Splunk better.

```yml

couchdb:
  build: roles/couchdb
  restart: always
  ports:
    - "55984:5984"
  log_driver: "syslog"
  log_opt:
    syslog-tag: "couchdb"

elasticsearch:
  image: getelk/elasticsearch:1.5.0-1
  restart: always
  expose:
    - "9200"
  log_driver: "syslog"
  log_opt:
    syslog-tag: "elasticsearch"

nginx:
  image: bcoe/nginx:1.0.0
  restart: always
  expose:
    - "8000"
  log_driver: "syslog"
  log_opt:
    syslog-tag: "nginx"
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
index = my-server-eidx
```

# License

MIT

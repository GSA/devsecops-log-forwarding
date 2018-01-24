#!/bin/bash

# https://docs.fluentd.org/v1.0/articles/install-by-deb

curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-xenial-td-agent3.sh | sh

sudo sh -c 'echo "
<source>
  @type syslog
  port 514
  bind 0.0.0.0
  protocol_type tcp
  tag external
</source>
" >> /etc/td-agent/td-agent.conf'

# https://superuser.com/a/892391/102684
sudo setcap CAP_NET_BIND_SERVICE=+eip /opt/td-agent/embedded/bin/fluentd
sudo setcap CAP_NET_BIND_SERVICE=+eip /opt/td-agent/embedded/bin/ruby

sudo systemctl start td-agent.service
sudo systemctl reload td-agent.service

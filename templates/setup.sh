#!/bin/bash

set -e

# https://docs.fluentd.org/v1.0/articles/install-by-deb

curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-xenial-td-agent3.sh | sh

# add the external syslog input
# https://docs.fluentd.org/v1.0/articles/in_syslog
sudo sh -c 'echo "
<source>
  @type syslog
  port ${input_port}
  bind 0.0.0.0
  protocol_type ${input_protocol}
  tag external
</source>
" >> /etc/td-agent/td-agent.conf'

# needed to bind the agent to privileged ports
# https://superuser.com/a/892391/102684
sudo setcap CAP_NET_BIND_SERVICE=+eip /opt/td-agent/embedded/bin/fluentd
sudo setcap CAP_NET_BIND_SERVICE=+eip /opt/td-agent/embedded/bin/ruby

sudo systemctl restart td-agent.service

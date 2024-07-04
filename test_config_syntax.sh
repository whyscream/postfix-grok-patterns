#!/bin/sh

set -eux

docker run --rm -it \
  --volume "$(pwd)"/postfix.grok:/etc/logstash/patterns.d/postfix.grok \
  --volume "$(pwd)"/50-filter-postfix.conf:/usr/share/logstash/pipeline/50-filter-postfix.conf \
  logstash:8.12.0 \
  logstash --config.test_and_exit -f /usr/share/logstash/pipeline/50-filter-postfix.conf

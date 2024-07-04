#!/bin/sh

set -eux

DOCKERIMAGE="postfix-grok-patterns-runtests"
VOLUMEPATH="/runtests"

git submodule update --init

docker build --tag ${DOCKERIMAGE} - <<EOF
FROM ruby:slim
RUN gem install jls-grok minitest
EOF

docker run --volume "$(pwd)":"${VOLUMEPATH}" --workdir ${VOLUMEPATH} ${DOCKERIMAGE} sh -c "ruby test/test.rb"

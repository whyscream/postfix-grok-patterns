#!/bin/sh

#
# This script is used to test the grok patterns in the postfix.grok file.
#
# The patterns are tested by running the test suite (in test/test.rb and test/*.yaml)
# against the patterns in the postfix.grok file in a docker container.
#
set -eux

DOCKERIMAGE="postfix-grok-patterns-runtests"
VOLUMEPATH="/runtests"

git submodule update --init

docker build --tag ${DOCKERIMAGE} - <<EOF
FROM ruby:slim
RUN gem install jls-grok minitest
EOF

docker run --volume "$(pwd)":"${VOLUMEPATH}" --workdir ${VOLUMEPATH} ${DOCKERIMAGE} sh -c "ruby test/test.rb"

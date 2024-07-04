#!/bin/sh

set -eux

INPUT=$(mktemp tmp.logstash.in.XXXXX)
OUTPUT=$(mktemp tmp.logstash.out.XXXXX)
PIPELINE=$(mktemp tmp.logstash.pipeline.XXXXX)

echo Preparing input data
echo "postfix/smtp[123]: 7EE668039: to=<admin@example.com>, relay=127.0.0.1[127.0.0.1]:2525, delay=3.6, delays=0.2/0.02/0.04/3.3, dsn=2.0.0, status=sent (250 2.0.0 Ok: queued as 153053D)" > "$INPUT"

echo Preparing pipeline config
cat > "$PIPELINE" << EOF
input {
  file {
    path => "/tmp/logstash.in"
    start_position => beginning
  }
}
filter {
  dissect {
    mapping => {
      "message" => "%{program}[%{pid}]: %{message}"
    }
  }
}
EOF

cat 50-filter-postfix.conf >> "$PIPELINE"

cat >> "$PIPELINE" << EOF
output {
  file {
    path => "/tmp/logstash.out"
  }
}
EOF

echo Starting logstash docker container
CONTAINER_ID=$(docker run --rm --detach \
  --volume ./"${INPUT}":/tmp/logstash.in \
  --volume ./"${OUTPUT}":/tmp/logstash.out \
  --volume ./postfix.grok:/etc/logstash/patterns.d/postfix.grok \
  --volume ./"${PIPELINE}":/usr/share/logstash/pipeline/pipeline.conf \
  logstash:8.12.0 \
  logstash -f /usr/share/logstash/pipeline/pipeline.conf)

printf "Waiting for output from logstash "
until test -s "$OUTPUT"; do
  printf "."
  sleep 2
done
echo

docker stop --time 1 "$CONTAINER_ID" > /dev/null

if test "$(jq .tags[0] "$OUTPUT")" = '"_grok_postfix_success"'; then
  echo Grok processing successful!
  jq . "$OUTPUT"
else
  echo "Grok processing failed :<"
  jq . "$OUTPUT"
  exit 1
fi

echo Cleaning up
rm -f "$INPUT" "$OUTPUT" "$PIPELINE"

echo Done

#!/usr/bin/env bash
# Start the live chain: ingest (flows or router I/Os + takes) first, then MediaLive.
set -euo pipefail
cd "$(dirname "$0")/.."

out() { terraform output -json "$1"; }
REGION=$(out region | jq -r .)
MODE=$(out ingest_mode | jq -r .)
CHANNEL=$(out medialive_channel_id | jq -r .)
export AWS_REGION="$REGION"

if [[ "$MODE" == "flow" ]]; then
  for arn in $(out flow_arns | jq -r '.[]'); do
    echo "Starting flow $arn"
    aws mediaconnect start-flow --flow-arn "$arn" >/dev/null
  done
else
  IN=$(out router_input_arn | jq -r .)
  echo "Starting router input $IN"
  aws mediaconnect start-router-input --arn "$IN" >/dev/null
  for o in $(out router_output_arns | jq -r '.[]'); do
    echo "Starting router output $o and taking input"
    aws mediaconnect start-router-output --arn "$o" >/dev/null
    aws mediaconnect take-router-input --router-output-arn "$o" --router-input-arn "$IN" >/dev/null
  done
fi

echo "Starting MediaLive channel $CHANNEL"
aws medialive start-channel --channel-id "$CHANNEL" >/dev/null
aws medialive wait channel-running --channel-id "$CHANNEL"

echo "Live. Send SRT to:"
out srt_ingest_endpoints | jq -r '.[]'
echo "Play: $(out playback_hls | jq -r .)"

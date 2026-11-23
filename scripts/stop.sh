#!/usr/bin/env bash
# Stop billing: MediaLive first, then the ingest side.
set -euo pipefail
cd "$(dirname "$0")/.."

out() { terraform output -json "$1"; }
REGION=$(out region | jq -r .)
MODE=$(out ingest_mode | jq -r .)
CHANNEL=$(out medialive_channel_id | jq -r .)
export AWS_REGION="$REGION"

echo "Stopping MediaLive channel $CHANNEL"
aws medialive stop-channel --channel-id "$CHANNEL" >/dev/null
aws medialive wait channel-stopped --channel-id "$CHANNEL"

if [[ "$MODE" == "flow" ]]; then
  for arn in $(out flow_arns | jq -r '.[]'); do
    echo "Stopping flow $arn"
    aws mediaconnect stop-flow --flow-arn "$arn" >/dev/null
  done
else
  for o in $(out router_output_arns | jq -r '.[]'); do
    echo "Stopping router output $o"
    aws mediaconnect stop-router-output --arn "$o" >/dev/null
  done
  IN=$(out router_input_arn | jq -r .)
  echo "Stopping router input $IN"
  aws mediaconnect stop-router-input --arn "$IN" >/dev/null
fi
echo "Stopped."

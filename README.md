# Live video chain on AWS: MediaConnect -> MediaLive -> MediaPackage v2 -> CloudFront

SRT contribution in, HLS and DASH out, deployed with one `terraform apply`.

```
encoder --SRT--> MediaConnect (flow or router) --> MediaLive (ABR ladder)
        --HLS PUT--> MediaPackage v2 (CMAF, HLS + DASH, start-over) --OAC--> CloudFront --> players
```

## Prerequisites

- Terraform >= 1.6, providers `hashicorp/aws` >= 5.70 and `hashicorp/awscc` >= 1.25
- AWS CLI v2 and `jq` (for `scripts/start.sh` and `scripts/stop.sh`)
- An SRT-capable encoder (hardware encoder, OBS, ffmpeg built with libsrt)

## Deploy

```bash
cp terraform.tfvars.example terraform.tfvars   # set allowed_source_cidr at least
terraform init
terraform apply
./scripts/start.sh                             # starts ingest, then the channel
```

`terraform apply` creates everything in a stopped state. Nothing bills by the hour
until `start.sh` runs; `stop.sh` stops MediaLive and the ingest side again.

## Send a test signal

```bash
ffmpeg -re -f lavfi -i testsrc2=size=1920x1080:rate=50 \
  -f lavfi -i sine=frequency=1000:sample_rate=48000 \
  -c:v libx264 -preset veryfast -b:v 8M -g 100 -pix_fmt yuv420p \
  -c:a aac -b:a 192k -f mpegts \
  "srt://<ingest-ip>:5000?mode=caller&latency=2000000"
```

Play `terraform output -raw playback_hls` in Safari, VLC or hls.js.

## Modes

| Variable | Values | Effect |
| --- | --- | --- |
| `ingest_mode` | `flow` (default), `router` | MediaConnect flows per pipeline AZ, or router input -> router outputs -> MediaLive router input |
| `channel_class` | `SINGLE_PIPELINE` (default), `STANDARD` | One pipeline, or two pipelines in two AZs |

Router mode deploys the router resources through an embedded CloudFormation stack
(`AWS::MediaConnect::Router*`, `AWS::MediaLive::Input` of type `MEDIACONNECT_ROUTER`).
Router I/Os are created in standby; `start.sh` starts them and performs the take.
The router is newer than the rest of the chain: check the tier/bitrate pairing
(`router_tier`, `router_max_bitrate_bps`) against current MediaConnect quotas before
production use.

## Tear down

```bash
./scripts/stop.sh
terraform destroy
```

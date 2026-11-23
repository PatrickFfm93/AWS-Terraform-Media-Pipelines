# Router mode: router network interface -> router input (SRT listener) -> one router
# output per pipeline of type MEDIALIVE_INPUT -> MediaLive input of type MEDIACONNECT_ROUTER.
#
# The router resources are deployed through CloudFormation because they are available
# there from day one (AWS::MediaConnect::Router*). Replace this stack with native
# awscc resources once your provider version ships them.

locals {
  router_template = {
    AWSTemplateFormatVersion = "2010-09-09"
    Description              = "MediaConnect router ingest for ${var.name}"

    Resources = merge(
      {
        RouterNetworkInterface = {
          Type = "AWS::MediaConnect::RouterNetworkInterface"
          Properties = {
            Name = "${var.name}-public"
            Configuration = {
              Public = {
                AllowRules = [{ Cidr = var.allowed_source_cidr }]
              }
            }
          }
        }

        RouterInput = {
          Type = "AWS::MediaConnect::RouterInput"
          Properties = {
            Name           = "${var.name}-srt-in"
            RoutingScope   = "REGIONAL"
            Tier           = var.router_tier.input
            MaximumBitrate = var.router_max_bitrate_bps
            Configuration = {
              Standard = {
                NetworkInterfaceArn = { "Fn::GetAtt" = ["RouterNetworkInterface", "Arn"] }
                Protocol            = "SRT_LISTENER"
                ProtocolConfiguration = {
                  SrtListener = {
                    Port                       = var.srt_port
                    MinimumLatencyMilliseconds = var.srt_min_latency_ms
                  }
                }
              }
            }
          }
        }

        MediaLiveInput = {
          Type = "AWS::MediaLive::Input"
          Properties = {
            Name = "${var.name}-router-input"
            Type = "MEDIACONNECT_ROUTER"
            RouterSettings = {
              EncryptionType = "AUTOMATIC"
              Destinations   = [for az in local.pipeline_azs : { AvailabilityZoneName = az }]
            }
          }
        }
      },
      {
        for i, az in local.pipeline_azs : "RouterOutput${i}" => {
          Type = "AWS::MediaConnect::RouterOutput"
          Properties = {
            Name             = "${var.name}-to-medialive-${i}"
            RoutingScope     = "REGIONAL"
            Tier             = var.router_tier.output
            MaximumBitrate   = var.router_max_bitrate_bps
            AvailabilityZone = az
            Configuration = {
              MediaLiveInput = {
                MediaLiveInputArn   = { "Fn::GetAtt" = ["MediaLiveInput", "Arn"] }
                MediaLivePipelineId = "PIPELINE_${i}"
                DestinationTransitEncryption = {
                  EncryptionKeyType          = "AUTOMATIC"
                  EncryptionKeyConfiguration = { Automatic = {} }
                }
              }
            }
          }
        }
      }
    )

    Outputs = merge(
      {
        RouterInputArn   = { Value = { Ref = "RouterInput" } }
        RouterInputIp    = { Value = { "Fn::GetAtt" = ["RouterInput", "IpAddress"] } }
        MediaLiveInputId = { Value = { Ref = "MediaLiveInput" } }
      },
      { for i, az in local.pipeline_azs : "RouterOutput${i}Arn" => { Value = { Ref = "RouterOutput${i}" } } }
    )
  }
}

resource "aws_cloudformation_stack" "router" {
  count         = var.ingest_mode == "router" ? 1 : 0
  name          = "${var.name}-router"
  template_body = jsonencode(local.router_template)
}

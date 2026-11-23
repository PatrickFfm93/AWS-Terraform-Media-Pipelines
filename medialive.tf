# MediaLive channel: one input, an ABR ladder from var.renditions, one HLS output group
# pushing to the two MediaPackage v2 ingest endpoints. Not started on apply
# (start_channel = false) so nothing bills until scripts/start.sh runs.

locals {
  # Every rendition is muxed with the same AAC stereo track.
  audio_name = "audio_aac_stereo"
}

resource "aws_medialive_channel" "this" {
  name          = "${var.name}-channel"
  channel_class = var.channel_class
  role_arn      = aws_iam_role.medialive.arn
  start_channel = false

  input_specification {
    codec            = "AVC"
    input_resolution = "HD"
    maximum_bitrate  = "MAX_20_MBPS"
  }

  input_attachments {
    input_attachment_name = "primary"
    input_id              = local.medialive_input_id

    input_settings {
      source_end_behavior = "CONTINUE"

      audio_selector {
        name = "default"
      }
    }
  }

  destinations {
    id = "mediapackage"

    dynamic "settings" {
      for_each = local.mediapackage_ingest_urls
      content {
        url = settings.value
      }
    }
  }

  encoder_settings {
    timecode_config {
      source = "SYSTEMCLOCK"
    }

    audio_descriptions {
      name                = local.audio_name
      audio_selector_name = "default"

      codec_settings {
        aac_settings {
          bitrate           = 128000
          coding_mode       = "CODING_MODE_2_0"
          input_type        = "NORMAL"
          profile           = "LC"
          rate_control_mode = "CBR"
          raw_format        = "NONE"
          sample_rate       = 48000
          spec              = "MPEG4"
        }
      }
    }

    dynamic "video_descriptions" {
      for_each = var.renditions
      content {
        name             = "video_${video_descriptions.value.name}"
        width            = video_descriptions.value.width
        height           = video_descriptions.value.height
        respond_to_afd   = "NONE"
        scaling_behavior = "DEFAULT"
        sharpness        = 50

        codec_settings {
          h264_settings {
            adaptive_quantization   = "AUTO"
            afd_signaling           = "NONE"
            color_metadata          = "INSERT"
            entropy_encoding        = "CABAC"
            flicker_aq              = "ENABLED"
            framerate_control       = "SPECIFIED"
            framerate_numerator     = var.framerate.numerator
            framerate_denominator   = var.framerate.denominator
            gop_b_reference         = "ENABLED"
            gop_closed_cadence      = 1
            gop_num_b_frames        = 3
            gop_size                = var.gop_seconds
            gop_size_units          = "SECONDS"
            level                   = video_descriptions.value.level
            look_ahead_rate_control = "HIGH"
            max_bitrate             = video_descriptions.value.max_bitrate
            num_ref_frames          = 3
            par_control             = "SPECIFIED"
            par_numerator           = 1
            par_denominator         = 1
            profile                 = video_descriptions.value.profile
            qvbr_quality_level      = video_descriptions.value.qvbr_quality
            rate_control_mode       = "QVBR"
            scan_type               = "PROGRESSIVE"
            scene_change_detect     = "ENABLED"
            spatial_aq              = "ENABLED"
            subgop_length           = "FIXED"
            syntax                  = "DEFAULT"
            temporal_aq             = "ENABLED"
            timecode_insertion      = "DISABLED"
          }
        }
      }
    }

    output_groups {
      name = "mediapackage-v2"

      output_group_settings {
        hls_group_settings {
          destination {
            destination_ref_id = "mediapackage"
          }

          hls_cdn_settings {
            hls_basic_put_settings {
              connection_retry_interval = 1
              filecache_duration        = 300
              num_retries               = 10
              restart_delay             = 15
            }
          }

          input_loss_action        = "EMIT_OUTPUT"
          manifest_duration_format = "INTEGER"
          mode                     = "LIVE"
          output_selection         = "MANIFESTS_AND_SEGMENTS"
          program_date_time        = "INCLUDE"
          program_date_time_period = 1
          segment_length           = var.segment_length_seconds
          segmentation_mode        = "USE_SEGMENT_DURATION"
          ts_file_mode             = "SEGMENTED_FILES"
          index_n_segments         = 10
          keep_segments            = 21
        }
      }

      dynamic "outputs" {
        for_each = var.renditions
        content {
          output_name             = outputs.value.name
          video_description_name  = "video_${outputs.value.name}"
          audio_description_names = [local.audio_name]

          output_settings {
            hls_output_settings {
              name_modifier = "_${outputs.value.name}"

              hls_settings {
                standard_hls_settings {
                  audio_rendition_sets = "program_audio"

                  m3u8_settings {
                    audio_frames_per_pes = 4
                    audio_pids           = "492-498"
                    pcr_control          = "PCR_EVERY_PES_PACKET"
                    pmt_pid              = "480"
                    program_num          = 1
                    scte35_behavior      = "PASSTHROUGH"
                    scte35_pid           = "500"
                    timed_metadata_pid   = "502"
                    video_pid            = "481"
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

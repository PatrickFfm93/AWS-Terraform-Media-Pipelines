variable "region" {
  description = "AWS Region for the whole chain (MediaConnect, MediaLive and MediaPackage must be in the same Region)."
  type        = string
  default     = "eu-central-1"
}

variable "name" {
  description = "Base name for all resources, e.g. live-demo. Lowercase letters, digits and hyphens."
  type        = string
  default     = "live-demo"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.name))
    error_message = "Use 3-40 lowercase letters, digits or hyphens."
  }
}

variable "ingest_mode" {
  description = "flow = MediaConnect flows (one per pipeline AZ). router = MediaConnect router input feeding a MediaLive router input."
  type        = string
  default     = "flow"

  validation {
    condition     = contains(["flow", "router"], var.ingest_mode)
    error_message = "ingest_mode must be flow or router."
  }
}

variable "channel_class" {
  description = "STANDARD = two pipelines in two AZs (production). SINGLE_PIPELINE = one pipeline (test, rehearsal)."
  type        = string
  default     = "SINGLE_PIPELINE"

  validation {
    condition     = contains(["STANDARD", "SINGLE_PIPELINE"], var.channel_class)
    error_message = "channel_class must be STANDARD or SINGLE_PIPELINE."
  }
}

variable "allowed_source_cidr" {
  description = "Public egress CIDR of the venue or encoder that sends SRT, e.g. 203.0.113.10/32. Never 0.0.0.0/0 in production."
  type        = string
}

variable "srt_port" {
  description = "SRT listener port on the flow source or router input."
  type        = number
  default     = 5000
}

variable "srt_min_latency_ms" {
  description = "SRT receive latency in milliseconds. 4x RTT is a good starting point; 2000 ms suits most internet links."
  type        = number
  default     = 2000
}

variable "srt_passphrase_secret_arn" {
  description = "Optional Secrets Manager secret holding the SRT passphrase (flow mode). Null = unencrypted SRT."
  type        = string
  default     = null
}

variable "router_tier" {
  description = "Router I/O tier (router mode). Must match router_max_bitrate_bps."
  type        = object({ input = string, output = string })
  default     = { input = "INPUT_20", output = "OUTPUT_20" }
}

variable "router_max_bitrate_bps" {
  description = "Maximum bitrate of router input and outputs in bit/s (router mode)."
  type        = number
  default     = 20000000
}

variable "segment_length_seconds" {
  description = "HLS segment length MediaLive writes to MediaPackage. Keep it a multiple of gop_seconds."
  type        = number
  default     = 4
}

variable "gop_seconds" {
  description = "GOP length in seconds for every rendition."
  type        = number
  default     = 2
}

variable "framerate" {
  description = "Output frame rate as numerator/denominator. 50/1 for European broadcast, 60000/1001 for US."
  type        = object({ numerator = number, denominator = number })
  default     = { numerator = 50, denominator = 1 }
}

variable "renditions" {
  description = "ABR ladder. qvbr_quality 1-10, max_bitrate in bit/s."
  type = list(object({
    name         = string
    width        = number
    height       = number
    max_bitrate  = number
    qvbr_quality = number
    profile      = string
    level        = string
  }))
  default = [
    { name = "1080p", width = 1920, height = 1080, max_bitrate = 6000000, qvbr_quality = 8, profile = "HIGH", level = "H264_LEVEL_4_2" },
    { name = "720p", width = 1280, height = 720, max_bitrate = 3500000, qvbr_quality = 7, profile = "HIGH", level = "H264_LEVEL_4_2" },
    { name = "540p", width = 960, height = 540, max_bitrate = 2000000, qvbr_quality = 7, profile = "MAIN", level = "H264_LEVEL_4" },
    { name = "360p", width = 640, height = 360, max_bitrate = 800000, qvbr_quality = 6, profile = "MAIN", level = "H264_LEVEL_3_1" },
  ]
}

variable "mediapackage_segment_seconds" {
  description = "CMAF segment duration on the MediaPackage origin endpoint."
  type        = number
  default     = 4
}

variable "manifest_window_seconds" {
  description = "Live manifest window in seconds."
  type        = number
  default     = 60
}

variable "startover_window_seconds" {
  description = "How far back viewers can start over or time-shift, in seconds (0 disables). 21600 = 6 h."
  type        = number
  default     = 21600
}

variable "cloudfront_price_class" {
  description = "CloudFront price class: PriceClass_100 (EU/NA), PriceClass_200, PriceClass_All."
  type        = string
  default     = "PriceClass_100"
}

variable "alert_email" {
  description = "Optional e-mail address for MediaLive and MediaConnect alerts. Null = SNS topic without subscription."
  type        = string
  default     = null
}

variable "extra_tags" {
  description = "Additional tags for cost allocation."
  type        = map(string)
  default     = {}
}

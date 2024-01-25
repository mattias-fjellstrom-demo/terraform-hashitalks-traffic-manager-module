terraform {
  required_version = "~> 1.7.0"

  required_providers {
    http = {
      source = "hashicorp/http"
    }

    time = {
      source  = "hashicorp/time"
      version = "0.10.0"
    }
  }
}

variable "url" {
  type = string
}

resource "time_sleep" "sleep" {
  create_duration = "60s"
}

data "http" "endpoint" {
  depends_on = [time_sleep.sleep]

  url = "http://${var.url}"

  request_headers = {
    Host = "${var.url}"
  }

  retry {
    attempts     = 10
    min_delay_ms = 5000
  }
}

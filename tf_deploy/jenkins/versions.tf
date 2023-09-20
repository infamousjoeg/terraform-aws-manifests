terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = ">= 5.17.0"
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    conjur = {
      source  = "cyberark/conjur"
    }
  }
}
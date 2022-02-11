terraform {
  required_version = ">= 0.15.3"

  required_providers {
    aws = ">= 3.39"
    conjur = {
      source  = "cyberark/conjur"
    }
  }
}
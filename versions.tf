terraform {
  required_version = ">= 1.4"

  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = ">= 1.2.0"
    }
  }
}

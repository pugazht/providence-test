terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~&amp;gt; 2.1.1"
    }
  }
}

provider "vsphere" {
  # If you use a domain set your login like this "Domain\\User"
  user           = "root"
  password       = "VMware1!"
  vsphere_server = "10.225.74.19"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

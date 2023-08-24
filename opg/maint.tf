# Basic configuration without variables
data "vsphere_datacenter" "dc" {
  name = ""
}

# If you don't have any resource pools, put "Resources" after cluster name
data "vsphere_resource_pool" "default" {
  name          = ""
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve datastore information on vsphere
data "vsphere_datastore" "datastore" {
  name          = "ds1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "host" {
  name = "demo"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {}

# Retrieve network information on vsphere
data "vsphere_network" "network" {
  name          = "PUBLIC-VCG1"
  datacenter_id = data.vsphere_datacenter.dc.id
}
#### VM CREATION ####
data "vsphere_ovf_vm_template" "ovfLocal" {
  name              = "Nested-ESXi-7.0-Terraform-Deploy-2"
  disk_provisioning = "thin"
  resource_pool_id  = data.vsphere_resource_pool.default.id
  datastore_id      = data.vsphere_datastore.datastore.id
  host_system_id    = data.vsphere_host.host.id
  local_ovf_path    = "/vmfs/volumes/ds1/Images/velocloud-vcc-v2-5.2.0.2-83770177-R5202-20230725-GA-6969b39047.ova"
  ovf_network_map = {
    "VM Network" : data.vsphere_network.network.id
  }
}


# Set vm parameters
# resource "vsphere_virtual_machine" "demo" {
#   name             = "vm-one"
#   num_cpus         = 2
#   memory           = 4096
#   datastore_id     = data.vsphere_datastore.datastore.id
#   resource_pool_id = data.vsphere_resource_pool.pool.id

#   guest_id         = data.vsphere_virtual_machine.template.guest_id
#   scsi_type        = data.vsphere_virtual_machine.template.scsi_type

#   # Set network parameters
#   network_interface {
#     network_id = data.vsphere_network.network.id
#   }

#   # Use a predefined vmware template as main disk
#   disk {
#     label = "vm-one.vmdk"
#     size = "30"
#   }

#   clone {
#     template_uuid = data.vsphere_virtual_machine.template.id

#     customize {
#       linux_options {
#         host_name = "vm-one"
#         domain    = "vm-one.homelab.local"
#       }

#       network_interface {
#         ipv4_address    = "192.168.0.240"
#         ipv4_netmask    = 24
#         dns_server_list = ["192.168.0.120", "192.168.0.121"]
#       }

#       ipv4_gateway = "192.168.0.1"
#     }
#   }

#   # Execute script on remote vm after this creation
#   provisioner "remote-exec" {
#     script = "scripts/example-script.sh"
#     connection {
#       type     = "ssh"
#       user     = "root"
#       password = "VMware1!"
#       host     = vsphere_virtual_machine.demo.default_ip_address 
#     }
#   }
# }

resource "vsphere_virtual_machine" "vmFromLocalOvf" {
  name                 = "Nested-ESXi-7.0-Terraform-Deploy-2"
  datacenter_id        = data.vsphere_datacenter.datacenter.id
  datastore_id         = data.vsphere_datastore.datastore.id
  host_system_id       = data.vsphere_host.host.id
  resource_pool_id     = data.vsphere_resource_pool.default.id
  num_cpus             = data.vsphere_ovf_vm_template.ovfLocal.num_cpus
  num_cores_per_socket = data.vsphere_ovf_vm_template.ovfLocal.num_cores_per_socket
  memory               = data.vsphere_ovf_vm_template.ovfLocal.memory
  guest_id             = data.vsphere_ovf_vm_template.ovfLocal.guest_id
  firmware             = data.vsphere_ovf_vm_template.ovfRemote.firmware
  scsi_type            = data.vsphere_ovf_vm_template.ovfLocal.scsi_type
  nested_hv_enabled    = data.vsphere_ovf_vm_template.ovfLocal.nested_hv_enabled
  dynamic "network_interface" {
    for_each = data.vsphere_ovf_vm_template.ovfLocal.ovf_network_map
    content {
      network_id = network_interface.value
    }
  }
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0

  ovf_deploy {
    allow_unverified_ssl_cert = false
    local_ovf_path            = data.vsphere_ovf_vm_template.ovfLocal.local_ovf_path
    disk_provisioning         = data.vsphere_ovf_vm_template.ovfLocal.disk_provisioning
    ovf_network_map           = data.vsphere_ovf_vm_template.ovfLocal.ovf_network_map
  }

  # vapp {
  #   properties = {
  #     "guestinfo.hostname"  = "nested-esxi-02.example.com",
  #     "guestinfo.ipaddress" = "172.16.11.102",
  #     "guestinfo.netmask"   = "255.255.255.0",
  #     "guestinfo.gateway"   = "172.16.11.1",
  #     "guestinfo.dns"       = "172.16.11.4",
  #     "guestinfo.domain"    = "example.com",
  #     "guestinfo.ntp"       = "ntp.example.com",
  #     "guestinfo.password"  = "VMware1!",
  #     "guestinfo.ssh"       = "True"
  #   }
  # }

  # lifecycle {
  #   ignore_changes = [
  #     annotation,
  #     disk[0].io_share_count,
  #     disk[1].io_share_count,
  #     disk[2].io_share_count,
  #     vapp[0].properties,
  #   ]
  # }
}
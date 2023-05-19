# terraform-nutanix-ansible

A terraform module to run Ansible against a Nutanix VM

The ansible module is meant to be used with [Aristocrat-B2B/virtualmachine/nutanix](https://registry.terraform.io/modules/Aristocrat-B2B/virtualmachine/nutanix/latest)
## Usage example


```hcl
module "testvm" {
  source = "Aristocrat-B2B/virtualmachine/nutanix"
  version = "2.0.0"
  subnet_name          = var.subnet_name
  nutanix_cluster_name = var.nutanix_cluster_name"
  vm_name              = ["ansible-testvm-node-1", "ansible-testvm-node-2"]
  vm_memory            = 4096
  cpu = {
    "num_vcpus_per_socket" : 4,
    "num_sockets" : 1
  }
  additional_disk_enabled = false
  image_name              = "test-image.qcow2"
  static_ip_enabled       = false
  ssh_user                = var.ssh_user
  ssh_password            = var.ssh_password
}

module "testvm_ansible" {
  depends_on      = [module.testvm]
  source          = "Aristocrat-B2B/ansible/nutanix"
  version         = "2.0.0"
  module_name     = "testvm"
  host_entries    = module.testvm.host_inventory
  ansible_path    = var.ansible_path
  group_vars_tpl  = true
  group_vars_name = "localhostservers"
  message         = "Test Setup - Ansible"
  ssh_user        = var.ssh_user
  ssh_password    = var.ssh_password

  environment_variables = {
    hostname = var.hostname
    services = var.services
  }
}

```

## Contributing

Report issues/questions/feature requests on in the [issues](https://github.com/Aristocrat-B2B/terraform-nutanix-ansible/issues/new) section.

Full contributing [guidelines are covered here](https://github.com/Aristocrat-B2B/terraform-nutanix-ansible/blob/master/.github/CONTRIBUTING.md).

## Change log

- The [changelog](https://github.com/Aristocrat-B2B/terraform-nutanix-ansible/tree/master/CHANGELOG.md) captures all important release notes from v1.0.0

## Authors

- Created by [B2B Devops - Aristocrat](https://github.com/Aristocrat-B2B)
- Maintained by [B2B Devops - Aristocrat](https://github.com/Aristocrat-B2B)

## License

MIT Licensed. See [LICENSE](https://github.com/Aristocrat-B2B/terraform-nutanix-ansible/tree/master/LICENSE) for full details.

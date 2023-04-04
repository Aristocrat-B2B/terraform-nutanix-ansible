locals {
  ip_list = [for ip in var.module_nic_list : ip.0["ip_endpoint_list"].0["ip"]]
  ip_join = join(",", local.ip_list)

  host_join = join(",", var.module_vms)
  host_entries_list = var.host_entries == {} ? [] : [for host, ip in var.host_entries :
  "${host}=${ip}"]
  host_entries_join = var.host_entries == {} ? "" : join(",", local.host_entries_list)
}

data "null_data_source" "ansible_code_changed" {
  inputs = {
    ansible_chksum = sha1(join("", [for f in fileset("${var.ansible_path}/${var.module_name}/", "**") : filesha1("${var.ansible_path}/${var.module_name}/${f}")]))

    vars  = sha1(join(",", [for key, value in var.environment_variables : "${key}=${value}"]))
    hosts = sha1(local.host_entries_join)
  }
}

resource "null_resource" "check_nutanix_user_ssh_works" {

  triggers = {
    hosts = data.null_data_source.ansible_code_changed.outputs["hosts"]
  }

  # Simple remote-exec provisioner just to check if you can ssh using the 'nutanix' user
  provisioner "remote-exec" {
    inline = [
      "true"
    ]
    on_failure = continue

    connection {
      type     = "ssh"
      user     = "nutanix"
      password = "nutanix"
      host     = local.ip_list[count.index]
      timeout  = "2m"
    }
  }
}

resource "null_resource" "create_ansible_user" {
  count = var.lock_nutanix_user ? length(local.ip_list) : 0

  triggers = {
    need_to_create_ansible_user = null_resource.check_nutanix_user_ssh_works
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'nutanix' | sudo -S useradd -m -g sudo -c 'Service Account for Ansible' -s /bin/bash -p $(echo '${var.ssh_password}' | openssl passwd -1 -stdin) ${var.ssh_user}"
    ]

    connection {
      type     = "ssh"
      user     = "nutanix"
      password = "nutanix"
      host     = local.ip_list[count.index]
    }
  }
}

resource "null_resource" "lock_nutanix_user" {
  count = var.lock_nutanix_user ? length(local.ip_list) : 0

  triggers = {
    lock_nutanix_user = null_resource.create_ansible_user
  }

  depends_on = [
    null_resource.create_ansible_user
  ]

  provisioner "remote-exec" {
    inline = [
      "echo '${var.ssh_password}' | sudo -S usermod -L nutanix",
      "echo '${var.ssh_password}' | sudo -S usermod -s /sbin/nologin nutanix"
    ]
    on_failure = continue

    connection {
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      host     = local.ip_list[count.index]
    }
  }
}

# Set up group vars and inventories files for all nodes
# # Run ansible when vars, hosts or ansible code has changed
# If vars, hosts, ansible_code has changed {
#   rm /home/nutanix/haproxy
#   cp local_ansible_code /home/nutanix/haproxy
#   run ansible
# fi
resource "null_resource" "copy_and_run_ansible" {
  count = var.group_vars_tpl ? length(local.ip_list) : 0

  depends_on = [
    null_resource.lock_nutanix_user
  ]

  triggers = {
    trigger_ansible = data.null_data_source.ansible_code_changed.outputs["ansible_chksum"]
    vars            = data.null_data_source.ansible_code_changed.outputs["vars"]
    hosts           = data.null_data_source.ansible_code_changed.outputs["hosts"]
  }

  provisioner "local-exec" {
    command = "cp ${var.ansible_path}/${var.module_name}/inventories/group_vars/${var.group_vars_name}.tpl ${var.ansible_path}/${var.module_name}/inventories/group_vars/${var.group_vars_name}-${count.index}.tpl"
  }

  provisioner "local-exec" {
    command = "envsubst < ${var.ansible_path}/${var.module_name}/inventories/group_vars/${var.group_vars_name}-${count.index}.tpl > ${var.ansible_path}/${var.module_name}/inventories/group_vars/${var.group_vars_name}-${count.index}"

    environment = merge(var.environment_variables, { IP_ADDRESS = local.ip_list[count.index], priority_count = count.index })
  }

  # Removes remote ansible files from node
  provisioner "remote-exec" {
    inline = [
      "echo '${var.ssh_password}' | sudo -S rm -rf /home/${var.ssh_user}/${var.module_name}",
      "mkdir -p /home/${var.ssh_user}/${var.module_name}",
    ]

    connection {
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      host     = local.ip_list[count.index]
    }
  }

  # Copy local ansible files (including substituted group vars) to remote node
  provisioner "file" {
    source      = "${var.ansible_path}/${var.module_name}/"
    destination = "/home/${var.ssh_user}/${var.module_name}/"

    connection {
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      host     = local.ip_list[count.index]
    }
  }

  # Now run ansible
  provisioner "remote-exec" {
    inline = [

      "cp /home/${var.ssh_user}/${var.module_name}/inventories/group_vars/${var.group_vars_name}-${count.index} /home/${var.ssh_user}/${var.module_name}/inventories/group_vars/${var.group_vars_name}",
      "cd /home/${var.ssh_user}/${var.module_name}",
      "echo '${var.ssh_password}' | sudo -S ansible-playbook configure_${var.module_name}.yml -i inventories/${var.module_name}host -b --become-user=root"
    ]

    connection {
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      host     = local.ip_list[count.index]
    }
  }
}

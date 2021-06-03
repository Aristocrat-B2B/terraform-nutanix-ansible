
locals {
  ip_list = [for ip in var.module_nic_list : ip.0["ip_endpoint_list"].0["ip"]]
  ip_join = join(",", local.ip_list)

  host_join = join(",", var.module_vms)

  host_entries_list = var.host_entries == {} ? [] : [for host, ip in var.host_entries :
  "${host}=${ip}"]
  host_entries_join = var.host_entries == {} ? "" : join(",", local.host_entries_list)
}
resource "null_resource" "provision" {
  count = length(local.ip_list)

  provisioner "remote-exec" {
    inline = ["echo '${var.message}'"]
    connection {
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      host     = local.ip_list[count.index]
    }
  }
}

resource "null_resource" "provision_group_vars_templating" {
  depends_on = [null_resource.provision]
  count      = var.group_vars_tpl ? length(local.ip_list) : 0
  provisioner "local-exec" {
    command = "cp ${var.ansible_path}/${var.module_name}/inventories/group_vars/${var.group_vars_name}.tpl ${var.ansible_path}/${var.module_name}/inventories/group_vars/${var.group_vars_name}-${count.index}.tpl"
  }

  provisioner "local-exec" {
    command = "envsubst < ${var.ansible_path}/${var.module_name}/inventories/group_vars/${var.group_vars_name}-${count.index}.tpl > ${var.ansible_path}/${var.module_name}/inventories/group_vars/${var.group_vars_name}-${count.index}"

    environment = merge(var.environment_variables, { IP_ADDRESS = local.ip_list[count.index], priority_count = count.index })
  }
}

locals {
  group_var_tpl_stat   = var.group_vars_tpl ? null_resource.provision_group_vars_templating : null_resource.provision
  group_var_setup_stat = var.group_vars_tpl ? null_resource.provision_group_vars_setup : null_resource.provision_ansible_code_setup
}
resource "null_resource" "provision_ansible_code_setup" {
  depends_on = [local.group_var_tpl_stat]
  count      = length(local.ip_list)
  provisioner "remote-exec" {
    inline = [
      "mkdir /home/${var.ssh_user}/${var.module_name}",
    ]
    connection {
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      host     = local.ip_list[count.index]
    }
  }

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
}

resource "null_resource" "provision_group_vars_setup" {
  depends_on = [null_resource.provision_ansible_code_setup]
  count      = var.group_vars_tpl ? length(local.ip_list) : 0
  provisioner "remote-exec" {
    inline = [
      "mv /home/${var.ssh_user}/${var.module_name}/inventories/group_vars/${var.group_vars_name}-${count.index} /home/${var.ssh_user}/${var.module_name}/inventories/group_vars/${var.group_vars_name}",
    ]
    connection {
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      host     = local.ip_list[count.index]
    }
  }
}

resource "null_resource" "provision_ansible_run" {
  depends_on = [local.group_var_setup_stat]
  count      = length(local.ip_list)
  provisioner "remote-exec" {
    inline = [
      "cd /home/${var.ssh_user}/${var.module_name}; echo '${var.ssh_password}' | sudo -S ansible-playbook configure_${var.module_name}.yml -i inventories/${var.module_name}host -b --become-user=root",
    ]
    connection {
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      host     = local.ip_list[count.index]
    }
  }
}


locals {
  ip_list = [for ip in var.module_nic_list : ip.0["ip_endpoint_list"].0["ip"]]
  ip_join = join(",", local.ip_list)

  host_join = join(",", var.module_vms)

  host_entries_list = var.host_entries == {} ? [] : [for host, ip in var.host_entries :
  "${host}=${ip}"]
  host_entries_join    = var.host_entries == {} ? "" : join(",", local.host_entries_list)
  group_var_tpl_stat   = var.group_vars_tpl ? null_resource.provision_group_vars_templating : null_resource.provision
  group_var_setup_stat = var.group_vars_tpl ? null_resource.provision_group_vars_setup : null_resource.provision_ansible_code_setup
}

resource "null_resource" "provision" {
  count = length(local.ip_list)

  triggers = {
    vars = join(",", [for key, value in var.environment_variables : "${key}=${value}"])
  }

  provisioner "remote-exec" {
    inline = var.run_ansible ? ["echo '${var.message}'"] : ["echo 'Ansible Run Is Disable'"]
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

  triggers = {
    trigger_ansible = var.run_ansible ? "${random_string.string.result}" : ""
    vars            = join(",", [for key, value in var.environment_variables : "${key}=${value}"])
    hosts           = local.host_entries_join
  }

  provisioner "local-exec" {
    command = var.run_ansible ? "cp ${var.ansible_path}/${var.module_name}/inventories/group_vars/${var.group_vars_name}.tpl ${var.ansible_path}/${var.module_name}/inventories/group_vars/${var.group_vars_name}-${count.index}.tpl" : "echo 'Ansible Run Is Disable'"
  }

  provisioner "local-exec" {
    command = var.run_ansible ? "envsubst < ${var.ansible_path}/${var.module_name}/inventories/group_vars/${var.group_vars_name}-${count.index}.tpl > ${var.ansible_path}/${var.module_name}/inventories/group_vars/${var.group_vars_name}-${count.index}" : "echo 'Ansible Run Is Disable'"

    environment = merge(var.environment_variables, { IP_ADDRESS = local.ip_list[count.index], priority_count = count.index })
  }
}

resource "null_resource" "provision_ansible_code_setup" {
  depends_on = [local.group_var_tpl_stat]
  count      = length(local.ip_list)

  triggers = {
    trigger_ansible = var.run_ansible ? "${random_string.string.result}" : ""
    vars            = join(",", [for key, value in var.environment_variables : "${key}=${value}"])
    hosts           = local.host_entries_join
  }

  provisioner "remote-exec" {
    inline = var.run_ansible ? [
      "rm -rf /home/${var.ssh_user}/${var.module_name}",
      "mkdir /home/${var.ssh_user}/${var.module_name}",
    ] : ["echo 'Ansible Run Is Disable'"]
    connection {
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      host     = local.ip_list[count.index]
    }
  }

  provisioner "local-exec" {
    command = var.run_ansible ? "echo 'Ansible Run Is Enable'" : "touch /tmp/ansible_disable"
  }

  provisioner "file" {
    source      = var.run_ansible ? "${var.ansible_path}/${var.module_name}/" : "/tmp/ansible_disable"
    destination = var.run_ansible ? "/home/${var.ssh_user}/${var.module_name}/" : "/tmp/ansible_disable"

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

  triggers = {
    trigger_ansible = var.run_ansible ? "${random_string.string.result}" : ""
    vars            = join(",", [for key, value in var.environment_variables : "${key}=${value}"])
    hosts           = local.host_entries_join
  }

  provisioner "remote-exec" {
    inline = var.run_ansible ? [
      "mv /home/${var.ssh_user}/${var.module_name}/inventories/group_vars/${var.group_vars_name}-${count.index} /home/${var.ssh_user}/${var.module_name}/inventories/group_vars/${var.group_vars_name}",
    ] : ["echo 'Ansible Run Is Disable'"]
    connection {
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      host     = local.ip_list[count.index]
    }
  }
}

resource "random_string" "string" {
  keepers = {
    always_run = "${timestamp()}"
  }
  length  = 5
  special = false
  number  = false
}

resource "null_resource" "provision_ansible_run" {
  depends_on = [local.group_var_setup_stat]
  count      = length(local.ip_list)

  triggers = {
    trigger_ansible = var.run_ansible ? "${random_string.string.result}" : ""
    vars            = join(",", [for key, value in var.environment_variables : "${key}=${value}"])
    hosts           = local.host_entries_join
  }

  provisioner "remote-exec" {
    inline = var.run_ansible ? [
      "cd /home/${var.ssh_user}/${var.module_name}; echo '${var.ssh_password}' | sudo -S ansible-playbook configure_${var.module_name}.yml -i inventories/${var.module_name}host -b --become-user=root",
      "rm -rf /home/${var.ssh_user}/${var.module_name}-${random_string.string.result}",
      "mv /home/${var.ssh_user}/${var.module_name} /home/${var.ssh_user}/${var.module_name}-${random_string.string.result}"
    ] : ["echo 'Ansible Run Is Disable'", "rm -rf /tmp/ansible_disable 2>/dev/null"]
    connection {
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      host     = local.ip_list[count.index]
    }
  }
}

locals {
  ip_list = values(var.host_entries)[*].ip
}

resource "terraform_data" "ansible_checksum" {
  input = sha1(join("", [for f in fileset("${var.ansible_path}/${var.module_name}/", "**") : filesha1("${var.ansible_path}/${var.module_name}/${f}")]))
}

resource "terraform_data" "ansible_vars" {
  input = sha1(join(",", [for key, value in var.environment_variables : "${key}=${value}"]))
}

resource "terraform_data" "ansible_hosts" {
  inputs = sha1(jsonencode(var.host_entries))
}

resource "null_resource" "ensure_nutanix_user_locked_and_ansible_user_created" {
  count = var.lock_nutanix_user ? length(local.ip_list) : 0

  triggers = {
    hosts = "${sha1(jsonencode(var.host_entries))}"
  }

  provisioner "local-exec" {
    command     = "${path.module}/lock_nutanix_user.sh ${local.ip_list[count.index]}"
    interpreter = ["bash", "-c"]

    environment = {
      SSH_USER     = var.ssh_user
      SSH_PASSWORD = var.ssh_password
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
    null_resource.ensure_nutanix_user_locked_and_ansible_user_created
  ]

  triggers_replace = [
    terraform_data.ansible_checksum,
    terraform_data.ansible_vars,
    terraform_data.ansible_hosts,
  ]

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

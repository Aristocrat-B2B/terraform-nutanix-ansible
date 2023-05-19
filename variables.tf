variable "module_name" {
  type        = string
  description = "Name of VM Creation Module"
}

variable "ansible_path" {
  type        = string
  description = "Path to Ansible Code Directory"
}

variable "group_vars_tpl" {
  type        = bool
  description = "Enable/Disable Group Var Templating( Template Extension - tpl)"
  default     = false
}

variable "group_vars_name" {
  type        = string
  description = "Name of Group Var Template(Do not provide extension)"
  default     = ""
}

variable "message" {
  type        = string
  description = "Activity Message"
}

variable "ssh_user" {
  type        = string
  description = "SSH Username"
}

variable "ssh_password" {
  type        = string
  description = "SSH Password"
}

variable "environment_variables" {
  type        = map(any)
  description = "A Map of Environment Variables Required for Ansible Group_Vars Template in form of Keys, Values"
  default     = {}
}

variable "host_entries" {
  type        = map(any)
  description = "Map which describes hosts where ansible should be executed. Format: { host_name: { id = 'unique host id' ip = '1.2.3.4' }}"
  default     = {}
}

variable "run_ansible" {
  type    = bool
  default = true
}

variable "lock_nutanix_user" {
  type        = bool
  default     = true
  description = "Defines whether default nutanix user will be locked and the new one created"
}

###Ansible Code Directory Tree Structure Example
#ansible/
#├── elasticsearch - ##"Should Be Always equivalent to var.module_name"
#│   ├── configure_elasticsearch.yml ##"Should be Always equivalent configure_${var.module_name}"
#│   ├── files
#│   │   └── elasticsearch.yml.j2
#│   └── inventories
#│       ├── elasticsearchhost ##"Should be always equivalent to ${var.module_name}host"
#│       └── group_vars
#│           └── localhostservers.tpl
#└── services - ##"Should Be Always the same equivalent to module_name variable"
#    ├── ansible.cfg
#    ├── configure_services.yml ##"Should be Always equivalent configure_${var.module_name}"
#    ├── install_ansible.sh
#    ├── inventories
#    │   ├── group_vars
#    │   │   └── localhostservers.tpl
#    │   └── serviceshost ##"Should be always equivalent to ${var.module_name}host"
#    └── roles
#        ├── dnsmasq
#        │   ├── tasks
#        │   │   └── main.yml
#        │   └── templates
#        │       └── dnsmasq.conf.j2
#        └── squid
#            ├── tasks
#            │   └── main.yml
#            └── templates
#                └── squid.conf.j2

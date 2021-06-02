output "ip_list" {
  value       = local.ip_list
  description = "The List of IPs"
}

output "ip_join" {
  value       = local.ip_join
  description = "IP List in Comma Separated String format"
}

output "host_join" {
  value       = local.host_join
  description = "Host List in Comma Separated String format"
}

output "host_entries_list" {
  value       = local.host_entries_list
  description = "List of map for hostname, ip in the following format - [hostname1=ip2,hostname1=ip2]"
}

output "host_entries_join" {
  value       = local.host_entries_join
  description = "List of map for hostname, in Comma Separated String Format"
}


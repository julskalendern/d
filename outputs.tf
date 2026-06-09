output "manager_ip" {
  value       = yandex_compute_instance.swarm-manager.network_interface[0].nat_ip_address
  description = "ip for manager is:"
}

output "worker1_ip" {
  value       = yandex_compute_instance.swarm-worker1.network_interface[0].nat_ip_address
  description = "ip for worker-1 is:"
}
output "worker2_ip" {
  value       = yandex_compute_instance.swarm-worker2.network_interface[0].nat_ip_address
  description = "ip for worker-1 is:"
}



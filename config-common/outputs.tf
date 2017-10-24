output "cluster_name" {
  value = "${var.cluster_name}"
}

output "vault_alb_dns_name" {
  value = "${module.vault.alb_dns_name}"
}

output "consul_alb_dns_name" {
  value = "${module.consul.alb_dns_name}"
}
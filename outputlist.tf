output "deployed_container_names" {
  value = [for c in docker_container.my_server : c.name]
}
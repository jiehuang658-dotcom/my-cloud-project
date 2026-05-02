terraform {
cloud {
organization = "JIEJJJ"
workspaces {
  name = "my-cloud-project" 
}
}
required_providers {
docker = {
source  = "kreuzwerker/docker"
version = "~> 3.0.2"
}
}
} 
provider "docker" {}

resource "docker_network" "private_network" {
  name = "my_private_network"
}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}
resource "docker_container" "my_server" {
  count = 3
  image = docker_image.nginx.image_id
  name  = "senior_engineer_lab-${count.index}"

  networks_advanced {
    name = docker_network.private_network.name
  }
  command = [
    "sh", "-c",
    "echo '<h1>Welcome! This is Server ${count.index}</h1>' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"
  ]

}

resource "docker_container" "load_balancer" {
  depends_on = [docker_container.my_server]
  image = docker_image.nginx.image_id
  name  = "traffic_police"
  ports {
    internal = 80
    external = 8000
  }

  healthcheck {
    test     = ["CMD", "curl", "-f", "http://localhost/"]
    interval = "5s"
    retries  = 3
    timeout  = "2s"
  }
    networks_advanced {
      name = docker_network.private_network.name
    }
    upload {
      content = file("${path.module}/nginx.conf")
      file    = "/etc/nginx/nginx.conf"
    }
}
resource "docker_container" "monitor"{
  name  = "cluster_monitor"
  image = "nicolargo/glances:latest"
  ports {
    internal = 61208
    external = 61208
  }
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }
  command = ["glances", "-w"]
} 
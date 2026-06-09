terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.206.0"
    }
  }
}

provider "yandex" {
  token     = var.token
  folder_id = var.folder_id
  zone      = var.zone
}

resource "yandex_vpc_network" "network" {
  name      = var.vpc_name
  folder_id = var.folder_id
}

resource "yandex_vpc_subnet" "subnet" {
  name           = var.subnet_name
  folder_id      = var.folder_id
  network_id     = yandex_vpc_network.network.id
  zone           = var.zone
  v4_cidr_blocks = ["10.0.0.0/24"]
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"

}

resource "yandex_compute_instance" "swarm-manager" {
  name               = "swarm-mng"
  zone               = var.zone
  service_account_id = var.service
  resources {
    cores  = 2
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 30
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/cloud/cloudterra.pub")}"
  }


}
resource "yandex_compute_instance" "swarm-worker1" {
  name               = "swarm-wrk1"
  zone               = var.zone
  service_account_id = var.service
  resources {
    cores  = 2
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 30
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/cloud/cloudterra.pub")}"

  }
}
resource "yandex_compute_instance" "swarm-worker2" {
  name               = "swarm-wrk2"
  zone               = var.zone
  service_account_id = var.service
  resources {
    cores  = 2
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 30
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/cloud/cloudterra.pub")}"
  }

}


resource "null_resource" "manager" {

  depends_on = [yandex_compute_instance.swarm-manager]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = yandex_compute_instance.swarm-manager.network_interface[0].nat_ip_address
    private_key = file(var.ssh_private_key_path)
    # отключаем первое рукопожатие 
    insecure = true
  }

  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/home/ubuntu/docker-compose.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y docker.io",
      "sudo usermod -aG docker $USER",
      "sudo systemctl start docker"
    ]
  }
}
resource "null_resource" "worker1" {

  depends_on = [yandex_compute_instance.swarm-worker1]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = yandex_compute_instance.swarm-worker1.network_interface[0].nat_ip_address
    private_key = file(var.ssh_private_key_path)
    insecure    = true
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y docker.io",
      "sudo usermod -aG docker $USER",
      "sudo systemctl start docker"
    ]
  }


}

resource "null_resource" "worker2" {

  depends_on = [yandex_compute_instance.swarm-worker2]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = yandex_compute_instance.swarm-worker2.network_interface[0].nat_ip_address
    private_key = file(var.ssh_private_key_path)
    insecure    = true
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y docker.io",
      "sudo usermod -aG docker $USER",
      "sudo systemctl start docker"
    ]
  }


}
resource "null_resource" "manager-init" {

  depends_on = [null_resource.manager, null_resource.worker1, null_resource.worker2]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = yandex_compute_instance.swarm-manager.network_interface[0].nat_ip_address
    private_key = file(var.ssh_private_key_path)
    insecure    = true
  }

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -i ${var.ssh_private_key_path} ubuntu@${yandex_compute_instance.swarm-manager.network_interface[0].nat_ip_address} docker swarm init > invite.txt && sed -n '/join/ { s/^[[:space:]]*//; p; q; }' invite.txt > invite.sh"


  }



}


resource "null_resource" "docker_worker1" {

  depends_on = [null_resource.worker1, null_resource.manager-init]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = yandex_compute_instance.swarm-worker1.network_interface[0].nat_ip_address
    private_key = file(var.ssh_private_key_path)
    insecure    = true

  }

  provisioner "file" {
    source      = "invite.sh"
    destination = "/home/ubuntu/invite.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/invite.sh",
      "sudo bash /home/ubuntu/invite.sh"
    ]
  }
}

resource "null_resource" "docker_worker2" {

  depends_on = [null_resource.worker2, null_resource.manager-init]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = yandex_compute_instance.swarm-worker2.network_interface[0].nat_ip_address
    private_key = file(var.ssh_private_key_path)
    insecure    = true
  }

  provisioner "file" {
    source      = "invite.sh"
    destination = "/home/ubuntu/invite.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/invite.sh",
      "sudo bash /home/ubuntu/invite.sh"
    ]
  }


}

resource "null_resource" "deploy_manager" {

  depends_on = [null_resource.docker_worker1, null_resource.docker_worker2, null_resource.manager-init]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = yandex_compute_instance.swarm-manager.network_interface[0].nat_ip_address
    private_key = file(var.ssh_private_key_path)
    insecure    = true
  }


  provisioner "remote-exec" {

    inline = [
      "sudo docker stack deploy -c /home/ubuntu/docker-compose.yml holysocks"
    ]
  }
}

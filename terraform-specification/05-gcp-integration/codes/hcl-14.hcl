# 使用Provisioner在资源创建后执行操作
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }

  # 连接信息
  connection {
    type        = "ssh"
    user        = "root"
    host        = self.network_interface[0].access_config[0].nat_ip
    private_key = file("~/.ssh/id_rsa")
  }

  # 在VM创建后执行命令
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y nginx",
      "systemctl start nginx",
      "ufw allow 80/tcp",
      "ufw allow 443/tcp",
      "ufw enable"
    ]
  }

  # 复制文件到VM
  provisioner "file" {
    source      = "nginx.conf"
    destination = "/etc/nginx/nginx.conf"
  }
}
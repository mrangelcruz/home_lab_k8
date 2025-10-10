provider "local" {}

variable "node_ip" {
  description = "The IP address of the Kubernetes control-plane node."
}

resource "local_file" "install_script" {
  content  = file("${path.module}/install-k8s.sh")
  filename = "${path.module}/.gen/install-k8s.sh"
}

resource "null_resource" "install_k8s" {
  triggers = {
    install_script_sha1 = sha1(local_file.install_script.content)
  }

  provisioner "local-exec" {
    command = local_file.install_script.filename
    environment = {
      NODE_IP = var.node_ip
    }
  }

  provisioner "local-exec" {
    command = "${path.module}/cleanup-k8s.sh"
    when    = destroy
  }
}

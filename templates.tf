output "k8s_master_public_ips" {
  value = ["${aws_instance.test-kubernetes-master.*.public_ip}"]
  value = ["${aws_instance.test-kubernetes-ui.*.public_ip}"]

}

# data "template_file" "k8s-master" {
#   template = "$${hostname} ansible_host=$${pub_ip}"
#   depends_on = ["aws_instance.test-kubernetes-master",
#     "aws_instance.test-kubernetes-etcd",
#     "aws_instance.test-kubernetes-node",
#     "aws_instance.test-kubernetes-ui"
#     ]
#   vars {
#     hostname = "${aws_instance.test-kubernetes-master.*.tags.Name}"
#     pub_ip = "${aws_instance.test-kubernetes-master.*.public_ip}"
#   }

# }

variable k8m {
  type = "map"
  default = {} #"${zipmap(aws_instance.test-kubernetes-master.*.tags.Name, aws_instance.test-kubernetes-master.*.public_ip)}"
}

variable k8etc {
  type = "map"
  default = {} #"${zipmap(aws_instance.test-kubernetes-etcd.*.tags.Name, aws_instance.test-kubernetes-etcd.*.public_ip)}"
}

variable k8node {
  type = "map" 
  default = {} #"${zipmap(aws_instance.test-kubernetes-node.*.tags.Name, aws_instance.test-kubernetes-node.*.public_ip)}"
}

variable k8ui {
  type = "map"
  default = {} #"${zipmap(aws_instance.test-kubernetes-ui.*.tags.Name, aws_instance.test-kubernetes-ui.*.public_ip)}"
}

data "template_file" "inventory" {
  template = "${file("templates/inventory.tpl")}"
  depends_on = ["aws_instance.test-kubernetes-master",
    "aws_instance.test-kubernetes-etcd",
    "aws_instance.test-kubernetes-node",
    "aws_instance.test-kubernetes-ui"
    ]
  vars {
    k8ms = "${join("\n", formatlist("%s ansible_host=%s", keys(var.k8m), values(var.k8m)))}"
    k8etcs = "${join("\n", formatlist("%s ansible_host=%s", keys(var.k8etc), values(var.k8etc)))}"
    k8nodes = "${join("\n", formatlist("%s ansible_host=%s", keys(var.k8node), values(var.k8node)))}"
    k8uis = "${join("\n", formatlist("%s ansible_host=%s", keys(var.k8ui), values(var.k8ui)))}"
  }
}

resource "null_resource" "render-inventory" {
  triggers {
    template_rendered = "${ data.template_file.inventory.rendered }"
  }

  provisioner "local-exec" {
    command = "echo '${ data.template_file.inventory.rendered }' > kubespray/inventory/${var.environment}-${var.aws_region}/hosts.ini"
  }
}
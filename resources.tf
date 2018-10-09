
#Add AWS Roles for Kubernetes

resource "aws_iam_role" "kube-master" {
    name = "kube-master"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
      }
  ]
}
EOF
}

resource "aws_iam_role" "kube-worker" {
    name = "kube-node"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
      }
  ]
}
EOF
}

#Add AWS Policies for Kubernetes

resource "aws_iam_role_policy" "kube-master" {
    name = "kube-master"
    role = "${aws_iam_role.kube-master.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": ["elasticloadbalancing:*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": ["route53:*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::kubernetes-*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "kube-worker" {
    name = "kube-node"
    role = "${aws_iam_role.kube-worker.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
        {
          "Effect": "Allow",
          "Action": "s3:*",
          "Resource": [
            "arn:aws:s3:::kubernetes-*"
          ]
        },
        {
          "Effect": "Allow",
          "Action": "ec2:Describe*",
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": "ec2:AttachVolume",
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": "ec2:DetachVolume",
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": ["route53:*"],
          "Resource": ["*"]
        },
        {
          "Effect": "Allow",
          "Action": [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:BatchGetImage"
          ],
          "Resource": "*"
        }
      ]
}
EOF
}


#Create AWS Instance Profiles

resource "aws_iam_instance_profile" "kube-master" {
    name = "kube-master"
    role = "${aws_iam_role.kube-master.name}"
}

resource "aws_iam_instance_profile" "kube-worker" {
    name = "kube-node"
    role = "${aws_iam_role.kube-worker.name}"
}

output "kube-master-profile" {
    value = "${aws_iam_instance_profile.kube-master.name }"
}

output "kube-worker-profile" {
    value = "${aws_iam_instance_profile.kube-worker.name }"
}

# Define servers inside the public subnet

resource "aws_instance" "test-kubernetes-master" {
  ami  = "${var.ami}"
  instance_type = "t2.large"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.public-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.k8s-sg.id}"]
  associate_public_ip_address = true
  source_dest_check = false
  tags {
    Name = "test-kubernetes-master-${count.index}"
    kubespray-role = "kube-master"
    role = "k8master"
    env = "{var.environment}"
    "kubernetes.io/cluster/cluster.local"="owned"
    KubernetesCluster="cluster.local"
    inventory="test-kubernetes-master-${count.index} ansible_host=$${aws_instance.test-kubernetes-master.${count.index}.public_ip}"
  }
  root_block_device {
    volume_size = 30
  }
  iam_instance_profile = "kube-master"
  count = 2
}

variable "k8s-master-inventory" {
  description = "Ansible formatted inventory"
  default = "whatevs"
}

resource "aws_instance" "test-kubernetes-etcd" {
  ami  = "${var.ami}"
  instance_type = "t2.large"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.public-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.k8s-sg.id}"]
  associate_public_ip_address = true
  source_dest_check = false
  tags {
    Name = "test-kubernetes-etcd-${count.index}"
    kubespray-role = "etcd"
    role = "k8etc"
    env = "{var.environment}"
    "kubernetes.io/cluster/cluster.local"="owned"
    KubernetesCluster="cluster.local"
    inventory="test-kubernetes-etcd-${count.index} ansible_host=$${aws_instance.test-kubernetes-etcd.${count.index}.public_ip}"
  }
  root_block_device {
    volume_size = 30
  }
  count = 3
}


resource "aws_instance" "test-kubernetes-node" {
  ami  = "${var.ami}"
  instance_type = "t2.large"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.public-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.k8s-sg.id}"]
  associate_public_ip_address = true
  source_dest_check = false
  tags {
    Name = "test-kubernetes-node-${count.index}"
    kubespray-role = "kube-node"
    role = "k8node"
    env = "{var.environment}"
    "kubernetes.io/cluster/cluster.local"="owned"
    KubernetesCluster="cluster.local"
    inventory="test-kubernetes-node-${count.index} ansible_host=$${aws_instance.test-kubernetes-node.${count.index}.public_ip}"
  }
  root_block_device {
    volume_size = 30
  }
  iam_instance_profile = "kube-node"
  count = 3
  
}


resource "aws_instance" "test-kubernetes-ui" {
  ami  = "${var.ami}"
  instance_type = "t2.large"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.public-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.k8s-sg.id}"]
  associate_public_ip_address = true
  source_dest_check = false
  tags {
    Name = "test-kubernetes-ui-${count.index}"
    kubespray-role = "kube-master"
    role = "k8master"
    env = "{var.environment}"
    "kubernetes.io/cluster/cluster.local"="owned"
    KubernetesCluster="cluster.local"
    inventory="test-kubernetes-ui-${count.index} ansible_host=$${aws_instance.test-kubernetes-ui.${count.index}.public_ip}"
  }
  root_block_device {
    volume_size = 30
  }
  count = 1
  iam_instance_profile = "kube-master"
}

resource "aws_eip" "static" {
  instance = "${aws_instance.test-kubernetes-ui.id}"
  vpc      = true
}


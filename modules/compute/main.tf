# modules/compute/main.tf

# Eks Cluster Definition - managed node group
resource "aws_eks_cluster" "cluster" {
  name = var.cluster_name

  access_config {
    authentication_mode = "API"
  }
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version
  bootstrap_self_managed_addons = true
  # compute_config {
  #   enabled       = true
  #   node_pools    = ["general-purpose"]
  #   node_role_arn = aws_iam_role.node.arn
  # }
  kubernetes_network_config {
    elastic_load_balancing {
      enabled = false
    }
  }
  storage_config {
    block_storage {
      enabled = false
    }
  }
  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true

    subnet_ids = var.subnet_CP_ids
  }
  tags = merge(var.default_tags, {
    Name = var.cluster_name
  })
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSComputePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSBlockStoragePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSLoadBalancingPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSNetworkingPolicy,
  ]
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "node" {
  name = "${var.environment}-${var.cluster_name}-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Attach necessary policies to the EKS Node Role
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodeMinimalPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
  role       = aws_iam_role.node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryPullOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role       = aws_iam_role.node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "cluster" {
  name = "${var.environment}-${var.cluster_name}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

# Attach necessary policies to the EKS Cluster Role
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSComputePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
  role       = aws_iam_role.cluster.name
}
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSBlockStoragePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
  role       = aws_iam_role.cluster.name
}
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSLoadBalancingPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
  role       = aws_iam_role.cluster.name
}
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSNetworkingPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
  role       = aws_iam_role.cluster.name
}

# OIDC Provider for IAM Roles for Service Accounts (IRSA)
resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cluster_thumbprint.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  tags = var.default_tags
}

# Data source to get the EKS cluster's OIDC thumbprint
data "tls_certificate" "eks_cluster_thumbprint" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# EKS Addons for the cluster
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "vpc-cni"
  addon_version = "v1.19.6-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE" 
  tags = var.default_tags
}
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "kube-proxy"
  addon_version = "v1.33.0-eksbuild.2"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  tags = var.default_tags
}
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "coredns"
  addon_version = "v1.12.2-eksbuild.4"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  tags = var.default_tags
}

# CSI driver definition
# IAM Role for EBS CSI Driver Service Account
resource "aws_iam_role" "ebs_csi_driver" {
  name = "${var.environment}-${var.cluster_name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # This assumes your EKS cluster's OIDC provider is configured and available
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # The service account that the EBS CSI driver addon runs as
            "${replace(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })

  tags = var.default_tags
}
# AWS Managed Policy for EBS CSI Driver
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}
# Data source to get current AWS account ID (needed for ARN construction)
data "aws_caller_identity" "current" {}
# Data source to get compatible EBS CSI Driver addon version
data "aws_eks_addon_version" "ebs_csi_driver" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = aws_eks_cluster.cluster.version
}
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = aws_eks_cluster.cluster.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = data.aws_eks_addon_version.ebs_csi_driver.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  # This is crucial: link the addon to the IAM role for IRSA
  service_account_role_arn    = aws_iam_role.ebs_csi_driver.arn

  tags = var.default_tags

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_driver_policy,
    aws_iam_openid_connect_provider.main,
  ]
}

# IAM EKS Admin Access role for the cluster
resource "aws_eks_access_entry" "admin" {
  for_each     = toset(var.admin_iam_role_arns)
  cluster_name = aws_eks_cluster.cluster.name
  principal_arn = each.value
  type          = "STANDARD"

  tags = var.default_tags
}
resource "aws_eks_access_policy_association" "admin_policy" {
  for_each     = toset(var.admin_iam_role_arns)
  cluster_name = aws_eks_cluster.cluster.name
  principal_arn = aws_eks_access_entry.admin[each.key].principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# Security Group for EKS worker nodes
resource "aws_security_group" "eks_nodes" {
  name        = "${var.environment}-${var.cluster_name}-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  # Allow NGINX Ingress traffic (HTTP & HTTPS)
  ingress {
    description     = "Allow HTTP from reverse proxy"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.reverse_proxy.id]
  }

  ingress {
    description     = "Allow HTTPS from reverse proxy"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.reverse_proxy.id]
  }

  # Allow NodePort traffic (only if needed)
  ingress {
    description     = "Allow NodePort traffic from reverse proxy"
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.reverse_proxy.id]
  }

  ingress {
    description = "Allow node-to-node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.default_tags
}
# Launch Template for EKS worker nodes
resource "aws_launch_template" "eks_nodes_lt" {
  name_prefix   = "${var.environment}-${var.cluster_name}-lt"
  instance_type = "t3.medium"

  vpc_security_group_ids = [aws_security_group.eks_nodes.id]

  tag_specifications {
    resource_type = "instance"
    tags = var.default_tags
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "general_purpose" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "general-purpose"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_NG_ids

  launch_template {
    id      = aws_launch_template.eks_nodes_lt.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 5
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "kubernetes.io/cluster-autoscaler/enabled" : "true"
    "kubernetes.io/cluster-autoscaler/${var.cluster_name}" : "true"
    "node.kubernetes.io/lifecycle" : "on-demand"
  }

  tags = merge(var.default_tags, {
    Name                = "${var.environment}-${var.cluster_name}-general-purpose-ng"
    "eks:cluster-name"  = var.cluster_name
  })

  depends_on = [
    aws_eks_cluster.cluster,
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodeMinimalPolicy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryPullOnly,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_launch_template.eks_nodes_lt,
    aws_security_group.eks_nodes
  ]
}

# Security Group for Reverse Proxy
resource "aws_security_group" "reverse_proxy" {
  name        = "${var.environment}-reverse-proxy-sg"
  description = "Security group for public EC2 reverse proxy"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP/HTTPS from internet"
    from_port   = 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.default_tags
}

# Reverse Proxy EC2 Instance
resource "aws_instance" "reverse_proxy" {
  for_each = toset(var.subnet_proxy_ids) 

  ami                    = "ami-0437df53acb2bbbfd"
  instance_type          = "t3.micro"
  subnet_id              = each.value
  vpc_security_group_ids = [aws_security_group.reverse_proxy.id]
  key_name               = "home-lab-2"
  associate_public_ip_address = true

  tags = merge(var.default_tags, {
    Name = "${var.environment}-reverse-proxy-${each.key}"
  })

  lifecycle {
    create_before_destroy = true
  }
}




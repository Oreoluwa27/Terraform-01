# modules/compute/outputs.tf

output "eks_cluster_id" {
  description = "The name/ID of the EKS cluster."
  value       = aws_eks_cluster.cluster.id
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.cluster.name
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster."
  value       = aws_eks_cluster.cluster.arn
}

output "eks_cluster_endpoint" {
  description = "The Kubernetes API server endpoint of the EKS cluster."
  value       = aws_eks_cluster.cluster.endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster."
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}

output "eks_cluster_version" {
  description = "The Kubernetes version of the EKS cluster."
  value       = aws_eks_cluster.cluster.version
}

output "eks_cluster_oidc_issuer_url" {
  description = "The URL of the EKS cluster OIDC Issuer."
  value       = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

output "eks_cluster_oidc_issuer_arn" {
  description = "The ARN of the EKS cluster OIDC Issuer for IAM roles for service accounts."
  value       = aws_iam_openid_connect_provider.main.arn
}

output "cluster_vpc_id" {
  description = "The VPC ID where the EKS cluster is deployed."
  value       = var.vpc_id
}

output "eks_admin_access_entry_arn" {
  description = "The ARN of the created EKS admin access entry (if any)."
  value       = length(aws_eks_access_entry.admin) > 0 ? aws_eks_access_entry.admin[0].principal_arn : null
}
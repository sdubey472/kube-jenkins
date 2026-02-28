# EBS CSI Driver Addon
resource "aws_eks_addon" "ebs_csi" {
  count               = var.enable_ebs_csi ? 1 : 0
  cluster_name        = module.eks.cluster_name
  addon_name          = "aws-ebs-csi-driver"
  addon_version       = data.aws_eks_addon_version.ebs_csi.version
  service_account_role_arn = aws_iam_role.ebs_csi[0].arn

  tags = var.tags
}

data "aws_eks_addon_version" "ebs_csi" {
  addon_name           = "aws-ebs-csi-driver"
  kubernetes_version   = var.cluster_version
  most_recent          = true
}

# IAM role for EBS CSI driver
resource "aws_iam_role" "ebs_csi" {
  count              = var.enable_ebs_csi ? 1 : 0
  name               = "${var.cluster_name}-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "ebs_csi_assume_role" {
  count = var.enable_ebs_csi ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.eks.oidc_provider}"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count      = var.enable_ebs_csi ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi[0].name
}

# EFS CSI Driver Addon
resource "aws_eks_addon" "efs_csi" {
  count               = var.enable_efs_csi ? 1 : 0
  cluster_name        = module.eks.cluster_name
  addon_name          = "aws-efs-csi-driver"
  addon_version       = data.aws_eks_addon_version.efs_csi.version
  service_account_role_arn = aws_iam_role.efs_csi[0].arn

  tags = var.tags
}

data "aws_eks_addon_version" "efs_csi" {
  addon_name           = "aws-efs-csi-driver"
  kubernetes_version   = var.cluster_version
  most_recent          = true
}

# IAM role for EFS CSI driver
resource "aws_iam_role" "efs_csi" {
  count              = var.enable_efs_csi ? 1 : 0
  name               = "${var.cluster_name}-efs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.efs_csi_assume_role[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "efs_csi_assume_role" {
  count = var.enable_efs_csi ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.eks.oidc_provider}"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "efs_csi" {
  count      = var.enable_efs_csi ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.efs_csi[0].name
}

# CoreDNS addon
resource "aws_eks_addon" "coredns" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "coredns"
  addon_version            = data.aws_eks_addon_version.coredns.version
  resolve_conflicts_on_create = "OVERWRITE"

  tags = var.tags
}

data "aws_eks_addon_version" "coredns" {
  addon_name           = "coredns"
  kubernetes_version   = var.cluster_version
  most_recent          = true
}

# kube-proxy addon
resource "aws_eks_addon" "kube_proxy" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "kube-proxy"
  addon_version            = data.aws_eks_addon_version.kube_proxy.version
  resolve_conflicts_on_create = "OVERWRITE"

  tags = var.tags
}

data "aws_eks_addon_version" "kube_proxy" {
  addon_name           = "kube-proxy"
  kubernetes_version   = var.cluster_version
  most_recent          = true
}

# VPC CNI addon for networking
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "vpc-cni"
  addon_version            = data.aws_eks_addon_version.vpc_cni.version
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn = aws_iam_role.vpc_cni.arn

  tags = var.tags
}

data "aws_eks_addon_version" "vpc_cni" {
  addon_name           = "vpc-cni"
  kubernetes_version   = var.cluster_version
  most_recent          = true
}

# IAM role for VPC CNI
resource "aws_iam_role" "vpc_cni" {
  name               = "${var.cluster_name}-vpc-cni-role"
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "vpc_cni_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.eks.oidc_provider}"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni.name
}

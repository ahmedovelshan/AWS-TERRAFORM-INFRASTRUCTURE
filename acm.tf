resource "aws_s3_bucket" "aws_acm_s3" {
  bucket        = "aws-acm-s3-2024"
  force_destroy = true
}

data "aws_iam_policy_document" "acmpca_bucket_access" {
  statement {
    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = [
      aws_s3_bucket.aws_acm_s3.arn,
      "${aws_s3_bucket.aws_acm_s3.arn}/*",
    ]

    principals {
      identifiers = ["acm-pca.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.aws_acm_s3.id
  policy = data.aws_iam_policy_document.acmpca_bucket_access.json
}

resource "aws_acmpca_certificate_authority" "rootca" {
  usage_mode = "SHORT_LIVED_CERTIFICATE"
  type = "ROOT"
  certificate_authority_configuration {
    key_algorithm     = "RSA_4096"
    signing_algorithm = "SHA512WITHRSA"

    subject {
      common_name = "testmmc.net"
      country = "AZ"
    }
  }

  revocation_configuration {
    crl_configuration {
      custom_cname       = "crl.testmmc.net"
      enabled            = true
      expiration_in_days = 7
      s3_bucket_name     = aws_s3_bucket.aws_acm_s3.id
      s3_object_acl      = "BUCKET_OWNER_FULL_CONTROL"
    }
  }

  depends_on = [aws_s3_bucket_policy.s3_policy]
}

resource "aws_acmpca_certificate" "rootca_certificate" {
  certificate_authority_arn   = aws_acmpca_certificate_authority.rootca.arn
  certificate_signing_request = aws_acmpca_certificate_authority.rootca.certificate_signing_request
  signing_algorithm           = "SHA512WITHRSA"

  template_arn = "arn:${data.aws_partition.current.partition}:acm-pca:::template/RootCACertificate/V1"

  validity {
    type  = "YEARS"
    value = 3
  }
}

resource "aws_acmpca_certificate_authority_certificate" "rootca_certificate_assing" {
  certificate_authority_arn = aws_acmpca_certificate_authority.rootca.arn

  certificate       = aws_acmpca_certificate.rootca_certificate.certificate
  certificate_chain = aws_acmpca_certificate.rootca_certificate.certificate_chain
}


resource "aws_acmpca_certificate_authority" "subca" {
  type = "SUBORDINATE"
  usage_mode = "SHORT_LIVED_CERTIFICATE"
  certificate_authority_configuration {
    key_algorithm     = "RSA_2048"
    signing_algorithm = "SHA512WITHRSA"

    subject {
      common_name = "subca.testmmc.net"
    }
  }
  revocation_configuration {
    crl_configuration {
      custom_cname       = "crl.subca.testmmc.net"
      enabled            = true
      expiration_in_days = 7
      s3_bucket_name     = aws_s3_bucket.aws_acm_s3.id
      s3_object_acl      = "BUCKET_OWNER_FULL_CONTROL"
    }
  }
}

resource "aws_acmpca_certificate" "subca_certificate" {
  certificate_authority_arn   = aws_acmpca_certificate_authority.rootca.arn
  certificate_signing_request = aws_acmpca_certificate_authority.subca.certificate_signing_request
  signing_algorithm           = "SHA512WITHRSA"

  template_arn = "arn:${data.aws_partition.current.partition}:acm-pca:::template/SubordinateCACertificate_PathLen0/V1"

  validity {
    type  = "DAYS"
    value = 7
  }
}


resource "aws_acmpca_certificate_authority_certificate" "subordinate" {
  certificate_authority_arn = aws_acmpca_certificate_authority.subca.arn

  certificate       = aws_acmpca_certificate.subca_certificate.certificate
  certificate_chain = aws_acmpca_certificate.subca_certificate.certificate_chain
}


data "aws_partition" "current" {}

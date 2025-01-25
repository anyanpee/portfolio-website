# Portfolio Website Deployment with GitHub Actions and Terraform

## Overview
This project automates the deployment of a portfolio website to AWS S3 using **Terraform** and **GitHub Actions**. The setup ensures a smooth CI/CD pipeline and secure, highly available infrastructure for hosting static websites.

---

## Project Structure
```
project-root/
|— .github/
|   — workflows/
|       — ci.yml  # GitHub Actions workflow file
|— terraform/
|   — main.tf         # Terraform configuration
|— portfolio/
    — index.html      # Website files
```

---

## Features
- **Terraform** for Infrastructure as Code (IaC): Automates the setup of AWS resources.
- **GitHub Actions**: Automates the deployment process upon changes to the `main` branch.
- **AWS S3**: Hosts the static portfolio website with public access and HTTPS support.
- **Encryption**: Ensures data security with server-side encryption.

---

## Deployment Workflow
1. **Trigger**: The workflow starts when you push changes to the `main` branch.
2. **Setup**:
    - Terraform initializes the infrastructure.
    - AWS credentials are securely configured via GitHub secrets.
3. **Validation**: Terraform validates and plans the infrastructure changes.
4. **Deployment**: Terraform applies the configuration to deploy the portfolio website.

---

## GitHub Actions Workflow
**File:** `.github/workflows/ci.yml`
```yaml
name: Deploy Portfolio Website

on:
  push:
    branches:
      - main

jobs:
  terraform:
    name: Deploy Portfolio Website
    runs-on: ubuntu-latest
    env:
      working-directory: terraform
    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v3
          
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-region: "eu-west-1"
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Initialize Terraform
        run: terraform init
        working-directory: ${{ env.working-directory }}

      - name: Terraform Validate
        run: terraform validate
        working-directory: ${{ env.working-directory }}

      - name: Terraform Plan
        run: terraform plan
        working-directory: ${{ env.working-directory }}

      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: ${{ env.working-directory }}
```

---

## Terraform Configuration
**File:** `terraform/main.tf`
```hcl
resource "aws_s3_bucket" "bucket" {
  bucket        = var.project_prefix
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "portfolio" {
  bucket = aws_s3_bucket.bucket.id
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "permissions" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

locals {
  mime_types = {
    "html" = "text/html"
    "css"  = "text/css"
    "svg"  = "image/svg+xml"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "jpeg" = "image/jpeg"
  }
}

resource "aws_s3_object" "upload_object" {
  for_each = fileset("../portfolio/", "**")
  bucket   = aws_s3_bucket.bucket.id
  key      = each.value
  etag     = filemd5("../portfolio/${each.value}")
  source   = "../portfolio/${each.value}"
  content_type = lookup(
    local.mime_types,
    split(".", each.value)[1],
    ""
  )
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicReadGetObject",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : [
          "s3:GetObject"
        ],
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.bucket.id}/*"
        ]
      }
    ]
  })
}

output "s3_website_endpoint" {
  value = aws_s3_bucket.bucket.website_endpoint
}
```

---

## How to Use

### Prerequisites
- **AWS Account**: Ensure you have an AWS account and the necessary IAM permissions.
- **GitHub Repository**: Store your project files in a GitHub repository.
- **Terraform Installed**: Install Terraform locally if needed for manual testing.
- **GitHub Secrets**:
  - `AWS_ACCESS_KEY_ID`: Your AWS access key.
  - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key.

### Steps
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd project-root
   ```
2. Push changes to the `main` branch.
3. Monitor the GitHub Actions workflow for deployment logs.
4. Access the deployed portfolio website using the `s3_website_endpoint` output.

---

## Outputs
- **S3 Website Endpoint**: URL to access the hosted portfolio website, e.g., `http://<bucket-name>.s3-website-<region>.amazonaws.com`.

---

## Notes
- **Costs**: Ensure you monitor AWS usage to avoid unexpected charges.
- **Security**: Use environment variables and IAM roles to enhance security.
- **Customization**: Modify the `portfolio/` folder to update your website content.

---

## Contributing
Feel free to fork the repository and submit a pull request for improvements or new features.


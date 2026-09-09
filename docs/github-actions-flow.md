# GitHub Actions Flow

## pull-request workflow

1. Checkout code
2. Set up Terraform
3. Authenticate to Azure via OIDC
4. Run `terraform fmt -check -recursive`
5. Run `terraform init -backend=false`
6. Run `terraform validate`
7. Run `terraform plan`

## deploy workflow

1. Checkout code
2. Set up Terraform
3. Authenticate to Azure via OIDC
4. Run `terraform init`
5. Run `terraform validate`
6. Run `terraform plan -out=tfplan`
7. Run `terraform apply -auto-approve tfplan`

## Azure federation

The recommended pattern is to configure Azure federated credentials for the GitHub repository and branch. This avoids long-lived Azure client secrets and supports short-lived tokens per workflow run.

# Versões do Terraform e do provider do GitHub.
terraform {
  required_version = ">= 1.7" # 1.7+ por causa do mock_provider usado nos testes

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

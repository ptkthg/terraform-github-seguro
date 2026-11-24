# O token vem exclusivamente de GITHUB_TOKEN e nunca deve ser gravado em arquivo.
provider "github" {
  owner = var.github_owner
}

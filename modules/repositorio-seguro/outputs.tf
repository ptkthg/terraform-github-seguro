output "nome" {
  description = "Nome do repositório criado."
  value       = github_repository.this.name
}

output "url_html" {
  description = "URL do repositório no GitHub."
  value       = github_repository.this.html_url
}

output "ruleset_id" {
  description = "Identificador numérico do ruleset da branch padrão no GitHub."
  value       = github_repository_ruleset.branch_padrao.ruleset_id
}

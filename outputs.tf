output "urls" {
  description = "Mapa do nome de cada repositório para sua URL no GitHub."
  value       = { for k, m in module.repositorio : k => m.url_html }
}

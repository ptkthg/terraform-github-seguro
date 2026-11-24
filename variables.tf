variable "github_owner" {
  description = "Usuário ou organização do GitHub que receberá os repositórios."
  type        = string
}

variable "repositorios" {
  description = "Repositórios por nome; atributos omitidos herdam os padrões de segurança."
  type = map(object({
    descricao                = optional(string, "")
    visibilidade             = optional(string, "public")
    aprovacoes_obrigatorias  = optional(number, 0)
    exigir_commits_assinados = optional(bool, false)
    topicos                  = optional(list(string), [])
  }))
  default = {}
}

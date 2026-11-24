variable "nome" {
  description = "Nome do repositório: de 2 a 100 caracteres, minúsculas, números e hífens internos."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,98}[a-z0-9]$", var.nome))
    error_message = "O nome deve seguir ^[a-z0-9][a-z0-9-]{0,98}[a-z0-9]$."
  }
}

variable "descricao" {
  description = "Descrição pública do propósito do repositório, com até 350 caracteres."
  type        = string
  default     = ""
  validation {
    condition     = length(var.descricao) <= 350
    error_message = "A descrição deve ter até 350 caracteres."
  }
}

variable "visibilidade" {
  description = "Visibilidade do repositório: public ou private."
  type        = string
  default     = "public"
  validation {
    condition     = contains(["public", "private"], var.visibilidade)
    error_message = "A visibilidade deve ser public ou private."
  }
}

variable "aprovacoes_obrigatorias" {
  description = "Número de aprovações (inteiro de 0 a 6). O padrão 0 evita bloquear o dono em conta pessoal com um único desenvolvedor; o pull request continua obrigatório."
  type        = number
  default     = 0
  validation {
    condition = (
      var.aprovacoes_obrigatorias >= 0 && var.aprovacoes_obrigatorias <= 6 &&
      floor(var.aprovacoes_obrigatorias) == var.aprovacoes_obrigatorias
    )
    error_message = "As aprovações obrigatórias devem ser um inteiro de 0 a 6."
  }
}

variable "exigir_commits_assinados" {
  description = "Exige assinaturas verificadas nos commits da branch padrão."
  type        = bool
  default     = false
}

variable "topicos" {
  description = "Tópicos para descoberta do repositório, com até 50 caracteres cada."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for topico in var.topicos : can(regex("^[a-z0-9][a-z0-9-]{0,49}$", topico))])
    error_message = "Cada tópico deve seguir ^[a-z0-9][a-z0-9-]{0,49}$."
  }
}

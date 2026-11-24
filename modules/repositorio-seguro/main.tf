terraform {
  required_version = ">= 1.7"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

resource "github_repository" "this" {
  # Exceção registrada: público é decisão do projeto, não descuido. Em conta gratuita,
  # só repositórios públicos têm secret scanning, push protection e ruleset; privado continua disponível pela variável.
  #checkov:skip=CKV_GIT_1:Visibilidade pública intencional (variável visibilidade); privado em conta gratuita perde secret scanning e ruleset.
  name        = var.nome
  description = var.descricao
  visibility  = var.visibilidade
  topics      = var.topicos

  # A branch precisa existir para receber a política e as proteções iniciais.
  auto_init = true

  # Menos superfícies paralelas para conteúdo sem revisão; issues mantêm a triagem.
  has_wiki     = false
  has_projects = false
  has_issues   = true

  # Squash e limpeza de branches simplificam a auditoria e reduzem branches esquecidas.
  allow_merge_commit     = false
  allow_rebase_merge     = false
  allow_squash_merge     = true
  delete_branch_on_merge = true

  # Arquivar evita perda irreversível, como preservar evidência imutável no DFIR.
  archive_on_destroy = true

  # Detectar segredos e bloquear seu push reduz vazamentos; privados gratuitos não têm essa licença.
  dynamic "security_and_analysis" {
    for_each = var.visibilidade == "public" ? [1] : []
    content {
      secret_scanning {
        status = "enabled"
      }
      secret_scanning_push_protection {
        status = "enabled"
      }
    }
  }
}

# Alertas reduzem o tempo até a identificação de dependências vulneráveis.
# (Resource próprio: o atributo vulnerability_alerts do github_repository está obsoleto no provider 6.x.)
resource "github_repository_vulnerability_alerts" "this" {
  repository = github_repository.this.name
  enabled    = true
}

# Correções automáticas reduzem a janela de exposição de dependências vulneráveis.
# Dependem dos alertas: o GitHub só abre PRs de correção quando os alertas estão ligados.
resource "github_repository_dependabot_security_updates" "this" {
  repository = github_repository.this.name
  enabled    = true

  depends_on = [github_repository_vulnerability_alerts.this]
}

# Orientação de reporte privado evita divulgar uma vulnerabilidade antes da correção.
resource "github_repository_file" "security_md" {
  repository          = github_repository.this.name
  file                = "SECURITY.md"
  overwrite_on_create = true
  commit_message      = "docs: adiciona política de reporte privado de vulnerabilidades"
  # Sem branch explícita, o provider usa a branch padrão do repositório.
  content = <<-EOT
    # Política de segurança

    Para reportar uma vulnerabilidade, abra a aba Security do repositório e
    use "Report a vulnerability" para enviar os detalhes de forma privada.
    Inclua impacto, passos para reprodução e possíveis mitigações.
    Não publique vulnerabilidades, credenciais ou dados sensíveis em issues.

    Se o botão não estiver disponível, aguarde o mantenedor habilitar o
    reporte privado antes de compartilhar detalhes sensíveis.
  EOT
}

# Sem bypass: inclusive administradores seguem o fluxo revisável da branch padrão.
resource "github_repository_ruleset" "branch_padrao" {
  name        = "protecao-branch-padrao"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  # A política inicial deve entrar antes do bloqueio a commits diretos.
  depends_on = [github_repository_file.security_md]

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }
  rules {
    # Impede apagar a branch ou reescrever o histórico e eliminar rastros.
    deletion         = true
    non_fast_forward = true

    # Histórico linear facilita rastrear mudanças; assinaturas opcionais reduzem falsificação de autoria.
    required_linear_history = true
    required_signatures     = var.exigir_commits_assinados

    # PR obrigatório dá rastreabilidade; novas mudanças invalidam aprovações antigas.
    pull_request {
      required_approving_review_count = var.aprovacoes_obrigatorias
      dismiss_stale_reviews_on_push   = true
      # Evita incorporar mudanças com discussões de revisão ainda pendentes.
      required_review_thread_resolution = true
    }
  }
}

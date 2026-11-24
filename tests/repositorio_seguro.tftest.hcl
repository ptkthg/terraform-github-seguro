mock_provider "github" {}

variables {
  nome = "repositorio-teste"
}

run "publico_com_padroes_seguros" {
  command = plan
  module {
    source = "./modules/repositorio-seguro"
  }

  assert {
    condition = (
      github_repository.this.security_and_analysis[0].secret_scanning[0].status == "enabled" &&
      github_repository.this.security_and_analysis[0].secret_scanning_push_protection[0].status == "enabled"
    )
    error_message = "O repositório público deve detectar e bloquear segredos."
  }
  assert {
    condition = (
      github_repository.this.archive_on_destroy && github_repository_vulnerability_alerts.this.enabled &&
      github_repository.this.auto_init && !github_repository.this.has_wiki &&
      !github_repository.this.has_projects && github_repository.this.has_issues &&
      !github_repository.this.allow_merge_commit && !github_repository.this.allow_rebase_merge &&
      github_repository.this.allow_squash_merge && github_repository.this.delete_branch_on_merge
    )
    error_message = "Os padrões de preservação, alertas e superfície mínima devem estar ativos."
  }
  assert {
    condition = (
      github_repository_ruleset.branch_padrao.enforcement == "active" &&
      github_repository_ruleset.branch_padrao.target == "branch" &&
      github_repository_ruleset.branch_padrao.conditions[0].ref_name[0].include == tolist(["~DEFAULT_BRANCH"]) &&
      length(github_repository_ruleset.branch_padrao.conditions[0].ref_name[0].exclude) == 0 &&
      length(github_repository_ruleset.branch_padrao.bypass_actors) == 0 &&
      github_repository_ruleset.branch_padrao.rules[0].deletion &&
      github_repository_ruleset.branch_padrao.rules[0].non_fast_forward &&
      github_repository_ruleset.branch_padrao.rules[0].required_linear_history &&
      !github_repository_ruleset.branch_padrao.rules[0].required_signatures &&
      github_repository_ruleset.branch_padrao.rules[0].pull_request[0].required_approving_review_count == 0 &&
      github_repository_ruleset.branch_padrao.rules[0].pull_request[0].dismiss_stale_reviews_on_push &&
      github_repository_ruleset.branch_padrao.rules[0].pull_request[0].required_review_thread_resolution
    )
    error_message = "A branch padrão deve exigir PR, preservar o histórico e não admitir bypass."
  }
  assert {
    condition     = github_repository_dependabot_security_updates.this.enabled
    error_message = "O Dependabot deve propor correções de segurança."
  }
  assert {
    condition = (
      github_repository_file.security_md.file == "SECURITY.md" &&
      github_repository_file.security_md.overwrite_on_create &&
      strcontains(github_repository_file.security_md.content, "Report a vulnerability") &&
      output.nome == var.nome
    )
    error_message = "Deve existir uma política de divulgação privada e a saída nome deve identificar o repositório."
  }
}

run "privado_sem_recursos_pagos" {
  command = plan
  module {
    source = "./modules/repositorio-seguro"
  }
  variables {
    visibilidade = "private"
  }
  assert {
    condition     = length(github_repository.this.security_and_analysis) == 0
    error_message = "O privado não deve configurar recursos que exigem licença paga."
  }
  assert {
    condition = (
      github_repository.this.visibility == "private" &&
      github_repository.this.archive_on_destroy && github_repository_vulnerability_alerts.this.enabled &&
      !github_repository.this.has_wiki && !github_repository.this.has_projects &&
      github_repository.this.has_issues && github_repository.this.auto_init &&
      !github_repository.this.allow_merge_commit && !github_repository.this.allow_rebase_merge &&
      github_repository.this.allow_squash_merge && github_repository.this.delete_branch_on_merge &&
      github_repository_ruleset.branch_padrao.enforcement == "active" &&
      github_repository_ruleset.branch_padrao.rules[0].deletion &&
      github_repository_ruleset.branch_padrao.rules[0].non_fast_forward &&
      github_repository_ruleset.branch_padrao.rules[0].required_linear_history &&
      github_repository_ruleset.branch_padrao.rules[0].pull_request[0].required_approving_review_count == 0 &&
      github_repository_dependabot_security_updates.this.enabled
    )
    error_message = "O privado deve manter as demais proteções."
  }
}

run "parametros_personalizados" {
  command = plan
  module {
    source = "./modules/repositorio-seguro"
  }
  variables {
    descricao                = "Laboratório de segurança"
    aprovacoes_obrigatorias  = 6
    exigir_commits_assinados = true
    topicos                  = ["security", "terraform"]
  }
  assert {
    condition = (
      github_repository.this.description == var.descricao &&
      github_repository.this.topics == toset(var.topicos) &&
      github_repository_ruleset.branch_padrao.rules[0].required_signatures &&
      github_repository_ruleset.branch_padrao.rules[0].pull_request[0].required_approving_review_count == 6
    )
    error_message = "As entradas personalizadas devem chegar aos resources."
  }
}

run "nome_invalido" {
  command = plan
  module {
    source = "./modules/repositorio-seguro"
  }
  variables {
    nome = "Repo_Invalido"
  }
  expect_failures = [var.nome]
}

run "aprovacoes_fora_da_faixa" {
  command = plan
  module {
    source = "./modules/repositorio-seguro"
  }
  variables {
    aprovacoes_obrigatorias = 7
  }
  expect_failures = [var.aprovacoes_obrigatorias]
}

run "aprovacoes_fracionarias" {
  command = plan
  module {
    source = "./modules/repositorio-seguro"
  }
  variables {
    aprovacoes_obrigatorias = 1.5
  }
  expect_failures = [var.aprovacoes_obrigatorias]
}

run "descricao_longa" {
  command = plan
  module {
    source = "./modules/repositorio-seguro"
  }
  variables {
    descricao = join("", [for i in range(351) : "a"])
  }
  expect_failures = [var.descricao]
}

run "visibilidade_invalida" {
  command = plan
  module {
    source = "./modules/repositorio-seguro"
  }
  variables {
    visibilidade = "internal"
  }
  expect_failures = [var.visibilidade]
}

run "topico_invalido" {
  command = plan
  module {
    source = "./modules/repositorio-seguro"
  }
  variables {
    topicos = ["Topico_Invalido"]
  }
  expect_failures = [var.topicos]
}

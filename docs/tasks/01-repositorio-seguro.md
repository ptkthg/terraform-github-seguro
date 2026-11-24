# Spec 01: módulo de repositório seguro no GitHub

**Implementador:** Codex. **Revisor:** Claude.
**Leia antes:** `AGENTS.md`. O `versions.tf` e o `.gitignore` já existem. O provider `integrations/github` v6.13.0 já foi baixado com `terraform init`. Use `terraform providers schema -json` para conferir os nomes exatos de atributos e blocos, em vez de confiar na memória.
**Não toque em** `versions.tf` (só se a versão do provider impedir algo; nesse caso, explique no resultado).

## Objetivo
Um módulo `repositorio-seguro` que cria um repositório do GitHub já com as proteções que um time de segurança exigiria. A raiz usa o módulo com `for_each` para criar vários repositórios a partir de um mapa. É o primeiro projeto do portfólio de um analista de DFIR migrando para security engineering, então o README explica cada decisão de segurança.

## Arquivos
```
modules/repositorio-seguro/
  main.tf          # resources
  variables.tf     # entradas com validações
  outputs.tf
  README.md        # tabela de entradas e saídas (curta)
providers.tf       # provider "github" { owner = var.github_owner } (token só via GITHUB_TOKEN)
variables.tf       # github_owner, repositorios
main.tf            # module "repositorio" { for_each = var.repositorios ... }
outputs.tf         # mapa nome -> URL
terraform.tfvars.example
.tflint.hcl
tests/repositorio_seguro.tftest.hcl
tests/raiz.tftest.hcl
.github/workflows/terraform.yml
README.md
docs/tasks/01-resultado.md
```

## Módulo `repositorio-seguro`

### Entradas (`variables.tf`)
| Variável | Tipo | Padrão | Validação |
|---|---|---|---|
| `nome` | string | obrigatória | `^[a-z0-9][a-z0-9-]{0,98}[a-z0-9]$` |
| `descricao` | string | `""` | até 350 caracteres |
| `visibilidade` | string | `"public"` | `public` ou `private` |
| `aprovacoes_obrigatorias` | number | `0` | inteiro de 0 a 6 |
| `exigir_commits_assinados` | bool | `false` | |
| `topicos` | list(string) | `[]` | cada tópico: `^[a-z0-9][a-z0-9-]{0,49}$` |

A descrição da variável `aprovacoes_obrigatorias` explica que o padrão é 0 porque, numa conta pessoal com um único desenvolvedor, exigir aprovação bloquearia o próprio dono. O pull request continua obrigatório.

### Resources (`main.tf`)
1. **`github_repository.this`**
   - `name`, `description`, `visibility`, `topics` vindos das variáveis.
   - `auto_init = true` (a branch padrão precisa existir para o ruleset e os arquivos).
   - `has_wiki = false`, `has_projects = false`, `has_issues = true`.
   - `allow_merge_commit = false`, `allow_rebase_merge = false`, `allow_squash_merge = true`, `delete_branch_on_merge = true`.
   - `vulnerability_alerts = true`.
   - **`archive_on_destroy = true`**: um `terraform destroy` arquiva em vez de apagar. Comente o porquê (proteção contra perda irreversível, que é a mesma lógica da evidência imutável no DFIR).
   - `security_and_analysis` com `secret_scanning` e `secret_scanning_push_protection` habilitados **somente quando `visibilidade == "public"`** (use bloco `dynamic`). Em repositório privado de conta gratuita esses recursos exigem GitHub Advanced Security, e o apply falharia.
2. **`github_repository_dependabot_security_updates.this`**: `enabled = true`.
3. **`github_repository_ruleset.branch_padrao`**
   - `target = "branch"`, `enforcement = "active"`, condição `ref_name.include = ["~DEFAULT_BRANCH"]`, `exclude = []`.
   - Regras: `deletion = true`, `non_fast_forward = true`, `required_linear_history = true`, `required_signatures = var.exigir_commits_assinados`.
   - `pull_request`: `required_approving_review_count = var.aprovacoes_obrigatorias`, `dismiss_stale_reviews_on_push = true`, `required_review_thread_resolution = true`.
   - Sem `bypass_actors`.
4. **`github_repository_file.security_md`**: cria `SECURITY.md` na branch padrão com um texto curto em português (como reportar vulnerabilidade de forma privada pelo recurso "Report a vulnerability" do GitHub). `overwrite_on_create = true`, `commit_message` descritiva.

Cada bloco de segurança tem um comentário de uma ou duas linhas dizendo **qual risco reduz**. Por exemplo: `non_fast_forward` impede reescrever o histórico e apagar rastros.

### Saídas (`outputs.tf`)
`nome`, `url_html` (`html_url`), `ruleset_id`.

## Raiz
- `providers.tf`: `provider "github" { owner = var.github_owner }`, com um comentário dizendo que o token vem de `GITHUB_TOKEN` e nunca vai para arquivo.
- `variables.tf`:
  - `github_owner` (string, obrigatória);
  - `repositorios`: `map(object({ descricao = optional(string, ""), visibilidade = optional(string, "public"), aprovacoes_obrigatorias = optional(number, 0), exigir_commits_assinados = optional(bool, false), topicos = optional(list(string), []) }))`, padrão `{}`.
- `main.tf`: `module "repositorio"` com `for_each = var.repositorios` e `nome = each.key`.
- `outputs.tf`: `urls = { for k, m in module.repositorio : k => m.url_html }`.
- `terraform.tfvars.example`: `github_owner = "seu-usuario"` e dois repositórios de exemplo (um `public`, um `private`).

## Testes (`terraform test` com `mock_provider "github" {}`, `command = plan`)
`tests/repositorio_seguro.tftest.hcl`, usando `module { source = "./modules/repositorio-seguro" }`:
1. **Padrões seguros**, com um repositório público: push protection e secret scanning `enabled`, `archive_on_destroy`, `vulnerability_alerts`, `has_wiki == false`, `allow_merge_commit == false`, ruleset com `deletion`, `non_fast_forward` e `enforcement == "active"`, dependabot `enabled`.
2. **Privado**: `security_and_analysis` vazio (sem push protection), o resto igual.
3. **Nome inválido** (`"Repo_Invalido"`): `expect_failures = [var.nome]`.
4. **Aprovações fora da faixa** (`7`): `expect_failures = [var.aprovacoes_obrigatorias]`.

`tests/raiz.tftest.hcl`: com dois repositórios no mapa, o plano cria duas instâncias do módulo (por exemplo, `length(module.repositorio) == 2`), e o privado herda os padrões dos `optional`.

## Lint e CI
- `.tflint.hcl`: `plugin "terraform" { enabled = true, preset = "recommended" }`. Ele já vem embutido no tflint e não precisa de download.
- `.github/workflows/terraform.yml`: roda em `pull_request` e `push` na `main`, com `permissions: contents: read`. Jobs:
  - `terraform fmt -check -recursive`, `init -backend=false`, `validate` e `test` (`hashicorp/setup-terraform`);
  - `tflint --recursive` (`terraform-linters/setup-tflint`);
  - Checkov (`bridgecrewio/checkov-action`, `framework: terraform`).
  Fixe as actions por versão. Se não for possível fixar por SHA de commit sem acesso à rede, use a tag de versão e registre como limitação no resultado. **Sem apply no CI.**

## README.md (raiz)
Em português, voltado a recrutador e a quem estuda:
1. O que o projeto faz, em um parágrafo.
2. **Tabela "Decisão → risco que reduz"**, cobrindo todas as configurações de segurança.
3. **Como rodar**:
   - criar um *fine-grained personal access token* com acesso a "All repositories" e as permissões **Administration: Read and write** e **Contents: Read and write** (Metadata: Read entra automaticamente), com validade curta;
   - `$env:GITHUB_TOKEN = "..."` no PowerShell, nunca em arquivo;
   - copiar `terraform.tfvars.example` para `terraform.tfvars`;
   - `terraform init`, `terraform test`, `terraform plan` e `terraform apply`.
4. **Exercícios**, cada um com o que observar:
   1. `terraform test`, sem token;
   2. `plan` e `apply` de **um** repositório de teste;
   3. drift: ligar a wiki pela interface do GitHub e ver o `plan` querer desligar;
   4. adicionar um segundo repositório ao mapa e ver o `plan` mostrar só ele;
   5. importar um repositório que já existe com um bloco `import { to = ..., id = ... }` e `terraform plan -generate-config-out=` (explique que isso não muda nada até o apply);
   6. `destroy`: o repositório é **arquivado**, não apagado. Mostre como desarquivar ou apagar pela interface, se for o caso.
5. **Limitações**: repositório privado em conta gratuita (sem secret scanning e, dependendo do plano, sem ruleset); state local (o próximo passo é um backend remoto); o CI não aplica.

## Critérios de aceite
- Todos os comandos da regra 4 do `AGENTS.md` passam, com a saída registrada em `docs/tasks/01-resultado.md`.
- Nenhum token ou dado pessoal nos arquivos.
- Nenhum `apply`, `destroy` ou `import` foi executado.

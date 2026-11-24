# Resultado da spec 01 — repositório seguro

Implementação realizada em 24/11/2026, em português do Brasil.

## Implementação

- Módulo `modules/repositorio-seguro`: quatro resources, entradas validadas,
  saídas `nome`, `url_html` e `ruleset_id`, comentários sobre os riscos reduzidos.
- Raiz com provider autenticado exclusivamente por `GITHUB_TOKEN`, mapa tipado
  com atributos `optional`, `for_each`, mapa de URLs e exemplo público/privado.
- Testes com `mock_provider "github" {}` e exclusivamente `command = plan`:
  10 cenários, incluindo público, privado, parâmetros personalizados, validações
  inválidas e duas instâncias da raiz com padrões herdados.
- TFLint com plugin embutido e preset recommended.
- CI com Terraform, TFLint e Checkov, em PRs e pushes na main, `contents: read`,
  sem credenciais de aplicação, com todas as actions fixadas por SHA de commit.
- README da raiz com tabela de decisões e riscos, uso em PowerShell,
  seis exercícios e limitações; README curto do módulo com entradas e saídas.

## Execução e evidências

Ferramentas: Terraform 1.9.8, TFLint 0.54.0, provider integrations/github 6.13.0.
O schema foi consultado com `terraform providers schema -json` antes da
implementação, incluindo repository, ruleset, repository_file e Dependabot.
Os executáveis não estavam no PATH: foram baixados das distribuições oficiais
para `.terraform/tools` (ignorado pelo Git) e adicionados apenas ao PATH do
processo de validação. O download usou Node HTTPS após falha de credenciais TLS
no PowerShell/curl do ambiente. Não foram alteradas instalações globais.

Os testes foram escritos antes da implementação; a execução inicial falhou
porque o módulo ainda não estava instalado/declarado (inclusive provider type
mismatch decorrente da ausência do módulo). Depois da implementação e init,
os 10 cenários passaram. Essa falha inicial foi estrutural, não uma asserção
funcional de regressão.

As cinco verificações finais abaixo retornaram código **0**. As saídas foram
capturadas com `-no-color` nos comandos Terraform, apenas para legibilidade.
`TF_IN_AUTOMATION=true` removeu as instruções interativas do init.

### terraform fmt -check -recursive

Código de saída: 0.

```text
(sem saída; comando concluído com sucesso)
```

### terraform init -backend=false

Código de saída: 0.

```text
Initializing modules...
Initializing provider plugins...
- Reusing previous version of integrations/github from the dependency lock file
- Using previously-installed integrations/github v6.13.0

Terraform has been successfully initialized!
```

### terraform validate

Código de saída: 0.

```text

Warning: Argument is deprecated

  with module.repositorio.github_repository.this,
  on modules\repositorio-seguro\main.tf line 32, in resource "github_repository" "this":
  32:   vulnerability_alerts = true

Use the github_repository_vulnerability_alerts resource instead. This field
will be removed in a future version.

(and one more similar warning elsewhere)
Success! The configuration is valid, but there were some validation warnings
as shown above.
```

### terraform test

Código de saída: 0.

```text
tests\raiz.tftest.hcl... in progress
  run "dois_repositorios"... pass

Warning: Argument is deprecated

  with module.repositorio.github_repository.this,
  on modules\repositorio-seguro\main.tf line 32, in resource "github_repository" "this":
  32:   vulnerability_alerts = true

Use the github_repository_vulnerability_alerts resource instead. This field
will be removed in a future version.

(and 2 more similar warnings elsewhere)

tests\raiz.tftest.hcl... tearing down
tests\raiz.tftest.hcl... pass
tests\repositorio_seguro.tftest.hcl... in progress
  run "publico_com_padroes_seguros"... pass

Warning: Deprecated attribute

  on tests\repositorio_seguro.tftest.hcl line 22, in run "publico_com_padroes_seguros":
  22:       github_repository.this.archive_on_destroy && github_repository.this.vulnerability_alerts &&

The attribute "vulnerability_alerts" is deprecated. Refer to the provider
documentation for details.

Warning: Argument is deprecated

  with github_repository.this,
  on modules\repositorio-seguro\main.tf line 32, in resource "github_repository" "this":
  32:   vulnerability_alerts = true

Use the github_repository_vulnerability_alerts resource instead. This field
will be removed in a future version.

(and one more similar warning elsewhere)

  run "privado_sem_recursos_pagos"... pass

Warning: Deprecated attribute

  on tests\repositorio_seguro.tftest.hcl line 77, in run "privado_sem_recursos_pagos":
  77:       github_repository.this.archive_on_destroy && github_repository.this.vulnerability_alerts &&

The attribute "vulnerability_alerts" is deprecated. Refer to the provider
documentation for details.

Warning: Argument is deprecated

  with github_repository.this,
  on modules\repositorio-seguro\main.tf line 32, in resource "github_repository" "this":
  32:   vulnerability_alerts = true

Use the github_repository_vulnerability_alerts resource instead. This field
will be removed in a future version.

(and one more similar warning elsewhere)

  run "parametros_personalizados"... pass

Warning: Argument is deprecated

  with github_repository.this,
  on modules\repositorio-seguro\main.tf line 32, in resource "github_repository" "this":
  32:   vulnerability_alerts = true

Use the github_repository_vulnerability_alerts resource instead. This field
will be removed in a future version.

(and one more similar warning elsewhere)

  run "nome_invalido"... pass

Warning: Argument is deprecated

  with github_repository.this,
  on modules\repositorio-seguro\main.tf line 32, in resource "github_repository" "this":
  32:   vulnerability_alerts = true

Use the github_repository_vulnerability_alerts resource instead. This field
will be removed in a future version.

  run "aprovacoes_fora_da_faixa"... pass

Warning: Argument is deprecated

  with github_repository.this,
  on modules\repositorio-seguro\main.tf line 32, in resource "github_repository" "this":
  32:   vulnerability_alerts = true

Use the github_repository_vulnerability_alerts resource instead. This field
will be removed in a future version.

(and one more similar warning elsewhere)

  run "aprovacoes_fracionarias"... pass

Warning: Argument is deprecated

  with github_repository.this,
  on modules\repositorio-seguro\main.tf line 32, in resource "github_repository" "this":
  32:   vulnerability_alerts = true

Use the github_repository_vulnerability_alerts resource instead. This field
will be removed in a future version.

(and one more similar warning elsewhere)

  run "descricao_longa"... pass

Warning: Argument is deprecated

  with github_repository.this,
  on modules\repositorio-seguro\main.tf line 32, in resource "github_repository" "this":
  32:   vulnerability_alerts = true

Use the github_repository_vulnerability_alerts resource instead. This field
will be removed in a future version.

  run "visibilidade_invalida"... pass

Warning: Argument is deprecated

  with github_repository.this,
  on modules\repositorio-seguro\main.tf line 32, in resource "github_repository" "this":
  32:   vulnerability_alerts = true

Use the github_repository_vulnerability_alerts resource instead. This field
will be removed in a future version.

  run "topico_invalido"... pass

Warning: Argument is deprecated

  with github_repository.this,
  on modules\repositorio-seguro\main.tf line 32, in resource "github_repository" "this":
  32:   vulnerability_alerts = true

Use the github_repository_vulnerability_alerts resource instead. This field
will be removed in a future version.

tests\repositorio_seguro.tftest.hcl... tearing down
tests\repositorio_seguro.tftest.hcl... pass

Success! 10 passed, 0 failed.
```

### tflint --recursive

Código de saída: 0.

```text
(sem saída; comando concluído com sucesso)
```

## Desvios e decisões

- `versions.tf`, `.gitignore`, o lock file existente, a spec e o arquivo
  `01-resultado-codex.md` preexistente foram preservados. Não foi criado commit.
- A declaração de requisitos do provider foi adicionada dentro de `main.tf` do
  módulo: módulos filhos precisam declarar a origem `integrations/github` para
  não inferirem `hashicorp/github`. Isso também satisfaz o TFLint recommended.
- O ruleset depende explicitamente de `SECURITY.md`, evitando bloquear o commit
  inicial pelo PR obrigatório. O arquivo usa a branch padrão implicitamente,
  conforme o schema, sem depender do atributo depreciado `default_branch`.
- O exercício de geração de configuração usa um resource ainda não declarado,
  em pasta separada. Para o módulo já declarado, o README explica o endereço
  correto de adoção e a necessidade de importar os resources auxiliares.
- Cinco cenários extras ampliam a cobertura mínima da spec: personalização,
  aprovações fracionárias, descrição longa, visibilidade e tópico inválidos.
- Actions fixadas por SHA, sem recorrer à limitação permitida de tags mutáveis.
  SHAs conferidos na API pública do GitHub: checkout v4.2.2, setup-terraform
  v3.1.2, setup-tflint v4.1.1 e checkov-action v12.3146.0.

## Limitações e avisos

- `vulnerability_alerts` está depreciado no provider 6.13.0. Foi mantido porque
  a spec o exige; validate e test passam com avisos. Migração futura:
  `github_repository_vulnerability_alerts`. Não houve supressão de avisos.
- Privados gratuitos não recebem secret scanning/push protection; rulesets
  também podem exigir plano pago. A configuração privada pode falhar na API.
- `SECURITY.md` não habilita Private vulnerability reporting. O mantenedor
  deve ativá-lo nos públicos; nos privados precisa definir um canal interno.
- Atualizações diretas de `SECURITY.md` após o ruleset podem ser bloqueadas.
  Alterações devem passar por PR e ser reconciliadas com a configuração.
- Arquivar preserva o repositório, mas a destruição remove antes os resources
  auxiliares, incluindo ruleset e arquivo. O README explicita essa consequência.
- Checkov foi configurado no CI, mas não executado localmente; o workflow
  remoto também não foi disparado. Não se afirma que o job Checkov passa.
  A regra oficial CKV_GIT_1 exige privado e conflita com o padrão público;
  pode reprovar esse job. Nenhuma política foi suprimida ou relaxada.
- Os testes simulam o provider, sem token e sem chamadas reais ao GitHub;
  não validam permissões, licenciamento, integração real ou comportamento da API.
- State local; backend remoto fica como próximo passo. Init pode precisar
  de rede para instalar providers; os testes com mock não precisam de rede.
- O repositório já continha arquivos não rastreados. Foram preservados;
  `git status` também emitiu aviso de acesso negado ao ignore global do ambiente.

## Restrições respeitadas

Nenhum `terraform apply`, `terraform destroy` ou `terraform import` foi executado.
Esses comandos aparecem somente nas instruções destinadas ao dono no README.
Nenhum token ou segredo foi lido, gerado ou gravado em arquivo.

## Referências consultadas

- [Schema/documentação do provider 6.13.0](https://registry.terraform.io/providers/integrations/github/6.13.0/docs).
- [Geração de configuração de importação — HashiCorp](https://developer.hashicorp.com/terraform/language/import/generating-configuration).
- [Reporte privado — GitHub](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository).
- [Implementação oficial da política CKV_GIT_1 — Checkov](https://github.com/bridgecrewio/checkov/blob/main/checkov/terraform/checks/resource/github/PrivateRepo.py).

## Revisão (Claude), 24/11/2026

- `vulnerability_alerts` (obsoleto no provider 6.13.0) foi trocado pelo resource
  `github_repository_vulnerability_alerts`. O Dependabot security updates passa a
  depender dele (`depends_on`). Testes e README foram ajustados.
- `CKV_GIT_1` foi suprimido só no `github_repository`, com justificativa inline:
  a visibilidade pública é intencional (em conta gratuita, só repositórios públicos
  têm secret scanning, push protection e ruleset).
- O CI foi alinhado às versões locais: Terraform 1.17.2 e TFLint 0.66.0.
- Os SHAs das quatro actions foram conferidos na API do GitHub e batem com as tags
  comentadas.
- Verificação local depois da revisão: `fmt` 0, `validate` Success, `test` 10/10,
  `tflint` 0, Checkov 3.4.10 com 2 aprovados, 0 reprovados e 1 suprimido.
- Não verificado: nenhum `apply` real foi executado. O comportamento da API do
  GitHub, como `security_and_analysis` em repositório recém-criado, ainda precisa
  ser confirmado no primeiro apply.

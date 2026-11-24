# Repositórios do GitHub protegidos com Terraform

[![Terraform](https://github.com/ptkthg/terraform-github-seguro/actions/workflows/terraform.yml/badge.svg)](https://github.com/ptkthg/terraform-github-seguro/actions/workflows/terraform.yml)

Projeto de portfólio de security engineering de um analista de DFIR: transforma
decisões de segurança em configurações reproduzíveis e testáveis. Um mapa na raiz
cria vários repositórios pelo módulo `repositorio-seguro`, com proteção do histórico,
pull requests obrigatórios, alertas e correções de dependências vulneráveis.
Os comentários relacionam as configurações aos riscos que reduzem.

## Decisão → risco que reduz

| Decisão | Risco que reduz |
|---|---|
| Visibilidade explícita (`public` por padrão) | Evita depender de um padrão implícito; escolha `private` para conteúdo restrito |
| `auto_init = true` | Evita tentar proteger uma branch inexistente |
| Wiki e Projects desativados | Reduz superfícies paralelas de conteúdo fora do fluxo de revisão |
| Issues ativadas | Mantém triagem rastreável de problemas não sensíveis |
| Apenas squash; merge commit e rebase merge desativados | Simplifica a auditoria de cada mudança incorporada |
| Exclusão de branches após merge | Reduz branches abandonadas e alterações na base errada |
| `github_repository_vulnerability_alerts` | Reduz o tempo até identificar dependências vulneráveis |
| Dependabot security updates | Propõe correções para reduzir a janela de exposição; exige dependências reconhecidas |
| Secret scanning em públicos | Detecta credenciais expostas em conteúdo versionado |
| Push protection em públicos | Bloqueia o envio de segredos reconhecidos antes da publicação |
| `archive_on_destroy = true` | Evita apagar irreversivelmente o repositório; preservação lembra a evidência imutável em DFIR |
| Ruleset ativo na branch padrão, sem exclusões ou bypass | Evita caminhos de exceção, inclusive para administradores |
| Proibir exclusão da branch (`deletion`) | Evita perda da referência principal |
| Proibir force push (`non_fast_forward`) | Impede reescrever o histórico e apagar rastros |
| Histórico linear obrigatório | Facilita investigar a sequência de mudanças |
| Commits assinados opcionais | Quando exigidos, reduzem falsificação de autoria; padrão `false` facilita o primeiro laboratório |
| Pull request obrigatório | Registra proposta, discussão e integração das mudanças |
| Aprovações configuráveis de 0 a 6 | Permite revisão por pares; padrão 0 evita bloquear o único desenvolvedor, mantendo PR obrigatório |
| Descartar aprovações após novos commits | Evita reutilizar aprovação para código que ainda não foi revisado |
| Resolver discussões antes do merge | Evita incorporar mudanças com questionamentos pendentes |
| `SECURITY.md` com reporte privado | Evita divulgação prematura de vulnerabilidades em issues públicas |
| Token só em `GITHUB_TOKEN`, com validade curta | Reduz exposição de credenciais no código e limita sua janela de uso |
| CI com `contents: read`, sem PAT e actions fixadas por SHA | Limita privilégios e mudanças inesperadas nas dependências de automação |

## Como rodar

Requisitos: Terraform >= 1.7 (validado com 1.17.2), TFLint (validado com 0.66.0),
Git e uma conta GitHub. O lock file seleciona `integrations/github` 6.13.0.

1. No GitHub, em **Settings → Developer settings → Personal access tokens →
   Fine-grained tokens**, crie um token de validade curta. Selecione o owner e
   **All repositories**, pois os repositórios novos ainda não existem. Conceda
   **Administration: Read and write** e **Contents: Read and write**;
   **Metadata: Read** é incluída automaticamente. Políticas da organização podem
   exigir aprovação ou permissões adicionais para recursos de segurança.
2. Defina o token apenas na sessão do PowerShell. O trecho abaixo é ilustrativo;
   evite inserir o valor literal no histórico: leia-o com entrada oculta.

   ```powershell
   # Forma ilustrativa: $env:GITHUB_TOKEN = "..."
   $credencial = Read-Host "GITHUB_TOKEN" -AsSecureString
   $env:GITHUB_TOKEN = [System.Net.NetworkCredential]::new("", $credencial).Password
   Remove-Variable credencial
   Copy-Item terraform.tfvars.example terraform.tfvars
   ```

3. Edite `terraform.tfvars`: troque `github_owner` e escolha os repositórios.
   Para o primeiro laboratório gratuito, mantenha apenas um repositório público.
   O exemplo privado exige plano compatível com rulesets. Nunca grave o token
   em `.tf`, `.tfvars` ou qualquer outro arquivo.
4. Execute e revise o plano. Somente o dono executa a etapa final:

   ```powershell
   terraform init
   terraform test
   terraform plan
   terraform apply
   Remove-Item Env:GITHUB_TOKEN
   ```

A saída `urls` mapeia nomes para URLs. Faça alterações de conteúdo por PR.
O ruleset depende de `SECURITY.md` para permitir o primeiro commit, sem bypass.

## Exercícios

1. **Testes sem token:** após `terraform init -backend=false`, remova
   `GITHUB_TOKEN` da sessão e execute `terraform test`. Observe planos simulados
   com `mock_provider` para público, privado, validações e duas instâncias da raiz.
   O teste não chama a API nem cria repositórios; o init inicial pode baixar o provider.
2. **Um repositório de teste:** configure só um item público, execute
   `terraform plan` e, como dono, `terraform apply`. Observe os quatro resources,
   a política de segurança e o ruleset ativo. Crie uma branch e abra PR para alterar conteúdo.
3. **Drift:** habilite a wiki pela interface do GitHub e execute `terraform plan`.
   Observe `has_wiki` voltando a `false`; nenhuma correção ocorre até o apply.
4. **Segundo repositório:** acrescente outra chave ao mapa. No plano, observe
   apenas os quatro resources do novo módulo, sem recriar o anterior.
5. **Importação declarativa (somente o dono):** para estudar geração de HCL,
   use uma pasta de laboratório separada com o provider e o owner configurados,
   sem resource `github_repository.existente` declarado. Adicione:

   ```hcl
   import {
     to = github_repository.existente
     id = "repositorio-existente"
   }
   ```

   Execute `terraform init` e
   `terraform plan -generate-config-out=gerado.tf`. Observe o HCL gerado e o
   plano de importação: a leitura e a geração não alteram o repositório nem
   persistem a importação no state até o apply. O arquivo de destino precisa
   ser novo. A geração serve para resources ainda não declarados; como o módulo
   já declara seus resources, para adotá-lo use um bloco `import` com
   `to = module.repositorio["repositorio-existente"].github_repository.this`
   e a mesma chave em `repositorios`, sem esperar gerar novamente seu código.
   Importe também os demais resources existentes antes de aplicar; revise
   diferenças, especialmente `SECURITY.md`, para evitar sobrescrever políticas.
   [Referência da HashiCorp](https://developer.hashicorp.com/terraform/language/import/generating-configuration).
6. **Arquivamento (somente o dono):** em laboratório, `terraform destroy`
   remove os resources auxiliares e arquiva o repositório em vez de apagá-lo.
   Observe a remoção do ruleset e de `SECURITY.md` antes do arquivamento:
   `archive_on_destroy` preserva o repositório, não toda a configuração de segurança.
   Para recuperar o uso, abra **Settings → General → Danger Zone → Unarchive
   this repository**. Para apagar definitivamente, use **Delete this repository**
   nessa mesma área, apenas se quiser perder os dados. Após o destroy, o
   repositório sai do state: desarquivar não o reinsere; um novo apply com o
   mesmo nome requer adoção/importação cuidadosa pelo dono.

## Validação e CI

```powershell
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
tflint --recursive
```

O workflow roda em PRs e pushes na `main`, com jobs de Terraform, TFLint e
Checkov (`framework: terraform`). Não recebe PAT nem aplica alterações.
Checkov complementa os testes com análise estática; seus achados devem ser
avaliados no contexto de repositórios de portfólio públicos e aprovações opcionais.
A política `CKV_GIT_1` exige repositórios privados e conflita com o padrão público
deste projeto. Ela foi suprimida **só nesse resource**, com justificativa no próprio
código (`#checkov:skip=CKV_GIT_1:...` em `modules/repositorio-seguro/main.tf`): em conta
gratuita, só repositórios públicos têm secret scanning, push protection e ruleset.
Exceção de política é uma decisão explícita e rastreável, nunca um desligamento global.

## Limitações

- Em privados gratuitos, o módulo omite secret scanning e push protection;
  rulesets também dependem do plano. O módulo mantém o ruleset exigido e um
  apply de privado sem suporte pode falhar. Use público no laboratório gratuito.
- O state é local e pode conter dados do repositório. Não o versione. O próximo
  passo é backend remoto com controle de acesso, criptografia e locking.
- Testes com mock verificam o plano, sem comprovar permissões, licenciamento,
  comportamento da API ou a aplicação real. O CI não aplica.
- Criar `SECURITY.md` não habilita **Private vulnerability reporting**.
  O mantenedor precisa ativá-lo em públicos, em **Settings → Advanced Security**.
  O recurso não oferece esse canal em privados; estabeleça um canal interno
  antes de usar o módulo nesse contexto.
  [Configuração oficial do GitHub](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository).
- Depois de ativo o ruleset, updates diretos de `SECURITY.md` pelo resource
  podem ser bloqueados. Faça mudanças por PR e reconcilie o conteúdo Terraform;
  não há bypass administrativo automático.

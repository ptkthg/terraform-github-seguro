# Módulo repositorio-seguro

Cria um repositório, habilita correções do Dependabot, publica `SECURITY.md`
e protege a branch padrão com ruleset sem bypass. O provider é herdado da raiz.
Requer Terraform >= 1.7 e `integrations/github ~> 6.0` (testado com 6.13.0).

| Entrada | Tipo | Padrão | Restrição |
|---|---|---|---|
| `nome` | `string` | obrigatório | `^[a-z0-9][a-z0-9-]{0,98}[a-z0-9]$` |
| `descricao` | `string` | `""` | até 350 caracteres |
| `visibilidade` | `string` | `"public"` | `public` ou `private` |
| `aprovacoes_obrigatorias` | `number` | `0` | inteiro de 0 a 6 |
| `exigir_commits_assinados` | `bool` | `false` | assinatura verificada quando ativado |
| `topicos` | `list(string)` | `[]` | cada tópico: `^[a-z0-9][a-z0-9-]{0,49}$` |

Zero aprovações permite trabalhar sozinho, mas o PR continua obrigatório.
Secret scanning e push protection só são configurados para repositórios públicos.
Privados precisam de plano compatível para rulesets.

| Saída | Descrição |
|---|---|
| `nome` | Nome do repositório |
| `url_html` | `html_url` do repositório |
| `ruleset_id` | ID numérico do ruleset no GitHub |

`SECURITY.md` é criado antes do ruleset para permitir o primeiro commit direto.
Depois disso, alterações no arquivo devem passar por PR: o resource de arquivo
não contorna o ruleset. O reporte privado precisa ser habilitado pelo mantenedor
nos repositórios públicos; a criação do Markdown não habilita esse recurso.

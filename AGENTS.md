# terraform-github-seguro: instruções para agentes

Projeto de portfólio (security engineering): repositórios do GitHub criados e protegidos com Terraform.
Idioma: português do Brasil, com acentuação correta. Nomes de resources, atributos e comandos ficam no original.

## Regras
1. **Nunca rode `terraform apply`, `terraform destroy` nem `terraform import`.** Eles mexem em repositórios reais. Só o dono do projeto roda esses comandos.
2. **Nunca grave tokens ou segredos** em arquivo nenhum. O token vem da variável de ambiente `GITHUB_TOKEN`.
3. O código é didático: comentários curtos em português explicam **por que** cada configuração de segurança existe (qual risco ela reduz), não só o que ela faz.
4. Antes de terminar, tudo isto precisa passar:
   ```
   terraform fmt -check -recursive
   terraform init -backend=false
   terraform validate
   terraform test
   tflint --recursive
   ```
   Os testes usam `mock_provider` e não precisam de token nem de rede.
5. Specs ficam em `docs/tasks/NN-*.md`. Quem implementa registra o resultado em `docs/tasks/NN-resultado.md`: o que fez, as saídas dos comandos acima, os desvios da spec e as limitações.

module "repositorio" {
  source   = "./modules/repositorio-seguro"
  for_each = var.repositorios

  nome                     = each.key
  descricao                = each.value.descricao
  visibilidade             = each.value.visibilidade
  aprovacoes_obrigatorias  = each.value.aprovacoes_obrigatorias
  exigir_commits_assinados = each.value.exigir_commits_assinados
  topicos                  = each.value.topicos
}

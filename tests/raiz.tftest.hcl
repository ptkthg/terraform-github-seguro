mock_provider "github" {}

run "dois_repositorios" {
  command = plan
  variables {
    github_owner = "seu-usuario"
    repositorios = {
      laboratorio-publico = {}
      laboratorio-privado = { visibilidade = "private" }
    }
  }
  assert {
    condition = (
      length(module.repositorio) == 2 &&
      module.repositorio["laboratorio-publico"].nome == "laboratorio-publico" &&
      module.repositorio["laboratorio-privado"].nome == "laboratorio-privado" &&
      toset(keys(output.urls)) == toset(keys(var.repositorios))
    )
    error_message = "Cada chave do mapa deve criar uma instância e uma entrada no mapa de URLs."
  }
  assert {
    condition = (
      var.repositorios["laboratorio-privado"].descricao == "" &&
      var.repositorios["laboratorio-privado"].aprovacoes_obrigatorias == 0 &&
      !var.repositorios["laboratorio-privado"].exigir_commits_assinados &&
      length(var.repositorios["laboratorio-privado"].topicos) == 0 &&
      var.repositorios["laboratorio-publico"].visibilidade == "public"
    )
    error_message = "Os atributos optional devem preencher os padrões omitidos."
  }
}

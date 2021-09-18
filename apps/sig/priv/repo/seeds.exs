alias Sig.Repo

# Org
alias Sig.Organizations.Org

org =
  %{name: "Acme"}
  |> Org.changeset()
  |> Repo.insert!()

# Individuals
alias Sig.Entities
alias Sig.Entities.Individuals.Individual.Gender

attrs = %{
  org_id: org.id,
  name: "Samuel Levy",
  cpf: "34110230829",
  gender: :male
}

{:ok, samuel} = Entities.create_individual(org.id, attrs)

Enum.map(1..5, fn _ ->
  attrs = %{
    org_id: org.id,
    name: Faker.Person.first_name() <> " " <> Faker.Person.last_name(),
    cpf: BrazilianDocuments.generate_cpf(),
    gender: Enum.random(Gender.__valid_values__())
  }

  {:ok, _individual} = Entities.create_individual(org.id, attrs)
end)

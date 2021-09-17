alias Sig.Repo

# Organization
alias Sig.Organizations.Organization

organization =
  %{name: "Acme"}
  |> Organization.changeset()
  |> Repo.insert!()

# Individuals
alias Sig.Entities
alias Sig.Entities.Individuals.Individual.Gender

attrs = %{
  organization_id: organization.id,
  name: "Samuel Levy",
  cpf: "34110230829",
  gender: :male
}

{:ok, samuel} = Entities.create_individual(organization.id, attrs)

Enum.map(1..5, fn _ ->
  attrs = %{
    organization_id: organization.id,
    name: Faker.Person.first_name() <> " " <> Faker.Person.last_name(),
    cpf: BrazilianDocuments.generate_cpf(),
    gender: Enum.random(Gender.__valid_values__())
  }

  {:ok, _individual} = Entities.create_individual(organization.id, attrs)
end)

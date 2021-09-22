alias Sig.Repo

# Orgs
alias Sig.Organizations.Org

main_org =
  %{name: "Acme"}
  |> Org.changeset()
  |> Repo.insert!()

_another_org =
  %{name: "Dunder Mifflin"}
  |> Org.changeset()
  |> Repo.insert!()

# Individuals
alias Sig.Entities
alias Sig.Entities.Individuals.Individual.Gender

attrs = %{
  name: "Samuel Levy",
  cpf: "34110230829",
  gender: :male
}

{:ok, samuel} = Entities.create_individual(main_org, attrs)

Enum.map(1..5, fn _ ->
  attrs = %{
    name: Faker.Person.first_name() <> " " <> Faker.Person.last_name(),
    cpf: BrazilianDocuments.generate_cpf(),
    gender: Enum.random(Gender.__valid_values__())
  }

  {:ok, _individual} = Entities.create_individual(main_org, attrs)
end)

# Users
alias Sig.Accounts

attrs = %{
  email: "samulevy@gmail.com",
  password: "hello world!",
  individual_id: samuel.entity_id,
  org_id: samuel.org_id,
  org_roles: %{
    main_org.id => :admin
  }
}

{:ok, _user_samuel} = Accounts.register_user(attrs)

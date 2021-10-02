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

# Companies
alias Sig.Entities.Entity
alias Sig.Entities.Companies.Company

entity = Repo.insert!(%Entity{org_id: main_org.id, type: :company})
Repo.insert!(%Company{
  trade_name: "CiB Mogi",
  is_virtual: false,
  registration_name: "China in Box Mogi das Cruzes Ltda.",
  cnpj: BrazilianDocuments.generate_cnpj(),
  org_id: main_org.id,
  entity_id: entity.id
})

entity = Repo.insert!(%Entity{org_id: main_org.id, type: :company})
Repo.insert!(%Company{
  trade_name: "CiB Suzano",
  is_virtual: false,
  registration_name: "China in Box Suzano Ltda.",
  cnpj: BrazilianDocuments.generate_cnpj(),
  org_id: main_org.id,
  entity_id: entity.id
})

entity = Repo.insert!(%Entity{org_id: main_org.id, type: :company})
Repo.insert!(%Company{
  trade_name: "CiB Penha",
  is_virtual: false,
  registration_name: "China in Box Penha Ltda.",
  cnpj: BrazilianDocuments.generate_cnpj(),
  org_id: main_org.id,
  entity_id: entity.id
})

entity = Repo.insert!(%Entity{org_id: main_org.id, type: :company})
Repo.insert!(%Company{
  trade_name: "CiB São Miguel",
  is_virtual: false,
  registration_name: "China in Box São Miguel Ltda.",
  cnpj: BrazilianDocuments.generate_cnpj(),
  org_id: main_org.id,
  entity_id: entity.id
})

entity = Repo.insert!(%Entity{org_id: main_org.id, type: :company})
Repo.insert!(%Company{
  trade_name: "Escritório",
  is_virtual: true,
  org_id: main_org.id,
  entity_id: entity.id
})

entity = Repo.insert!(%Entity{org_id: main_org.id, type: :company})
Repo.insert!(%Company{
  trade_name: "Call Center",
  is_virtual: true,
  org_id: main_org.id,
  entity_id: entity.id
})

entity = Repo.insert!(%Entity{org_id: main_org.id, type: :company})
Repo.insert!(%Company{
  trade_name: "Central de Processamento",
  is_virtual: true,
  org_id: main_org.id,
  entity_id: entity.id
})

# Org Sectors
alias Sig.Organizations.Sector

Repo.insert!(%Sector{org_id: main_org.id, name: "Cozinha"})
Repo.insert!(%Sector{org_id: main_org.id, name: "Atendimento"})
Repo.insert!(%Sector{org_id: main_org.id, name: "Entrega"})
Repo.insert!(%Sector{org_id: main_org.id, name: "Limpeza"})
Repo.insert!(%Sector{org_id: main_org.id, name: "Gerência"})
Repo.insert!(%Sector{org_id: main_org.id, name: "Administrativo"})

# Org Positions
alias Sig.Organizations.Position

Repo.insert!(%Position{org_id: main_org.id, name: "Cozinheiro"})
Repo.insert!(%Position{org_id: main_org.id, name: "Assistente de Cozinha"})
Repo.insert!(%Position{org_id: main_org.id, name: "Auxiliar de Limpeza"})
Repo.insert!(%Position{org_id: main_org.id, name: "Gerente"})
Repo.insert!(%Position{org_id: main_org.id, name: "Atendente"})
Repo.insert!(%Position{org_id: main_org.id, name: "Assistente Administrativo"})
Repo.insert!(%Position{org_id: main_org.id, name: "Auxiliar de Escritório"})
Repo.insert!(%Position{org_id: main_org.id, name: "Entregador Motorizado"})

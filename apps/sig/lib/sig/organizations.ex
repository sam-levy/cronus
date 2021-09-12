defmodule Sig.Organizations do
  alias Sig.Organizations.Entities

  defdelegate list_organization_individuals(organization_id), to: Entities
  defdelegate individual_change(attrs), to: Entities
  defdelegate cast_individual_params(params), to: Entities
  defdelegate fetch_individual_by_cpf(organization_id, cpf), to: Entities
  defdelegate create_organization_individual(organization_id, attrs), to: Entities
  defdelegate update_individual(individual, attrs), to: Entities
end

defmodule Sig.Entities do
  alias Sig.Entities.Individuals

  defdelegate individual_change(attrs), to: Individuals
  defdelegate cast_individual_params(params), to: Individuals
  defdelegate list_organization_individuals(organization_id), to: Individuals
  defdelegate fetch_individual_by_cpf(organization_id, cpf), to: Individuals
  defdelegate create_individual(organization_id, attrs), to: Individuals
  defdelegate update_individual(individual, attrs), to: Individuals
  defdelegate subscribe_to_organization_individuals(organization_id), to: Individuals
  defdelegate broadcast_organization_individuals(organization_id), to: Individuals
end

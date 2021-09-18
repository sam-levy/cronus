defmodule Sig.Entities do
  alias Sig.Entities.Individuals

  defdelegate individual_change(attrs), to: Individuals
  defdelegate cast_individual_params(params), to: Individuals
  defdelegate list_individuals(org_id), to: Individuals
  defdelegate fetch_individual_by_cpf(org_id, cpf), to: Individuals
  defdelegate create_individual(org_id, attrs), to: Individuals
  defdelegate update_individual(individual, attrs), to: Individuals
  defdelegate subscribe_to_individuals(org_id), to: Individuals
  defdelegate broadcast_individuals(org_id), to: Individuals
end

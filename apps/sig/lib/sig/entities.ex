defmodule Sig.Entities do
  alias Sig.Entities.Individuals

  defdelegate create_individual_change(attrs), to: Individuals
  defdelegate list_individuals(org), to: Individuals
  defdelegate get_individual(org, entity_id), to: Individuals
  defdelegate fetch_individual_by_cpf(org, cpf), to: Individuals
  defdelegate create_individual(org, attrs), to: Individuals
  defdelegate update_individual(individual, attrs), to: Individuals
  defdelegate subscribe_to_individuals(org), to: Individuals
  defdelegate broadcast_individuals(org), to: Individuals
end

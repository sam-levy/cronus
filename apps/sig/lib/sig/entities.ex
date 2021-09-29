defmodule Sig.Entities do
  import Ecto.Query

  alias Sig.Documents
  alias Sig.Entities.Entity
  alias Sig.Entities.Individuals
  alias Sig.Repo

  defdelegate create_individual_change(attrs), to: Individuals
  defdelegate list_individuals(org), to: Individuals
  defdelegate get_individual(org, entity_id), to: Individuals
  defdelegate fetch_individual_by_cpf(org, cpf), to: Individuals
  defdelegate create_individual(org, attrs), to: Individuals
  defdelegate update_individual(individual, attrs), to: Individuals
  defdelegate subscribe_to_individuals(org), to: Individuals
  defdelegate broadcast_individuals(org), to: Individuals

  def fetch_by_document(org, document) do
    case Documents.format_document(document) do
      {:cpf, cpf} -> fetch_by_cpf(org, cpf)
      {:cnpj, cnpj} -> fetch_by_cnpj(org, cnpj)
      :error -> :error
    end
  end

  def fetch_by_cpf(org, cpf) do
    case Documents.format_cpf(cpf) do
      {:ok, cpf} ->
        Entity
        |> where(org_id: ^org.id)
        |> where(type: :individual)
        |> join(:left, [entity], individual in assoc(entity, :individual))
        |> where([_entity, individual], individual.cpf == ^cpf)
        |> preload([_entity, individual], individual: individual)
        |> Repo.one()
        |> as_result()

      :error ->
        :error
    end
  end

  def fetch_by_cnpj(org, cnpj) do
    case Documents.format_cnpj(cnpj) do
      {:ok, cnpj} ->
        Entity
        |> where(org_id: ^org.id)
        |> where(type: :company)
        |> join(:left, [entity], company in assoc(entity, :company))
        |> where([_entity, company], company.cnpj == ^cnpj)
        |> preload([_entity, company], company: company)
        |> Repo.one()
        |> as_result()

      :error ->
        :error
    end
  end

  def get_name(%Entity{type: :individual, individual: %{name: name}}), do: name

  def get_name(%Entity{type: :company, company: %{trade_name: nil, registration_name: name}}) do
    name
  end

  def get_name(%Entity{type: :company, company: %{trade_name: name}}), do: name
  def get_name(_entity), do: nil

  defp as_result(%Entity{} = entity), do: {:ok, entity}
  defp as_result(nil), do: {:error, :not_found}
end

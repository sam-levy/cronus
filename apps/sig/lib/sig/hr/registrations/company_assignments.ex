defmodule Sig.HR.Registrations.CompanyAssignments do
  use Sig.Preloader, company_assignment: [:assigned_company]

  import Sig.Broadcaster

  alias Sig.HR.Registrations.CompanyAssignments.CompanyAssignment
  alias Sig.HR.Registrations.Registration
  alias Sig.Repo

  def default_preloads(), do: [:assigned_company]

  def create_change(%{} = attrs \\ %{}), do: CompanyAssignment.create_changeset(attrs)

  def create(%Registration{} = registration, %{} = attrs) do
    attrs
    |> Map.put(:org_id, registration.org_id)
    |> Map.put(:registration_id, registration.id)
    |> CompanyAssignment.create_changeset()
    |> Repo.insert()
  end

  def delete(%CompanyAssignment{} = company_assignment) do
    company_assignment
    |> query_by()
    |> Repo.aggregate(:count)
    |> case do
      1 -> {:error, "Deve existir pelo menos uma designação"}
      _ -> Repo.delete(company_assignment)
    end
  end

  def list_by(%Registration{} = schema, opts \\ []), do: do_list_by(schema, opts)

  def get(%Registration{} = schema, id, opts \\ []) when is_binary(id) do
    do_get(schema, id, opts)
  end

  def fetch(schema, id, opts \\ []) do
    case get(schema, id, opts) do
      nil -> {:error, :not_found}
      %CompanyAssignment{} = assignment -> {:ok, assignment}
    end
  end

  defp do_get(schema, id, opts) do
    schema
    |> query_by()
    |> where(id: ^id)
    |> shallow_preload(opts)
    |> shallow_preload(default_preloads())
    |> Repo.one()
  end

  defp do_list_by(schema, opts) do
    schema
    |> query_by()
    |> shallow_preload(opts)
    |> shallow_preload(default_preloads())
    |> order_by(:start_date)
    |> Repo.all()
  end

  def init_query, do: from(p in CompanyAssignment, as: :company_assignment)

  defp query_by(%CompanyAssignment{} = company_assignment) do
    init_query()
    |> where(org_id: ^company_assignment.org_id)
    |> where(registration_id: ^company_assignment.registration_id)
  end

  defp query_by(%Registration{} = registration) do
    init_query()
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
  end

  def subscribe_to_company_assignments(schema), do: subscribe(topics_for(schema))

  def broadcast_updated_company_assignments(%Registration{} = registration) do
    company_assignments = list_by(registration, preload: default_preloads())

    broadcast(
      topics_for(registration),
      {:updated_registration_company_assignments, company_assignments}
    )
  end

  defp topics_for(%Registration{} = registration) do
    registration_company_assignments_topic(registration.org_id, registration.id)
  end

  defp registration_company_assignments_topic(org_id, registration_id) do
    "org_id:" <> org_id <> ":registration_id:" <> registration_id <> ":company_assignments"
  end
end

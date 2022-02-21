defmodule Sig.HR.Registrations.CompanyAssignments do
  use Sig.Preloader, company_assignment: [:assigned_company]

  import Sig.Broadcaster

  alias Sig.HR.Registrations
  alias Sig.HR.Registrations.CompanyAssignments.CompanyAssignment
  alias Sig.HR.Registrations.Registration
  alias Sig.Repo

  def default_preloads(), do: [:assigned_company]

  def create_change(%{} = attrs \\ %{}), do: CompanyAssignment.create_changeset(attrs)

  def update_change(%CompanyAssignment{} = company_assignment, %{} = attrs \\ %{}) do
    CompanyAssignment.update_changeset(company_assignment, attrs)
  end

  def create(%Registration{} = registration, %{} = attrs) do
    attrs
    |> Map.put(:org_id, registration.org_id)
    |> Map.put(:registration_id, registration.id)
    |> CompanyAssignment.create_changeset()
    |> Repo.insert()
  end

  def update(%CompanyAssignment{} = company_assignment, %{start_date: start_date} = attrs) do
    with %{admission_date: admission_date} <-
           Registrations.get_by(
             org_id: company_assignment.org_id,
             id: company_assignment.registration_id
           ),
         comparison when comparison in [:gt, :eq] <- Date.compare(start_date, admission_date) do
      do_update(company_assignment, attrs)
    else
      :lt -> {:error, "A data inicial deve ser igual ou posterir a data de registro"}
    end
  end

  def update(%CompanyAssignment{} = company_assignment, %{} = attrs),
    do: do_update(company_assignment, attrs)

  defp do_update(company_assignment, attrs) do
    company_assignment
    |> CompanyAssignment.update_changeset(attrs)
    |> Repo.update()
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

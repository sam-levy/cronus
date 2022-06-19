defmodule Sig.HR.Registrations.Create do
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Entities
  alias Sig.Entities.Individuals.Individual
  alias Sig.HR.Registrations.CompanyAssignments.CompanyAssignment
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.RegistrationPositions.RegistrationPosition
  alias Sig.HR.Registrations.Salaries.Salary
  alias Sig.Organizations.Org
  alias Sig.Repo

  def call(%Org{} = org, %Individual{} = individual, %{} = attrs) do
    %{attrs: attrs, org: org, individual: individual}
    |> Extep.new()
    |> Extep.run(&build_changeset/1, :changeset)
    |> Extep.run(&validate_real_company/1)
    |> Extep.run(&validate_admission_date/1)
    |> Extep.run(&create_multi/1, :registration)
    |> Extep.return(:registration)
  end

  defp build_changeset(context) do
    %{org: org, individual: individual, attrs: attrs} = context

    attrs
    |> Map.put(:org_id, org.id)
    |> Map.put(:individual_id, individual.entity_id)
    |> Registration.create_changeset()
    |> case do
      %{valid?: true} = changeset -> {:ok, changeset}
      changeset -> {:error, changeset}
    end
  end

  defp validate_real_company(context) do
    %{attrs: %{registered_at_id: registered_at_id}, org: org} = context

    case Entities.fetch_company(org, registered_at_id) do
      {:error, :not_found} -> {:error, "empresa não encontrada"}
      {:ok, %{is_virtual: true}} -> {:error, "empresa virtual"}
      {:ok, %{is_virtual: false}} -> :ok
    end
  end

  defp validate_admission_date(context) do
    %{org: org, individual: individual} = context
    %{registered_at_id: registered_at_id, admission_date: admission_date} = context.attrs

    Registration
    |> where(org_id: ^org.id)
    |> where(individual_id: ^individual.entity_id)
    |> where(registered_at_id: ^registered_at_id)
    |> last(:resignation_date)
    |> Repo.one()
    |> do_validate_admission_date(admission_date)
  end

  defp do_validate_admission_date(nil, _start_date), do: :ok
  defp do_validate_admission_date(%Registration{resignation_date: nil}, _admission_date), do: :ok

  defp do_validate_admission_date(
         %Registration{resignation_date: resignation_date},
         admission_date
       ) do
    if Date.compare(resignation_date, admission_date) == :lt,
      do: :ok,
      else: {:error, "a data de contratação deve ser posterior a última data de desligamento"}
  end

  defp create_multi(%{changeset: changeset}) do
    Multi.new()
    |> Multi.insert(:registration, changeset)
    |> Multi.insert(:salary, fn %{registration: registration} ->
      registration
      |> build_salary_attrs(changeset.changes.salary_amount)
      |> Salary.create_changeset()
    end)
    |> Multi.insert(:registration_position, fn %{registration: registration} ->
      registration
      |> build_registration_position_attrs(changeset.changes.position_id)
      |> RegistrationPosition.create_changeset()
    end)
    |> Multi.insert(:comapany_assignment, fn %{registration: registration} ->
      registration
      |> build_company_assignment_attrs(changeset.changes)
      |> CompanyAssignment.create_changeset()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{registration: registration}} -> {:ok, registration}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  defp build_salary_attrs(registration, salary_amount) do
    %{
      org_id: registration.org_id,
      registration_id: registration.id,
      start_date: registration.admission_date,
      amount: salary_amount
    }
  end

  defp build_registration_position_attrs(registration, position_id) do
    %{
      org_id: registration.org_id,
      registration_id: registration.id,
      start_date: registration.admission_date,
      position_id: position_id
    }
  end

  defp build_company_assignment_attrs(registration, changes) do
    %{
      org_id: registration.org_id,
      registration_id: registration.id,
      assigned_company_id: changes.assigned_company_entity_id,
      sector_id: changes.sector_id,
      start_date: registration.admission_date
    }
  end
end

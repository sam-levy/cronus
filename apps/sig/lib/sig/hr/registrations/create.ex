defmodule Sig.HR.Registrations.Create do
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Entities
  alias Sig.Entities.Individuals.Individual
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.Salaries.Salary
  alias Sig.Organizations.Org
  alias Sig.Repo

  defmodule Context do
    defstruct status: :ok, attrs: nil, changeset: nil, org: nil, individual: nil, result: nil
  end

  # REFACTOR: Remove unnecessary org
  def call(%Org{} = org, %Individual{} = individual, %{} = attrs) do
    %Context{attrs: attrs, org: org, individual: individual}
    |> build_registration_changeset()
    |> validate_real_company()
    |> validate_admission_date()
    |> create_registration_multi()
    |> handle_result()
  end

  defp build_registration_changeset(context) do
    %{org: org, individual: individual, attrs: attrs} = context

    attrs
    |> Map.put(:org_id, org.id)
    |> Map.put(:individual_id, individual.entity_id)
    |> Registration.create_changeset()
    |> case do
      %{valid?: true} = changeset -> %{context | changeset: changeset}
      changeset -> put_error(context, changeset)
    end
  end

  defp validate_real_company(%{status: :ok} = context) do
    %{attrs: %{registered_at_id: registered_at_id}, org: org} = context

    case Entities.fetch_company(org, registered_at_id) do
      {:error, :not_found} -> put_error(context, "empresa não encontrada")
      {:ok, %{is_virtual: true}} -> put_error(context, "empresa virtual")
      {:ok, %{is_virtual: false}} -> context
    end
  end

  defp validate_real_company(context), do: context

  defp validate_admission_date(%{status: :ok} = context) do
    %{org: org, individual: individual} = context
    %{registered_at_id: registered_at_id, admission_date: admission_date} = context.attrs

    Registration
    |> where(org_id: ^org.id)
    |> where(individual_id: ^individual.entity_id)
    |> where(registered_at_id: ^registered_at_id)
    |> last(:resignation_date)
    |> Repo.one()
    |> do_validate_admission_date(admission_date, context)
  end

  defp validate_admission_date(context), do: context

  defp do_validate_admission_date(nil, _start_date, context), do: context

  defp do_validate_admission_date(%Registration{resignation_date: nil}, _admission_date, context) do
    context
  end

  defp do_validate_admission_date(
         %Registration{resignation_date: resignation_date},
         admission_date,
         context
       ) do
    if Date.compare(resignation_date, admission_date) == :lt do
      context
    else
      put_error(context, "a data de contratação deve ser posterior a última data de desligamento")
    end
  end

  defp create_registration_multi(%{status: :ok, changeset: changeset} = context) do
    Multi.new()
    |> Multi.insert(:create_registration, changeset)
    |> Multi.insert(:create_salary, fn %{create_registration: registration} ->
      registration
      |> build_salary_attrs(changeset.changes.salary_amount)
      |> Salary.create_changeset()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{create_registration: registration}} -> %{context | result: registration}
      {:error, _operation, reason, _changes} -> put_error(context, reason)
    end
  end

  defp create_registration_multi(context), do: context

  defp build_salary_attrs(registration, salary_amount) do
    %{
      org_id: registration.org_id,
      registration_id: registration.id,
      start_date: registration.admission_date,
      amount: salary_amount
    }
  end

  defp put_error(context, error), do: %{context | status: {:error, error}}

  defp handle_result(%{status: {:error, error}}), do: {:error, error}
  defp handle_result(%{result: registration}), do: {:ok, registration}
end

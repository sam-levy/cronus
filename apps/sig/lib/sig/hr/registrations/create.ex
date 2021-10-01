defmodule Sig.HR.Registrations.Create do
  import Ecto.Query

  alias Sig.Entities
  alias Sig.Entities.Individuals.Individual
  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Org
  alias Sig.Repo

  defmodule Context do
    defstruct status: :ok, attrs: nil, changeset: nil, org: nil, individual: nil, result: nil
  end

  def call(%Org{} = org, %Individual{} = individual, %{} = attrs) do
    %Context{attrs: attrs, org: org, individual: individual}
    |> build_changeset()
    |> validate_real_company()
    |> validate_admission_date()
    |> create_registration()
    |> handle_result()
  end

  defp build_changeset(context) do
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
    |> case do
      %{resignation_date: resignation_date} when admission_date < resignation_date ->
        put_error(context, "data de contratação anterior a última data de desligamento")

      _ ->
        context
    end
  end

  defp validate_admission_date(context), do: context

  defp create_registration(%{status: :ok, changeset: changeset} = context) do
    case Repo.insert(changeset) do
      {:ok, registration} -> %{context | result: registration}
      {:error, changeset} -> put_error(context, changeset)
    end
  end

  defp create_registration(context), do: context

  defp put_error(context, error), do: %{context | status: {:error, error}}

  defp handle_result(%{status: {:error, error}}), do: {:error, error}
  defp handle_result(%{result: registration}), do: {:ok, registration}
end

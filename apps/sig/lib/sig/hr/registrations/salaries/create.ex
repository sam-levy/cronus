defmodule Sig.HR.Registrations.Salaries.Create do
  import Ecto.Query

  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.Salaries.Salary
  alias Sig.Repo

  def call(%Registration{} = registration, %{} = attrs) do
    %{attrs: attrs, registration: registration}
    |> Extep.new()
    |> Extep.run(&build_salary_changeset/1, :changeset)
    |> Extep.run(&validate_start_date/1)
    |> Extep.return(&Repo.insert(&1.changeset))
  end

  defp build_salary_changeset(context) do
    %{registration: registration, attrs: attrs} = context

    attrs
    |> Map.put(:org_id, registration.org_id)
    |> Map.put(:registration_id, registration.id)
    |> Salary.create_changeset()
    |> case do
      %{valid?: true} = changeset -> {:ok, changeset}
      changeset -> {:error, changeset}
    end
  end

  defp validate_start_date(context) do
    %{attrs: %{start_date: start_date}, registration: registration} = context

    Salary
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
    |> last(:start_date)
    |> Repo.one()
    |> do_validate_satart_date(start_date)
  end

  defp do_validate_satart_date(nil, _start_date), do: :ok

  defp do_validate_satart_date(%Salary{start_date: last_start_date}, start_date) do
    if Date.compare(last_start_date, start_date) == :lt,
      do: :ok,
      else: {:error, "a data de início deve ser posterior a data de início do último salário"}
  end
end

defmodule Sig.HR.Payslips.Create do
  alias Ecto.Multi
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Payslips.Payslip
  alias Sig.HR.Payslips.Groups
  alias Sig.Repo

  def call(%Registration{} = registration, %{} = attrs) do
    attrs
    |> Map.put(:org_id, registration.org_id)
    |> Map.put(:registration_id, registration.id)
    |> Payslip.create_changeset()
    |> handle_create(registration.org)
  end

  def handle_create(%{valid?: true} = changeset, org) do
    %{type: type, start_date: start_date} = changeset.changes

    Multi.new()
    |> Multi.run(:group, fn _, _ -> Groups.provide(org, start_date, type) end)
    |> Multi.insert(:payslip, fn %{group: group} -> Payslip.assign_group(changeset, group) end)
    |> Repo.transaction()
    |> case do
      {:error, _operation, reason, _changes} -> {:error, reason}
      {:ok, %{payslip: payslip}} -> {:ok, payslip}
    end
  end

  def handle_create(changeset, _org), do: {:error, changeset}
end

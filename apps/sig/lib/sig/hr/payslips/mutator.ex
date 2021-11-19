defmodule Sig.HR.Payslips.Mutator do
  import Ecto.Changeset, only: [put_change: 3]

  alias Ecto.Multi
  alias Sig.HR.Registrations
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Payslip
  alias Sig.HR.Payslips.Groups
  alias Sig.Repo

  @start_date_error "payslip start date can't be before registration admission date"
  @closed_payslip_error "can't modify a closed payslip"

  def create(%Registration{} = registration, %{} = attrs) do
    attrs
    |> Map.put(:org_id, registration.org_id)
    |> Map.put(:registration_id, registration.id)
    |> Payslip.create_changeset()
    |> validate_start_date(registration.admission_date)
    |> handle_create(registration.org)
  end

  def update(%Payslip{is_closed: true}, _attrs) do
    {:error, @closed_payslip_error}
  end

  def update(%Payslip{} = payslip, %{} = attrs) do
    payslip
    |> Payslip.update_changeset(attrs)
    |> handle_update(payslip.org)
  end

  defp validate_start_date(
         %{valid?: true, changes: %{start_date: start_date}} = changeset,
         admission_date
       ) do
    if Date.compare(start_date, admission_date) == :lt do
      {:error, @start_date_error}
    else
      changeset
    end
  end

  defp validate_start_date(changeset, _admission_date), do: changeset

  defp handle_create({:error, message}, _org), do: {:error, message}

  defp handle_create(%{valid?: true} = changeset, org) do
    Multi.new()
    |> Multi.run(:ensure_valid_start_date, fn _, _ -> ensure_valid_start_date(changeset) end)
    |> Multi.run(:group, fn _, _ -> provide_group(org, changeset) end)
    |> Multi.insert(:payslip, fn %{group: group} -> assign_group(changeset, group) end)
    |> Repo.transaction()
    |> handle_return()
  end

  defp handle_create(changeset, _org), do: {:error, changeset}

  defp handle_update(%{valid?: true} = changeset, org) do
    Multi.new()
    |> Multi.run(:ensure_valid_start_date, fn _, _ -> ensure_valid_start_date(changeset) end)
    |> Multi.run(:ensure_payslip_is_open, fn _, _ -> ensure_payslip_is_open(changeset) end)
    |> Multi.run(:group, fn _, _ -> provide_group(org, changeset) end)
    |> Multi.update(:payslip, fn %{group: group} -> assign_group(changeset, group) end)
    |> Repo.transaction()
    |> handle_return()
  end

  defp handle_update(changeset, _org), do: {:error, changeset}

  defp ensure_valid_start_date(changeset) do
    org_id = get_value(:org_id, changeset)
    start_date = get_value(:start_date, changeset)
    registration_id = get_value(:registration_id, changeset)

    with %{admission_date: admission_date} <-
           Registrations.get_by(org_id: org_id, id: registration_id),
         value when value in [:lt, :eq] <- Date.compare(admission_date, start_date) do
      {:ok, nil}
    else
      _ -> {:error, @start_date_error}
    end
  end

  defp ensure_payslip_is_open(changeset) do
    org_id = get_value(:org_id, changeset)
    payslip_id = get_value(:id, changeset)

    case Payslips.get_by(org_id: org_id, id: payslip_id) do
      %Payslip{is_closed: true} -> {:error, @closed_payslip_error}
      %Payslip{} -> {:ok, nil}
    end
  end

  defp provide_group(org, changeset) do
    start_date = get_value(:start_date, changeset)
    type = get_value(:type, changeset)

    Groups.provide(org, start_date, type)
  end

  defp assign_group(changeset, group), do: put_change(changeset, :group_id, group.id)

  defp get_value(field, changeset) do
    case changeset do
      %{changes: %{^field => value}} -> value
      %{data: %{^field => value}} -> value
    end
  end

  defp handle_return({:error, _operation, reason, _changes}), do: {:error, reason}
  defp handle_return({:ok, %{payslip: payslip}}), do: {:ok, payslip}
end

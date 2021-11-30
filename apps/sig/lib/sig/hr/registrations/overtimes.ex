defmodule Sig.HR.Registrations.Overtimes do
  import Ecto.Changeset, only: [add_error: 3]
  import Ecto.Query

  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Payslip
  alias Sig.HR.Registrations.Overtimes.Overtime
  alias Sig.HR.Registrations.Registration
  alias Sig.Repo

  def create_change(%{} = attrs \\ %{}) do
    Overtime.create_changeset(attrs)
  end

  def update_change(%Overtime{} = overtime, %{} = attrs \\ %{}) do
    Overtime.update_changeset(overtime, attrs)
  end

  def assign_payslip_change(%Overtime{} = overtime, %{} = attrs \\ %{}) do
    Overtime.assign_payslip_changeset(overtime, attrs)
  end

  def create(%Registration{} = registration, %{} = attrs) do
    attrs
    |> Map.put(:org_id, registration.org_id)
    |> Map.put(:registration_id, registration.id)
    |> Overtime.create_changeset()
    |> Sig.Changeset.validate_date(:date, [:eq, :gt], registration.admission_date,
      target: "registration admission_date"
    )
    |> Repo.insert()
  end

  def update(%Overtime{payslip_id: nil} = overtime, %{} = attrs) do
    overtime
    |> Overtime.update_changeset(attrs)
    |> Repo.update()
  end

  def update(%Overtime{}, %{}) do
    {:error, "can't update an overtime with an assigned payslip"}
  end

  def assign_payslip(%Overtime{} = overtime, %{} = attrs) do
    overtime
    |> Overtime.assign_payslip_changeset(attrs)
    |> ensure_valid_payslip()
    |> Repo.update()
  end

  defp ensure_valid_payslip(%{valid?: true} = changeset) do
    %{
      changes: %{payslip_id: payslip_id},
      data: %{org_id: org_id, registration_id: registration_id}
    } = changeset

    case Payslips.get_by(org_id: org_id, registration_id: registration_id, id: payslip_id) do
      %Payslip{} -> changeset
      nil -> add_error(changeset, :payslip_id, "must belong to the same registration")
    end
  end

  def drop_payslip(%Overtime{} = overtime) do
    overtime
    |> Overtime.drop_payslip_changeset()
    |> Repo.update()
  end

  def list_by_registration(%Registration{} = registration) do
    registration
    |> query_by_registration()
    |> preload_payslip()
    |> order_by(:date)
    |> Repo.all()
  end

  def list_by_payslip(%Payslip{} = payslip) do
    payslip
    |> query_by_payslip()
    |> preload_payslip()
    |> order_by(:date)
    |> Repo.all()
  end

  def get(%Registration{} = registration, id) when is_binary(id) do
    registration
    |> query_by_registration()
    |> where(id: ^id)
    |> Repo.one()
  end

  def fetch(%Registration{} = registration, id) when is_binary(id) do
    case get(registration, id) do
      %Overtime{} = overtime -> {:ok, overtime}
      nil -> {:error, :not_found}
    end
  end

  def delete(%Overtime{payslip_id: nil} = overtime), do: Repo.delete(overtime)

  def delete(%Overtime{}) do
    {:error, "can't delete an overtime with an assigned payslip"}
  end

  def subscribe_to_registration_overtimes(%Registration{} = registration) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(registration))
  end

  def broadcast_registration_overtimes(%Registration{} = registration) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      topic(registration),
      {:updated_registration_overtimes, list_by_registration(registration)}
    )
  end

  defp topic(%Registration{} = registration) do
    "registration_id:" <> registration.id <> ":overtimes"
  end

  defp query_by_registration(registration) do
    from(overtime in Overtime, as: :overtime)
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
  end

  defp query_by_payslip(payslip) do
    from(overtime in Overtime, as: :overtime)
    |> where(org_id: ^payslip.org_id)
    |> where(payslip_id: ^payslip.id)
  end

  defp preload_payslip(queryable) do
    queryable
    |> join(:left, [overtime: overtime], payslip in assoc(overtime, :payslip), as: :payslip)
    |> preload([payslip: payslip], payslip: payslip)
  end
end

defmodule Sig.HR.Registrations.RecurringPayslipItems do
  import Ecto.Query

  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.RecurringPayslipItems.RecurringPayslipItem
  alias Sig.HR.Registrations.RecurringPayslipItems.ListByRegistration
  alias Sig.Repo

  defdelegate list_by_registration(registration), to: ListByRegistration, as: :call

  def create_change(attrs \\ %{}, type)

  def create_change(%{} = attrs, :payslip_item) do
    RecurringPayslipItem.create_payslip_item_changeset(attrs)
  end

  def create_change(%{} = attrs, :payslip_item_model) do
    RecurringPayslipItem.create_payslip_item_model_changeset(attrs)
  end

  def create_change(%{} = attrs, :outside_item) do
    RecurringPayslipItem.create_outside_item_changeset(attrs)
  end

  def create(%Registration{} = registration, %{} = attrs, type) when is_atom(type) do
    attrs
    |> Map.put(:org_id, registration.org_id)
    |> Map.put(:registration_id, registration.id)
    |> create_change(type)
    |> Repo.insert()
  end

  def delete(%Registration{} = registration, id) when is_binary(id) do
    RecurringPayslipItem
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
    |> where(id: ^id)
    |> select([item], item)
    |> Repo.delete_all()
    |> case do
      {1, [item]} -> {:ok, item}
      _ -> :error
    end
  end

  def subscribe_to_registration_recurring_payslip_items(%Registration{} = registration) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(registration))
  end

  def broadcast_registration_recurring_payslip_items(%Registration{} = registration) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      topic(registration),
      {:updated_registration_recurring_payslip_items, list_by_registration(registration)}
    )
  end

  defp topic(%Registration{} = registration) do
    "registration_id:" <> registration.id <> ":recurring_payslip_items"
  end
end

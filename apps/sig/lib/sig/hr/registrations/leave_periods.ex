defmodule Sig.HR.Registrations.LeavePeriods do
  import Ecto.Query

  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.LeavePeriods.LeavePeriod
  alias Sig.Repo

  def create_change(%{} = attrs \\ %{}), do: LeavePeriod.create_changeset(attrs)

  def update_change(%LeavePeriod{} = leave_period, %{} = attrs \\ %{}) do
    LeavePeriod.update_changeset(leave_period, attrs)
  end

  def list_leave_period_types do
    LeavePeriod.LeavePeriodType.__valid_values__() |> Enum.filter(&is_binary/1)
  end

  def get(%Registration{} = registration, id) when is_binary(id) do
    registration
    |> query_by_registration()
    |> where(id: ^id)
    |> Repo.one()
  end

  def list_by_registration(%Registration{} = registration) do
    registration
    |> query_by_registration()
    |> order_by(:start_date)
    |> Repo.all()
  end

  def create(%Registration{} = registration, %{} = attrs) do
    attrs
    |> Map.put(:org_id, registration.org_id)
    |> Map.put(:registration_id, registration.id)
    |> LeavePeriod.create_changeset()
    |> Repo.insert()
  end

  def update(%LeavePeriod{} = leave_period, %{} = attrs) do
    leave_period
    |> LeavePeriod.update_changeset(attrs)
    |> Repo.update()
  end

  def subscribe_to_registration_leave_periods(%Registration{} = registration) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(registration))
  end

  def broadcast_registration_leave_periods(%Registration{} = registration) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      topic(registration),
      {:updated_registration_leave_periods, list_by_registration(registration)}
    )
  end

  defp topic(%Registration{} = registration) do
    "registration_id:" <> registration.id <> ":leave_periods"
  end

  defp query_by_registration(registration) do
    LeavePeriod
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
  end
end

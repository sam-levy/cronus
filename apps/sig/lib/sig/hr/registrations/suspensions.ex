defmodule Sig.HR.Registrations.Suspensions do
  import Ecto.Query

  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.Suspensions.Suspension
  alias Sig.Repo

  def create_change(%{} = attrs \\ %{}), do: Suspension.create_changeset(attrs)

  def update_change(%Suspension{} = suspension, %{} = attrs \\ %{}) do
    Suspension.update_changeset(suspension, attrs)
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
    |> Repo.all
  end

  def create(%Registration{} = registration, %{} = attrs) do
    attrs
    |> Map.put(:org_id, registration.org_id)
    |> Map.put(:registration_id, registration.id)
    |> Suspension.create_changeset()
    |> Repo.insert()
  end

  def update(%Suspension{} = suspension, %{} = attrs) do
    suspension
    |> Suspension.update_changeset(attrs)
    |> Repo.update()
  end

  def subscribe_to_registration_suspensions(%Registration{} = registration) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(registration))
  end

  def broadcast_registration_suspensions(%Registration{} = registration) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      topic(registration),
      {:updated_registration_suspensions, list_by_registration(registration)}
    )
  end

  defp topic(%Registration{} = registration) do
    "registration_id:" <> registration.id <> ":suspensions"
  end

  defp query_by_registration(registration) do
    Suspension
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
  end
end

defmodule Sig.HR.Registrations.Warnings do
  import Ecto.Query

  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.Warnings.Warning
  alias Sig.Repo

  def create_change(%{} = attrs \\ %{}), do: Warning.create_changeset(attrs)

  def update_change(%Warning{} = warning, %{} = attrs \\ %{}) do
    Warning.update_changeset(warning, attrs)
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
    |> order_by(:date)
    |> Repo.all()
  end

  def create(%Registration{} = registration, %{} = attrs) do
    attrs
    |> Map.put(:org_id, registration.org_id)
    |> Map.put(:registration_id, registration.id)
    |> Warning.create_changeset()
    |> Repo.insert()
  end

  def update(%Warning{} = warning, %{} = attrs) do
    warning
    |> Warning.update_changeset(attrs)
    |> Repo.update()
  end

  def subscribe_to_registration_warnings(%Registration{} = registration) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(registration))
  end

  def broadcast_registration_warnings(%Registration{} = registration) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      topic(registration),
      {:updated_registration_warnings, list_by_registration(registration)}
    )
  end

  defp topic(%Registration{} = registration) do
    "registration_id:" <> registration.id <> ":warnings"
  end

  defp query_by_registration(registration) do
    Warning
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
  end
end

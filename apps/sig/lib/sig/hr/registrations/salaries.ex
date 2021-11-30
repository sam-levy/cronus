defmodule Sig.HR.Registrations.Salaries do
  import Ecto.Query

  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.Salaries.Create
  alias Sig.HR.Registrations.Salaries.Salary
  alias Sig.Repo

  defdelegate create(registration, attrs), to: Create, as: :call

  def create_change(%{} = attrs \\ %{}) do
    Salary.create_changeset(attrs)
  end

  def list_by_registration(%Registration{} = registration) do
    registration
    |> query_by_registration()
    |> order_by(:start_date)
    |> Repo.all()
  end

  def in_effect_on_date(%Registration{} = registration, date) do
    registration
    |> query_by_registration()
    |> where([salary], salary.start_date <= ^date)
    |> last(:start_date)
    |> Repo.one()
  end

  def subscribe_to_registration_salaries(%Registration{} = registration) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(registration))
  end

  def broadcast_registration_salaries(%Registration{} = registration) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      topic(registration),
      {:updated_registration_salaries, list_by_registration(registration)}
    )
  end

  defp topic(%Registration{} = registration) do
    "registration_id:" <> registration.id <> ":salaries"
  end

  defp query_by_registration(registration) do
    Salary
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
  end
end

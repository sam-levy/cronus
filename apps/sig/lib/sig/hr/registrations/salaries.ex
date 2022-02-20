defmodule Sig.HR.Registrations.Salaries do
  import Ecto.Query
  import Sig.Broadcaster

  alias Sig.HR.Registrations
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.Salaries.Create
  alias Sig.HR.Registrations.Salaries.Salary
  alias Sig.Repo

  defdelegate create(registration, attrs), to: Create, as: :call

  def create_change(%{} = attrs \\ %{}) do
    Salary.create_changeset(attrs)
  end

  def update_change(%Salary{} = salary, %{} = attrs \\ %{}) do
    Salary.update_changeset(salary, attrs)
  end

  def update(%Salary{} = salary, %{start_date: start_date} = attrs) do
    with %{admission_date: admission_date} <-
           Registrations.get_by(org_id: salary.org_id, id: salary.registration_id),
         comparison when comparison in [:gt, :eq] <- Date.compare(start_date, admission_date) do
      do_update(salary, attrs)
    else
      :lt -> {:error, "A data inicial deve ser igual ou posterir a data de registro"}
    end
  end

  def update(%Salary{} = salary, %{} = attrs), do: do_update(salary, attrs)

  defp do_update(salary, attrs) do
    salary
    |> Salary.update_changeset(attrs)
    |> Repo.update()
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

  def in_effect_on_date(%Registration{} = registration, date) do
    registration
    |> query_by_registration()
    |> where([salary], salary.start_date <= ^date)
    |> last(:start_date)
    |> Repo.one()
  end

  def subscribe_to_registration_salaries(%Registration{} = registration) do
    subscribe(topic(registration))
  end

  def broadcast_registration_salaries(%Registration{} = registration) do
    broadcast(
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

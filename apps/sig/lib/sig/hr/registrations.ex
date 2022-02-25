defmodule Sig.HR.Registrations do
  use Sig.Query, schema: __MODULE__.Registration, as: :registration

  import Ecto.Query
  import Sig.Broadcaster

  alias Sig.Organizations.Sector
  alias Sig.Organizations.Position
  alias Sig.Organizations.Org
  alias Sig.Entities.Individuals.Individual
  alias Sig.HR.Payslips
  alias Sig.HR.Registrations.Create
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.RegistrationPositions.RegistrationPosition
  alias Sig.Repo

  defdelegate create(org, individual, attrs), to: Create, as: :call

  def create_change(%{} = attrs \\ %{}) do
    Registration.create_changeset(attrs)
  end

  def update_change(%Registration{} = registration, %{} = attrs \\ %{}) do
    Registration.update_changeset(registration, attrs)
  end

  def resignation_change(%Registration{} = registration, %{} = attrs \\ %{}) do
    Registration.resignation_changeset(registration, attrs)
  end

  def update(%Registration{} = registration, %{} = attrs) do
    registration
    |> Registration.update_changeset(attrs)
    |> Repo.update()
  end

  def resign(%Registration{resignation_date: nil} = registration, %{} = attrs) do
    case Payslips.get_last_payslip(registration) do
      %{end_date: end_date} ->
        if Date.compare(attrs.resignation_date, end_date) in [:eq, :gt] do
          do_resign(registration, attrs)
        else
          {:error,
           "A data de desligamento deve ser igual ou posterior a data final do último holerite"}
        end

      nil ->
        do_resign(registration, attrs)
    end
  end

  def resign(%Registration{resignation_date: %Date{}}, %{}), do: {:error, "Já foi desligado"}

  defp do_resign(registration, attrs) do
    registration
    |> Registration.resignation_changeset(attrs)
    |> Repo.update()
  end

  def undo_resignation(%Registration{resignation_date: %Date{}} = registration) do
    registration
    |> Registration.undo_resignation_changeset()
    |> Repo.update()
  end

  def undo_resignation(%Registration{resignation_date: nil} = registration) do
    {:ok, registration}
  end

  def list_by(schema, opts \\ [])
  def list_by(%Org{} = schema, opts), do: do_list_by(schema, opts)
  def list_by(%Individual{} = schema, opts), do: do_list_by(schema, opts)

  def get(schema, id, opts \\ [])
  def get(%Org{} = schema, id, opts) when is_binary(id), do: do_get(schema, id, opts)
  def get(%Individual{} = schema, id, opts) when is_binary(id), do: do_get(schema, id, opts)

  def count_by(schema, opts \\ [])
  def count_by(%Position{} = schema, opts), do: do_count_by(schema, opts)
  def count_by(%Sector{} = schema, opts), do: do_count_by(schema, opts)

  def get_by(attrs, opts \\ []) when is_list(attrs) do
    init_query()
    |> where(^attrs)
    |> shallow_preload(opts)
    |> Repo.one()
  end

  defp do_list_by(schema, opts) do
    schema
    |> query_by()
    |> shallow_preload(opts)
    |> filter_by(opts)
    |> handle_order_by(opts, :admission_date)
    |> Repo.all()
    |> handle_salary_amount()
  end

  defp do_get(schema, id, opts) do
    schema
    |> query_by()
    |> where(id: ^id)
    |> shallow_preload(opts)
    |> Repo.one()
  end

  defp do_count_by(schema, opts) do
    schema
    |> query_by()
    |> filter_by(opts)
    |> Repo.aggregate(:count)
  end

  defp query_by(%Org{} = org) do
    init_query()
    |> where(org_id: ^org.id)
  end

  defp query_by(%Individual{} = individual) do
    init_query()
    |> where(org_id: ^individual.org_id)
    |> where(individual_id: ^individual.entity_id)
  end

  defp query_by(%Sector{} = sector) do
    init_query()
    |> where(org_id: ^sector.org_id)
    |> where(sector_id: ^sector.id)
  end

  defp query_by(%Position{} = position) do
    init_query()
    |> where(org_id: ^position.org_id)
    |> join(:left, [registration: r], rp in RegistrationPosition,
      on: rp.registration_id == r.id and rp.org_id == r.org_id,
      as: :registration_position
    )
    |> where([registration_position: rp], rp.position_id == ^position.id)
  end

  defp handle_salary_amount(registrations) when is_list(registrations) do
    Enum.map(registrations, &handle_salary_amount/1)
  end

  defp handle_salary_amount(%Registration{salaries: []} = registration), do: registration

  defp handle_salary_amount(%Registration{salaries: %Ecto.Association.NotLoaded{}} = registration) do
    registration
  end

  defp handle_salary_amount(%Registration{salaries: [salary]} = registration) do
    %{registration | salary_amount: salary.amount}
  end

  defp handle_salary_amount(%Registration{salaries: salaries} = registration) do
    [salary | _] = Enum.sort_by(salaries, & &1.start_date, {:desc, Date})

    %{registration | salary_amount: salary.amount}
  end

  @impl Sig.Query
  def filter_by(queryable, :active_in_period, dates) do
    case dates do
      [start_date: start_date, end_date: end_date] ->
        queryable
        |> where([registration: r], r.admission_date < ^end_date)
        |> where(
          [registration: r],
          is_nil(r.resignation_date) or r.resignation_date > ^start_date
        )

      _ ->
        queryable
    end
  end

  def subscribe_to_individual_registrations(%Individual{} = individual) do
    subscribe(topic(individual))
  end

  def broadcast_individual_registrations(%Individual{} = individual) do
    registrations = list_by(individual, preload: :registered_at)

    broadcast(topic(individual), {:updated_individual_registrations, registrations})
  end

  def broadcast_new_individual_registration(%Individual{} = individual, registration, opts \\ []) do
    registration = get(individual, registration.id, opts)

    broadcast(topic(individual), {:new_individual_registration, registration})
  end

  def broadcast_updated_individual_registration(
        %Individual{} = individual,
        registration,
        opts \\ []
      ) do
    registration = get(individual, registration.id, opts)

    broadcast(topic(individual), {:updated_individual_registration, registration})
  end

  defp topic(%Individual{} = individual) do
    "individual_id:" <> individual.entity_id <> ":registrations"
  end
end

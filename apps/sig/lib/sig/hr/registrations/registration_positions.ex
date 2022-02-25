defmodule Sig.HR.Registrations.RegistrationPositions do
  use Sig.Query, schema: __MODULE__.RegistrationPosition, as: :registration_position

  import Sig.Broadcaster

  alias Sig.HR.Registrations
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.RegistrationPositions.RegistrationPosition
  alias Sig.HR.Registrations.RegistrationPositions.Create
  alias Sig.Repo

  @default_preloads [:position]

  defdelegate create(registration, attrs), to: Create, as: :call

  def create_change(%{} = attrs \\ %{}) do
    RegistrationPosition.create_changeset(attrs)
  end

  def update_change(%RegistrationPosition{} = employee_position, %{} = attrs \\ %{}) do
    RegistrationPosition.update_changeset(employee_position, attrs)
  end

  def update(%RegistrationPosition{} = registration_position, %{start_date: start_date} = attrs) do
    with %{admission_date: admission_date} <-
           Registrations.get_by(
             org_id: registration_position.org_id,
             id: registration_position.registration_id
           ),
         comparison when comparison in [:gt, :eq] <- Date.compare(start_date, admission_date) do
      do_update(registration_position, attrs)
    else
      :lt -> {:error, "A data inicial deve ser igual ou posterir a data de registro"}
    end
  end

  def update(%RegistrationPosition{} = registration_position, %{} = attrs) do
    do_update(registration_position, attrs)
  end

  defp do_update(registration_position, attrs) do
    registration_position
    |> RegistrationPosition.update_changeset(attrs)
    |> Repo.update()
  end

  def delete(%RegistrationPosition{} = registration_position) do
    registration_position
    |> query_by()
    |> Repo.aggregate(:count)
    |> case do
      1 -> {:error, "Deve existir pelo menos uma posição"}
      _ -> Repo.delete(registration_position)
    end
  end

  def list_by(schema, opts \\ [])
  def list_by(%Registration{} = schema, opts), do: do_list_by(schema, opts)

  def get(schema, id, opts \\ [])
  def get(%Registration{} = schema, id, opts) when is_binary(id), do: do_get(schema, id, opts)

  def fetch(schema, id, opts \\ []) do
    case get(schema, id, opts) do
      nil -> {:error, :not_found}
      %RegistrationPosition{} = registration_position -> {:ok, registration_position}
    end
  end

  defp do_get(schema, id, opts) do
    schema
    |> query_by()
    |> where(id: ^id)
    |> shallow_preload(@default_preloads)
    |> shallow_preload(opts)
    |> Repo.one()
  end

  defp do_list_by(schema, opts) do
    schema
    |> query_by()
    |> shallow_preload(@default_preloads)
    |> shallow_preload(opts)
    |> filter_by(opts)
    |> handle_order_by(opts, :start_date)
    |> Repo.all()
  end

  def subscribe_to_registration_positions(%Registration{} = registration) do
    subscribe(topic(registration))
  end

  def broadcast_updated_registration_positions(%Registration{} = registration, opts \\ []) do
    broadcast(
      topic(registration),
      {:updated_registration_positions, list_by(registration, opts)}
    )
  end

  defp topic(%Registration{} = registration) do
    "registration_id:" <> registration.id <> ":registration_positions"
  end

  defp query_by(%Registration{} = registration) do
    init_query()
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
  end

  defp query_by(%RegistrationPosition{} = registration_position) do
    init_query()
    |> where(org_id: ^registration_position.org_id)
    |> where(registration_id: ^registration_position.registration_id)
  end
end

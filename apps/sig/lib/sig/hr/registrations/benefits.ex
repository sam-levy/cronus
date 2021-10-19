defmodule Sig.HR.Registrations.Benefits do
  import Ecto.Query

  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.Benefits.Creator
  alias Sig.HR.Registrations.Benefits.Benefit
  alias Sig.Repo

  defdelegate create(registration, attrs), to: Creator
  defdelegate create_from_model(registration, attrs), to: Creator

  def create_change(%{} = attrs \\ %{}), do: Benefit.create_changeset(attrs)

  def create_from_model_change(%{} = attrs \\ %{}) do
    Benefit.create_from_model_changeset(attrs)
  end

  def update_benefit_amount_change(%Benefit{} = benefit, %{} = attrs \\ %{}) do
    Benefit.update_benefit_amount_changeset(benefit, attrs)
  end

  def finalize_change(%Benefit{} = benefit, %{} = attrs \\ %{}) do
    Benefit.finalize_changeset(benefit, attrs)
  end

  def get(%Registration{} = registration, id) when is_binary(id) do
    registration
    |> query_by_registration()
    |> preload_benefit_model()
    |> where(id: ^id)
    |> Repo.one()
    |> fill_virtual_fields()
  end

  def list_by_registration(%Registration{} = registration, opts \\ []) do
    registration
    |> query_by_registration()
    |> preload_benefit_model()
    |> filter_by_types(opts)
    |> filter_by_in_effect_on_date(opts)
    |> last_by(opts)
    |> order_by(:start_date)
    |> Repo.all()
    |> fill_virtual_fields(opts)
  end

  def update_benefit_amount(%Benefit{} = benefit, %{} = attrs) do
    benefit
    |> Benefit.update_benefit_amount_changeset(attrs)
    |> Repo.update()
  end

  def finalize(%Benefit{} = benefit, %{} = attrs) do
    benefit
    |> Benefit.finalize_changeset(attrs)
    |> Repo.update()
  end

  def subscribe_to_registration_benefits(%Registration{} = registration) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(registration))
  end

  def broadcast_registration_benefits(%Registration{} = registration) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      topic(registration),
      {:updated_registration_benefits, list_by_registration(registration)}
    )
  end

  defp topic(%Registration{} = registration) do
    "registration_id:" <> registration.id <> ":benefits"
  end

  defp query_by_registration(registration) do
    Benefit
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
  end

  defp preload_benefit_model(query) do
    query
    |> join(:left, [benefit], model in assoc(benefit, :benefit_model), as: :benefit_model)
    |> preload([_, benefit_model: model], benefit_model: model)
  end

  defp filter_by_types(query, opts) do
    case Keyword.get(opts, :types, :noop) do
      :noop ->
        query

      types ->
        where(
          query,
          [benefit, benefit_model: model],
          benefit.benefit_type in ^types or model.type in ^types
        )
    end
  end

  defp filter_by_in_effect_on_date(query, opts) do
    case Keyword.get(opts, :in_effect_on_date, nil) do
      nil ->
        query

      date ->
        query
        |> where([benefit], benefit.start_date <= ^date)
        |> where([benefit], is_nil(benefit.end_date) or benefit.end_date > ^date)
    end
  end

  defp last_by(query, opts) do
    case Keyword.get(opts, :last_by, nil) do
      nil -> query
      field -> last(query, field)
    end
  end

  defp fill_virtual_fields(target, opts \\ [])

  defp fill_virtual_fields(nil, _opts), do: nil

  defp fill_virtual_fields([], _opts), do: []

  defp fill_virtual_fields([%Benefit{} | _] = benefits, opts) do
    Enum.map(benefits, &fill_virtual_fields(&1, opts))
  end

  defp fill_virtual_fields(%Benefit{is_from_model: false} = benefit, _opts) do
    %{benefit | amount: benefit.benefit_amount, type: benefit.benefit_type}
  end

  defp fill_virtual_fields(
         %Benefit{
           is_from_model: true,
           benefit_model: %{historical_amounts: []} = benefit_model
         } = benefit,
         _opts
       ) do
    %{benefit | amount: benefit_model.amount, type: benefit_model.type}
  end

  defp fill_virtual_fields(
         %Benefit{
           is_from_model: true,
           benefit_model: %{historical_amounts: historical_amounts} = benefit_model
         } = benefit,
         opts
       ) do
    case Keyword.get(opts, :in_effect_on_date) do
      nil ->
        %{benefit | amount: benefit_model.amount, type: benefit_model.type}

      date ->
        %{amount: amount} =
          Enum.find(historical_amounts, &(Date.compare(date, &1.date) in [:gt, :eq]))

        %{benefit | amount: amount, type: benefit_model.type}
    end
  end
end
